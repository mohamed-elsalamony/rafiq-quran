import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:quran/quran.dart' as quran;
import '../../../core/services/app_state.dart';
import '../../../core/services/recitation_service.dart';

class QuranProvider extends ChangeNotifier {
  final AppState appState;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _currentPage = 1;
  int? _activePlayingSurah;
  int? _activePlayingAyah;
  int? _selectedAyahSurah;
  int? _selectedAyahNumber;

  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  bool _isPlaying = false;
  String _currentReciterId = 'Abdul_Basit_Murattal_64kbps';
  double _playbackSpeed = 1.0;
  int _repeatTimes = 1;
  int _currentRepeatCount = 0;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _isKhatmCompleted = false;

  int _currentAudioPositionMs = 0;
  int _lastSavedTimeMs = 0;

  final Map<int, List<Map<String, dynamic>>> _pageVersesCache = {};

  // StreamSubscription references for proper cleanup
  StreamSubscription? _completeSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _logSub;

  // Getters
  int get currentPage => _currentPage;
  int? get activePlayingSurah => _activePlayingSurah;
  int? get activePlayingAyah => _activePlayingAyah;
  int? get selectedAyahSurah => _selectedAyahSurah;
  int? get selectedAyahNumber => _selectedAyahNumber;
  bool get isSearching => _isSearching;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isPlaying => _isPlaying;
  String get currentReciterId => _currentReciterId;
  double get playbackSpeed => _playbackSpeed;
  int get repeatTimes => _repeatTimes;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  int get currentAudioPositionMs => _currentAudioPositionMs;
  bool get isKhatmCompleted => _isKhatmCompleted;

  void clearKhatmCompleted() {
    _isKhatmCompleted = false;
    notifyListeners();
  }

  final List<Map<String, String>> reciters = [
    {'name': 'عبد الباسط عبد الصمد', 'id': 'Abdul_Basit_Murattal_64kbps'},
    {'name': 'محمد صديق المنشاوي', 'id': 'Minshawy_Murattal_128kbps'},
    {'name': 'محمود خليل الحصري', 'id': 'Husary_64kbps'},
    {'name': 'مشاري راشد العفاسي', 'id': 'Alafasy_128kbps'},
    {'name': 'سعد الغامدي', 'id': 'Ghamadi_40kbps'},
    {'name': 'ياسر الدوسري', 'id': 'Dussary_128kbps'},
    {'name': 'ماهر المعيقلي', 'id': 'MaherAlMuaiqly128kbps'},
    {'name': 'عبد الرحمن السديس', 'id': 'Abdurrahmaan_As-Sudais_192kbps'},
    {'name': 'سعود الشريم', 'id': 'Shuraym_128kbps'},
  ];

  QuranProvider({required this.appState}) {
    _audioPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.defaultToSpeaker,
        },
      ),
    ));

    _currentPage = appState.lastPageRead;
    // Load the initial page and prefetch neighbors
    _loadPageVerses(_currentPage);
    Future.microtask(() {
      _loadPageVerses(_currentPage + 1);
      _loadPageVerses(_currentPage - 1);
    });

    // Listen to audio player events
    _completeSub = _audioPlayer.onPlayerComplete.listen((event) {
      _playNextAyah();
    });

    _logSub = _audioPlayer.onLog.listen((log) {
      debugPrint("AudioPlayer Log: $log");
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      _currentAudioPositionMs = pos.inMilliseconds;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - _lastSavedTimeMs > 5000) {
        _lastSavedTimeMs = nowMs;
        if (_isPlaying &&
            _activePlayingSurah != null &&
            _activePlayingAyah != null) {
          final reciterName =
              reciters.firstWhere((r) => r['id'] == _currentReciterId)['name']!;
          appState.saveAudioState(
            reciter: reciterName,
            positionMs: _currentAudioPositionMs,
            surah: _activePlayingSurah!,
            ayah: _activePlayingAyah!,
          );
        }
      }
    });
  }

  void _loadPageVerses(int pageNum) {
    if (pageNum < 1 || pageNum > 604) return;
    if (_pageVersesCache.containsKey(pageNum)) return;

    try {
      final List<Map<String, dynamic>> pageVerses = [];
      final pageData = quran.getPageData(pageNum);
      for (var data in pageData) {
        final int surah = data['surah'];
        final int start = data['start'];
        final int end = data['end'];
        final String surahName = quran.getSurahNameArabic(surah);
        for (int v = start; v <= end; v++) {
          pageVerses.add({
            'surah': surah,
            'ayah': v,
            'text': quran.getVerse(surah, v),
            'surahName': surahName,
          });
        }
      }
      _pageVersesCache[pageNum] = pageVerses;
    } catch (e) {
      debugPrint("Error loading verses for page $pageNum: $e");
    }
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _positionSub?.cancel();
    _logSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- Page Navigation ---
  void goToPage(int pageNum) {
    if (pageNum < 1 || pageNum > 604) return;
    _currentPage = pageNum;
    _selectedAyahSurah = null;
    _selectedAyahNumber = null;
    notifyListeners();

    // Auto-save read progress
    _saveProgress(pageNum);
  }

  void _saveProgress(int pageNum) {
    final verses = getVersesOnPage(pageNum);
    if (verses.isNotEmpty) {
      final firstVerse = verses.first;
      appState.saveReadingPosition(
        page: pageNum,
        surah: firstVerse['surah'],
        ayah: firstVerse['ayah'],
      );
    }
  }

  List<Map<String, dynamic>> getVersesOnPage(int pageNum) {
    if (pageNum < 1 || pageNum > 604) return [];
    if (!_pageVersesCache.containsKey(pageNum)) {
      _loadPageVerses(pageNum);
    }
    Future.microtask(() {
      _loadPageVerses(pageNum + 1);
      _loadPageVerses(pageNum - 1);
    });
    return _pageVersesCache[pageNum] ?? [];
  }

  // --- Recitation controls ---
  Future<void> startRecitation(int surah, int ayah,
      {int? startPositionMs}) async {
    _errorMessage = null;
    _activePlayingSurah = surah;
    _activePlayingAyah = ayah;
    _isPlaying = true;
    _currentRepeatCount = 0;
    _currentAudioPositionMs = startPositionMs ?? 0;
    notifyListeners();

    try {
      final localFile =
          await RecitationService.getLocalFile(surah, ayah, _currentReciterId);
      await _audioPlayer.setPlaybackRate(_playbackSpeed);

      if (await localFile.exists()) {
        await _audioPlayer.play(DeviceFileSource(localFile.path));
      } else {
        final url =
            RecitationService.getAudioUrl(surah, ayah, _currentReciterId);
        await _audioPlayer.play(UrlSource(url)).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception(
                  'انتهت مهلة تشغيل الصوت. يرجى التحقق من اتصالك بالإنترنت.'),
            );
      }

      if (startPositionMs != null && startPositionMs > 0) {
        await _audioPlayer.seek(Duration(milliseconds: startPositionMs));
      }

      // Save audio state
      final reciterName =
          reciters.firstWhere((r) => r['id'] == _currentReciterId)['name']!;
      appState.saveAudioState(
        reciter: reciterName,
        positionMs: startPositionMs ?? 0,
        surah: surah,
        ayah: ayah,
      );

      // Prefetch the next verse silently in the background
      _prefetchNextVerse(surah, ayah);
    } catch (e) {
      debugPrint("Error starting recitation: $e");
      _isPlaying = false;
      _errorMessage =
          "عذراً، فشل تشغيل الصوت: ${e.toString().replaceAll('Exception:', '').trim()}";
      notifyListeners();
    }
  }

  Future<void> _playNextAyah() async {
    if (_activePlayingSurah == null || _activePlayingAyah == null) return;

    if (_currentRepeatCount < _repeatTimes - 1) {
      _currentRepeatCount++;
      startRecitation(_activePlayingSurah!, _activePlayingAyah!);
      return;
    }

    int currentAyah = _activePlayingAyah!;
    int currentSurah = _activePlayingSurah!;
    int totalAyahsInSurah = quran.getVerseCount(currentSurah);

    if (currentAyah < totalAyahsInSurah) {
      currentAyah++;
    } else {
      if (currentSurah < 114) {
        currentSurah++;
        currentAyah = 1;
      } else {
        // Entire Quran finished
        _isKhatmCompleted = true;
        _isPlaying = false;
        _activePlayingSurah = null;
        _activePlayingAyah = null;
        notifyListeners();
        return;
      }
    }

    // Auto-scroll to page if voice transitions to a new page
    int nextPage = quran.getPageNumber(currentSurah, currentAyah);
    if (nextPage != _currentPage) {
      _currentPage = nextPage;
      _saveProgress(nextPage);
    }

    startRecitation(currentSurah, currentAyah);
  }

  void _prefetchNextVerse(int surah, int ayah) {
    int nextAyah = ayah;
    int nextSurah = surah;
    int total = quran.getVerseCount(nextSurah);

    if (nextAyah < total) {
      nextAyah++;
    } else if (nextSurah < 114) {
      nextSurah++;
      nextAyah = 1;
    } else {
      return; // End of Quran
    }

    // Call the recitation service prefetch method asynchronously
    RecitationService.prefetchVerse(nextSurah, nextAyah, _currentReciterId);
  }

  void pauseRecitation() {
    try {
      _audioPlayer.pause();
      _isPlaying = false;
      if (_activePlayingSurah != null && _activePlayingAyah != null) {
        final reciterName =
            reciters.firstWhere((r) => r['id'] == _currentReciterId)['name']!;
        appState.saveAudioState(
          reciter: reciterName,
          positionMs: _currentAudioPositionMs,
          surah: _activePlayingSurah!,
          ayah: _activePlayingAyah!,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error pausing: $e");
    }
  }

  void resumeRecitation() {
    if (_activePlayingSurah != null && _activePlayingAyah != null) {
      try {
        _audioPlayer.resume();
        _isPlaying = true;
        notifyListeners();
      } catch (e) {
        debugPrint("Error resuming: $e");
        startRecitation(_activePlayingSurah!, _activePlayingAyah!);
      }
    } else {
      final pageVerses = getVersesOnPage(_currentPage);
      if (pageVerses.isNotEmpty) {
        startRecitation(pageVerses.first['surah'], pageVerses.first['ayah']);
      }
    }
  }

  void changeReciter(String reciterId) {
    _currentReciterId = reciterId;
    notifyListeners();
    if (_isPlaying &&
        _activePlayingSurah != null &&
        _activePlayingAyah != null) {
      startRecitation(_activePlayingSurah!, _activePlayingAyah!);
    }
  }

  void changePlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
    try {
      _audioPlayer.setPlaybackRate(speed);
    } catch (_) {}
  }

  void changeRepeatTimes(int times) {
    _repeatTimes = times;
    notifyListeners();
  }

  // --- Offline Downloading ---
  Future<void> downloadPageAudio() async {
    if (_isDownloading) return;
    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    final pageVerses = getVersesOnPage(_currentPage);
    final List<Map<String, int>> versesToDownload = pageVerses
        .map((v) => {'surah': v['surah'] as int, 'ayah': v['ayah'] as int})
        .toList();

    await RecitationService.downloadVerses(
      verses: versesToDownload,
      reciterId: _currentReciterId,
      onProgress: (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
      onSuccess: () {
        _isDownloading = false;
        notifyListeners();
      },
      onFailure: (error) {
        _isDownloading = false;
        _errorMessage = "فشل تحميل تلاوة الصفحة: $error";
        notifyListeners();
      },
    );
  }

  // --- Search ---
  void toggleSearch(bool search) {
    _isSearching = search;
    if (!search) {
      _searchResults.clear();
    }
    notifyListeners();
  }

  void performSearch(String query) {
    if (query.trim().isEmpty) return;
    List<Map<String, dynamic>> results = [];

    try {
      for (int s = 1; s <= 114; s++) {
        int count = quran.getVerseCount(s);
        for (int v = 1; v <= count; v++) {
          String verseText = quran.getVerse(s, v);
          if (verseText.contains(query) ||
              quran.getSurahNameArabic(s).contains(query)) {
            results.add({
              'surah': s,
              'ayah': v,
              'text': verseText,
              'page': quran.getPageNumber(s, v),
              'surahName': quran.getSurahNameArabic(s),
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error performing search: $e");
    }

    _searchResults = results;
    notifyListeners();
  }

  // --- Ayah Selection ---
  void selectAyah(int surah, int ayah) {
    _selectedAyahSurah = surah;
    _selectedAyahNumber = ayah;
    notifyListeners();
  }

  void deselectAyah() {
    _selectedAyahSurah = null;
    _selectedAyahNumber = null;
    notifyListeners();
  }

  void setCurrentPageFromScroll(int pageNum) {
    if (pageNum < 1 || pageNum > 604) return;
    _currentPage = pageNum;
    _saveProgress(pageNum);
    notifyListeners();
  }
}

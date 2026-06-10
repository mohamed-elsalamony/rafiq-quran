import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import 'audio_player_widget.dart';
import 'tafseer_widget.dart';

class QuranScreen extends StatefulWidget {
  final int initialPage;
  final int initialSurah;
  final bool autoPlay;

  const QuranScreen({
    super.key,
    this.initialPage = 1,
    this.initialSurah = 1,
    this.autoPlay = false,
  });

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  int _selectedSurah = 1;
  int? _activePlayingSurah;
  int? _activePlayingAyah;
  
  // التحكم في تظليل الآية المحددة يدوياً للتفسير أو الحفظ
  int? _selectedAyahSurah;
  int? _selectedAyahNumber;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  // تشغيل الصوت
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _currentReciterId = 'Abdul_Basit_Murattal_64kbps'; // الافتراضي عبد الباسط
  double _playbackSpeed = 1.0;
  int _repeatTimes = 1;
  int _currentRepeatCount = 0;

  // قائمة القراء المعتمدين
  final List<Map<String, String>> _reciters = [
    {'name': 'عبد الباسط عبد الصمد', 'id': 'Abdul_Basit_Murattal_64kbps'},
    {'name': 'محمد صديق المنشاوي', 'id': 'Minshawy_Murattal_128kbps'},
    {'name': 'محمود خليل الحصري', 'id': 'Husary_64kbps'},
    {'name': 'مشاري راشد العفاسي', 'id': 'Alafasy_128kbps'},
    {'name': 'سعد الغامدي', 'id': 'Ghamadi_40kbps'},
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _selectedSurah = widget.initialSurah;
    _pageController = PageController(initialPage: _currentPage - 1);
    
    // مراقبة انتهاء التلاوة لتشغيل الآية التالية تلقائياً
    _audioPlayer.onPlayerComplete.listen((event) {
      _playNextAyah();
    });

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final appState = Provider.of<AppState>(context, listen: false);
        _startRecitation(appState.lastAudioSurah, appState.lastAudioAyah);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // الحصول على الآيات الخاصة بصفحة معينة
  List<Map<String, dynamic>> _getVersesOnPage(int pageNum) {
    List<Map<String, dynamic>> pageVerses = [];
    for (int s = 1; s <= 114; s++) {
      int count = quran.getVerseCount(s);
      for (int v = 1; v <= count; v++) {
        if (quran.getPageNumber(s, v) == pageNum) {
          pageVerses.add({
            'surah': s,
            'ayah': v,
            'text': quran.getVerse(s, v),
            'surahName': quran.getSurahNameArabic(s),
          });
        }
      }
    }
    return pageVerses;
  }

  // الانتقال إلى صفحة معينة مع حفظ الحالة تلقائياً
  void _goToPage(int pageNum) {
    if (pageNum < 1 || pageNum > 604) return;
    _pageController.animateToPage(
      pageNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _saveProgress(pageNum);
  }

  void _saveProgress(int pageNum) {
    final verses = _getVersesOnPage(pageNum);
    if (verses.isNotEmpty) {
      final firstVerse = verses.first;
      final appState = Provider.of<AppState>(context, listen: false);
      appState.saveReadingPosition(
        page: pageNum,
        surah: firstVerse['surah'],
        ayah: firstVerse['ayah'],
      );
    }
  }

  // --- تشغيل التلاوة الصوتية ---
  Future<String> _getAudioUrl(int surah, int ayah, String reciter) async {
    final sStr = surah.toString().padLeft(3, '0');
    final aStr = ayah.toString().padLeft(3, '0');
    return 'https://www.everyayah.com/data/$reciter/$sStr$aStr.mp3';
  }

  Future<void> _startRecitation(int surah, int ayah) async {
    setState(() {
      _activePlayingSurah = surah;
      _activePlayingAyah = ayah;
      _isPlaying = true;
      _currentRepeatCount = 0;
    });

    final url = await _getAudioUrl(surah, ayah, _currentReciterId);
    
    // التحقق من الملف محلياً لتشغيل بدون إنترنت
    final directory = await getApplicationDocumentsDirectory();
    final sStr = surah.toString().padLeft(3, '0');
    final aStr = ayah.toString().padLeft(3, '0');
    final filePath = '${directory.path}/recitations/$_currentReciterId/${sStr}_$aStr.mp3';
    final file = File(filePath);

    try {
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      if (await file.exists()) {
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        await _audioPlayer.play(UrlSource(url));
      }

      // حفظ موضع الاستماع الأخير
      final appState = Provider.of<AppState>(context, listen: false);
      appState.saveAudioState(
        reciter: _reciters.firstWhere((r) => r['id'] == _currentReciterId)['name']!,
        positionMs: 0,
        surah: surah,
        ayah: ayah,
      );
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> _playNextAyah() async {
    if (_activePlayingSurah == null || _activePlayingAyah == null) return;

    // تكرار الآية الحالية للمساعدة في الحفظ
    if (_currentRepeatCount < _repeatTimes - 1) {
      _currentRepeatCount++;
      _startRecitation(_activePlayingSurah!, _activePlayingAyah!);
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
        // انتهى القرآن الكريم كاملاً
        setState(() {
          _isPlaying = false;
          _activePlayingSurah = null;
          _activePlayingAyah = null;
        });
        return;
      }
    }

    // الانتقال التلقائي للصفحة التالية إذا انتقل الصوت لصفحة جديدة
    int nextPage = quran.getPageNumber(currentSurah, currentAyah);
    if (nextPage != _currentPage) {
      _goToPage(nextPage);
    }

    _startRecitation(currentSurah, currentAyah);
  }

  void _pauseRecitation() {
    _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resumeRecitation() {
    if (_activePlayingSurah != null && _activePlayingAyah != null) {
      _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    } else {
      // تشغيل أول آية في الصفحة الحالية
      final pageVerses = _getVersesOnPage(_currentPage);
      if (pageVerses.isNotEmpty) {
        _startRecitation(pageVerses.first['surah'], pageVerses.first['ayah']);
      }
    }
  }

  // تحميل تلاوات الصفحة الحالية للاستماع بدون إنترنت
  Future<void> _downloadPageAudio() async {
    final pageVerses = _getVersesOnPage(_currentPage);
    final directory = await getApplicationDocumentsDirectory();
    final dirPath = '${directory.path}/recitations/$_currentReciterId';
    await Directory(dirPath).create(recursive: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تحميل التلاوات', textAlign: TextAlign.right),
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('جاري تحميل تلاوات الصفحة الحالية...'),
            SizedBox(width: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );

    try {
      for (final verse in pageVerses) {
        final surah = verse['surah'] as int;
        final ayah = verse['ayah'] as int;
        final sStr = surah.toString().padLeft(3, '0');
        final aStr = ayah.toString().padLeft(3, '0');
        final file = File('$dirPath/${sStr}_$aStr.mp3');

        if (!await file.exists()) {
          final url = await _getAudioUrl(surah, ayah, _currentReciterId);
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            await file.writeAsBytes(res.bodyBytes);
          }
        }
      }
      if (mounted) Navigator.pop(context); // إغلاق الحوار
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحميل تلاوات الصفحة بنجاح!')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحميل: $e')),
        );
      }
    }
  }

  // --- البحث داخل المصحف الشريف ---
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    List<Map<String, dynamic>> results = [];

    // البحث في جميع السور والآيات
    for (int s = 1; s <= 114; s++) {
      int count = quran.getVerseCount(s);
      for (int v = 1; v <= count; v++) {
        String verseText = quran.getVerse(s, v);
        // فلترة النصوص والبحث البسيط (يمكن إزالة التشكيل للبحث الاحترافي)
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

    setState(() {
      _searchResults = results;
    });
  }

  // --- حوار الانتقال السريع ---
  void _showNavigationDialog() {
    int tempPage = _currentPage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتقال سريع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الانتقال بالصفحة
            const Text('أدخل رقم الصفحة (1 - 604):'),
            TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'مثال: 42'),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null && p >= 1 && p <= 604) {
                  tempPage = p;
                }
              },
            ),
            const SizedBox(height: 16),
            // قائمة السور
            const Text('أو اختر السورة:'),
            SizedBox(
              height: 150,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: 114,
                itemBuilder: (context, index) {
                  final sNum = index + 1;
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${sNum}. سورة ${quran.getSurahNameArabic(sNum)}',
                      textAlign: TextAlign.right,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(quran.getPageNumber(sNum, 1));
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5A47)),
            onPressed: () {
              Navigator.pop(context);
              _goToPage(tempPage);
            },
            child: const Text('انتقال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);
    final isDark = appState.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن آية أو سورة...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: _performSearch,
              )
            : Text(
                'سورة ${quran.getSurahNameArabic(_getVersesOnPage(_currentPage).isNotEmpty ? _getVersesOnPage(_currentPage).first['surah'] : 1)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
        centerTitle: true,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchResults.clear();
                  _searchController.clear();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.import_contacts),
            onPressed: _showNavigationDialog,
            tooltip: 'فهرس القرآن الكريَم',
          )
        ],
      ),
      body: Column(
        children: [
          // عرض نتائج البحث في حال التفعيل
          if (_isSearching && _searchResults.isNotEmpty)
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF121212) : Colors.grey[100],
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final res = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(
                          res['text'],
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: isDark ? Colors.amber[200] : primaryColor,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                        subtitle: Text(
                          'سورة ${res['surahName']} - الآية ${res['ayah']} - صفحة ${res['page']}',
                          textAlign: TextAlign.left,
                        ),
                        onTap: () {
                          setState(() {
                            _isSearching = false;
                          });
                          _goToPage(res['page']);
                        },
                      ),
                    );
                  },
                ),
              ),
            )
          else
            // المعرض الرئيسي لصفحات القرآن
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                onPageChanged: (idx) {
                  setState(() {
                    _currentPage = idx + 1;
                    _selectedAyahSurah = null;
                    _selectedAyahNumber = null;
                  });
                  _saveProgress(_currentPage);
                },
                itemBuilder: (context, pageIdx) {
                  final pageNum = pageIdx + 1;
                  final pageVerses = _getVersesOnPage(pageNum);

                  if (pageVerses.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Container(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFDFBF7),
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // معلومات الجزء والحزب والصفحة في الأعلى
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الجزء ${quran.getJuzNumber(pageVerses.first['surah'], pageVerses.first['ayah'])}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                'صفحة ${pageNum}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'الحزب ${quran.getHizbQuarterNumber(pageVerses.first['surah'], pageVerses.first['ayah'])}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          // عرض البسملة إذا كانت بداية سورة جديدة (وليست الفاتحة أو التوبة)
                          if (pageVerses.first['ayah'] == 1 && 
                              pageVerses.first['surah'] != 1 && 
                              pageVerses.first['surah'] != 9)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                quran.basmala,
                                style: GoogleFonts.amiri(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.amber[100] : primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // النص القرآني المتصل للصفحة
                          RichText(
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                            text: TextSpan(
                              children: pageVerses.map((verse) {
                                final sNum = verse['surah'] as int;
                                final aNum = verse['ayah'] as int;
                                final isAudioPlaying = (_activePlayingSurah == sNum && _activePlayingAyah == aNum);
                                final isTextSelected = (_selectedAyahSurah == sNum && _selectedAyahNumber == aNum);

                                return WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedAyahSurah = sNum;
                                        _selectedAyahNumber = aNum;
                                      });
                                      _showVerseActionsBottomSheet(sNum, aNum, verse['text']);
                                    },
                                    child: Container(
                                      color: isAudioPlaying
                                          ? accentColor.withOpacity(0.3)
                                          : isTextSelected
                                              ? Colors.teal.withOpacity(0.2)
                                              : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                                      child: Text(
                                        '${verse['text']} ﴿${quran.getVerseEndSymbol(aNum)}﴾ ',
                                        style: GoogleFonts.amiri(
                                          fontSize: appState.fontSize,
                                          fontWeight: FontWeight.w500,
                                          height: 2.0,
                                          color: isDark ? Colors.grey[200] : Colors.black87,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // لوحة التحكم بالصوت في الأسفل
          AudioPlayerWidget(
            isPlaying: _isPlaying,
            reciters: _reciters,
            currentReciterId: _currentReciterId,
            playbackSpeed: _playbackSpeed,
            repeatTimes: _repeatTimes,
            onPlayToggle: () {
              if (_isPlaying) {
                _pauseRecitation();
              } else {
                _resumeRecitation();
              }
            },
            onReciterChanged: (val) {
              setState(() {
                _currentReciterId = val;
              });
              if (_isPlaying && _activePlayingSurah != null && _activePlayingAyah != null) {
                _startRecitation(_activePlayingSurah!, _activePlayingAyah!);
              }
            },
            onSpeedChanged: (val) {
              setState(() {
                _playbackSpeed = val;
              });
              _audioPlayer.setPlaybackRate(val);
            },
            onRepeatChanged: (val) {
              setState(() {
                _repeatTimes = val;
              });
            },
            onDownload: _downloadPageAudio,
          ),
        ],
      ),
    );
  }

  // --- عرض خيارات الآية (تفسير، نسخ، تشغيل، علامة مرجعية) ---
  void _showVerseActionsBottomSheet(int surah, int ayah, String text) {
    final appState = Provider.of<AppState>(context, listen: false);
    final Color primaryColor = const Color(0xFF0F5A47);
    final isDark = appState.isDarkMode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الآية $ayah - سورة ${quran.getSurahNameArabic(surah)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.teal),
              title: const Text('تلاوة هذه الآية', textAlign: TextAlign.right),
              onTap: () {
                Navigator.pop(context);
                _startRecitation(surah, ayah);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.blue),
              title: const Text('عرض التفسير والتدبر', textAlign: TextAlign.right),
              onTap: () {
                Navigator.pop(context);
                _showTafseerDialog(surah, ayah, text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add, color: Colors.amber),
              title: const Text('إضافة للعلامات المرجعية', textAlign: TextAlign.right),
              onTap: () async {
                Navigator.pop(context);
                await DbHelper.addBookmark(
                  page: quran.getPageNumber(surah, ayah),
                  surah: surah,
                  ayah: ayah,
                  label: 'سورة ${quran.getSurahNameArabic(surah)} الآية $ayah',
                  surahName: quran.getSurahNameArabic(surah),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت الإضافة للعلامات المرجعية بنجاح!')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('نسخ نص الآية', textAlign: TextAlign.right),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: '$text ﴿${quran.getVerseEndSymbol(ayah)}﴾'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ نص الآية إلى الحافظة!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('مشاركة الآية كنص', textAlign: TextAlign.right),
              onTap: () {
                Navigator.pop(context);
                Share.share('$text ﴿${quran.getVerseEndSymbol(ayah)}﴾ [سورة ${quran.getSurahNameArabic(surah)}: $ayah]');
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- عرض مربع حوار التفسير ---
  void _showTafseerDialog(int surah, int ayah, String verseText) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: TafseerWidget(
          surah: surah,
          ayah: ayah,
          verseText: verseText,
        ),
      ),
    );
  }
}

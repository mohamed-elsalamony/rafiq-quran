import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import 'audio_player_widget.dart';
import 'tafseer_widget.dart';
import 'quran_provider.dart';
import 'widgets/quran_page_widget.dart';
import 'widgets/quran_page_separator.dart';
import 'quran_index_screen.dart';

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
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isInit = false;
  bool _isProgrammaticScroll = false;
  static const double _averagePageHeight = 850.0;

  // Auto-scroll variables
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  bool _showAutoScrollPanel = false;
  bool _showBackToTopBtn = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      quranProvider.addListener(_onProviderChange);

      if (widget.initialPage != 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          quranProvider.goToPage(widget.initialPage);
          _scrollToPage(widget.initialPage);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToPage(quranProvider.currentPage);
        });
      }

      if (widget.autoPlay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final appState = Provider.of<AppState>(context, listen: false);
          quranProvider.startRecitation(
            appState.lastAudioSurah,
            appState.lastAudioAyah,
            startPositionMs: appState.lastAudioPositionMs,
          );
        });
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    try {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      quranProvider.removeListener(_onProviderChange);
    } catch (_) {}
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    
    // Show back-to-top button
    if (_scrollController.offset > 400 && !_showBackToTopBtn) {
      setState(() => _showBackToTopBtn = true);
    } else if (_scrollController.offset <= 400 && _showBackToTopBtn) {
      setState(() => _showBackToTopBtn = false);
    }

    // Scroll progress tracker
    if (!_isProgrammaticScroll && _scrollController.hasClients) {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      final offset = _scrollController.offset;
      final pageIndex = (offset / _averagePageHeight).round().clamp(0, 603);
      final targetPage = pageIndex + 1;
      
      if (quranProvider.currentPage != targetPage) {
        quranProvider.setCurrentPageFromScroll(targetPage);
      }
    }
  }

  void _scrollToPage(int pageNum) {
    if (!_scrollController.hasClients) return;
    final targetOffset = (pageNum - 1) * _averagePageHeight;
    _isProgrammaticScroll = true;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    ).then((_) {
      _isProgrammaticScroll = false;
    });
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = Provider.of<QuranProvider>(context, listen: false);

    // 1. Handle errors
    if (provider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage!, textAlign: TextAlign.right),
              backgroundColor: Colors.red[900],
            ),
          );
          provider.clearError();
        }
      });
    }

    // 2. Handle download dialog loader
    if (provider.isDownloading) {
      _showDownloadProgressDialog(provider);
    }

    // 3. Sync scroll offset when page changes externally
    if (!_isProgrammaticScroll && _scrollController.hasClients) {
      final targetOffset = (provider.currentPage - 1) * _averagePageHeight;
      if ((_scrollController.offset - targetOffset).abs() > 100) {
        _scrollToPage(provider.currentPage);
      }
    }
  }

  // --- Auto-scroll execution logic ---
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final appState = Provider.of<AppState>(context, listen: false);
    
    // speed is in pixels per second. 
    // A timer running every 50ms means we execute 20 updates per second.
    // delta = speed / 20.0
    final double step = appState.autoScrollSpeed / 20.0;
    
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients && _isAutoScrolling) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        if (currentScroll >= maxScroll) {
          _stopAutoScroll();
        } else {
          _scrollController.jumpTo(currentScroll + step);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    setState(() {
      _isAutoScrolling = false;
    });
  }

  void _toggleAutoScrolling() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
      if (_isAutoScrolling) {
        _startAutoScroll();
      } else {
        _stopAutoScroll();
      }
    });
  }

  void _adjustSpeed(double delta) {
    final appState = Provider.of<AppState>(context, listen: false);
    double newSpeed = (appState.autoScrollSpeed + delta).clamp(5.0, 100.0);
    appState.setAutoScrollSpeed(newSpeed);
    if (_isAutoScrolling) {
      _startAutoScroll();
    }
    setState(() {});
  }

  void _showDownloadProgressDialog(QuranProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Selector<QuranProvider, Map<String, dynamic>>(
          selector: (context, p) => {
            'isDownloading': p.isDownloading,
            'progress': p.downloadProgress,
          },
          builder: (context, data, child) {
            final isDownloading = data['isDownloading'] as bool;
            final progress = data['progress'] as double;

            if (!isDownloading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context, rootNavigator: true).pop();
              });
            }

            return AlertDialog(
              title: const Text('تحميل التلاوات', textAlign: TextAlign.right),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('جاري تحميل تلاوات الصفحة الحالية للاستماع بدون اتصال...'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Settings sheet to configure themes, fonts, sizes ---
  void _showReaderSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, appState, child) {
            final primaryColor = const Color(0xFF0F5A47);
            final goldColor = const Color(0xFFD4AF37);
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'تخصيص قارئ المصحف',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 1. Theme choices
                  const Text('سمة الخلفية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeOption(context, appState, 'light', 'فاتح', const Color(0xFFFDFBF7), Colors.black87),
                      _buildThemeOption(context, appState, 'sepia', 'دافئ (Sepia)', const Color(0xFFF4ECD8), const Color(0xFF5B4636)),
                      _buildThemeOption(context, appState, 'dark', 'مظلم', const Color(0xFF1E1E1E), Colors.grey[200]!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Font choices
                  const Text('نوع الخط العربي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => appState.setQuranFontFamily('Amiri'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: appState.quranFontFamily == 'Amiri' ? primaryColor.withOpacity(0.1) : Colors.transparent,
                            side: BorderSide(color: appState.quranFontFamily == 'Amiri' ? primaryColor : Colors.grey[300]!),
                          ),
                          child: Text('خط Amiri', style: GoogleFonts.amiri(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => appState.setQuranFontFamily('Scheherazade'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: appState.quranFontFamily == 'Scheherazade' ? primaryColor.withOpacity(0.1) : Colors.transparent,
                            side: BorderSide(color: appState.quranFontFamily == 'Scheherazade' ? primaryColor : Colors.grey[300]!),
                          ),
                          child: Text('خط Scheherazade', style: GoogleFonts.scheherazadeNew(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Size slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('حجم الخط (${appState.fontSize.toInt()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Icon(Icons.format_size, size: 20),
                    ],
                  ),
                  Slider(
                    value: appState.fontSize,
                    min: 16.0,
                    max: 36.0,
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.2),
                    onChanged: (val) {
                      appState.setFontSize(val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppState appState,
    String mode,
    String label,
    Color bg,
    Color fg,
  ) {
    final isSelected = appState.quranThemeMode == mode;
    return GestureDetector(
      onTap: () => appState.setQuranThemeMode(mode),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.withOpacity(0.3),
                width: isSelected ? 3.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 8)]
                  : null,
            ),
            child: Icon(Icons.check, color: isSelected ? fg : Colors.transparent, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final quranProvider = Provider.of<QuranProvider>(context);
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color goldColor = const Color(0xFFD4AF37);
    final isDark = appState.isDarkMode;

    final themeMode = appState.quranThemeMode;
    final Color layoutBgColor = themeMode == 'dark'
        ? const Color(0xFF1E1E1E)
        : (themeMode == 'sepia' ? const Color(0xFFF4ECD8) : const Color(0xFFFDFBF7));

    final currentVerses = quranProvider.getVersesOnPage(quranProvider.currentPage);
    final String titleText = quranProvider.isSearching
        ? 'البحث في المصحف'
        : (currentVerses.isNotEmpty ? 'سورة ${currentVerses.first['surahName']}' : 'القرآن الكريم');

    return Scaffold(
      backgroundColor: layoutBgColor,
      appBar: AppBar(
        backgroundColor: themeMode == 'dark'
            ? const Color(0xFF1A1A1A)
            : (themeMode == 'sepia' ? const Color(0xFFE8DECA) : primaryColor),
        foregroundColor: themeMode == 'dark' || themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white,
        title: quranProvider.isSearching
            ? TextField(
                controller: _searchController,
                style: TextStyle(color: themeMode == 'dark' || themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن آية أو سورة...',
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                ),
                onSubmitted: quranProvider.performSearch,
              )
            : Text(
                titleText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: themeMode == 'dark' ? Colors.amber[200] : (themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white),
                ),
              ),
        iconTheme: IconThemeData(
          color: themeMode == 'dark' ? Colors.amber[200] : (themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (!quranProvider.isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => quranProvider.toggleSearch(true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                quranProvider.toggleSearch(false);
                _searchController.clear();
              },
            ),
          IconButton(
            icon: const Icon(Icons.format_size),
            onPressed: () => _showReaderSettingsBottomSheet(context),
            tooltip: 'تخصيص قارئ القرآن',
          ),
          IconButton(
            icon: const Icon(Icons.swap_vertical_circle),
            onPressed: () {
              setState(() {
                _showAutoScrollPanel = !_showAutoScrollPanel;
                if (!_showAutoScrollPanel) {
                  _stopAutoScroll();
                }
              });
            },
            color: _showAutoScrollPanel ? goldColor : null,
            tooltip: 'التمرير التلقائي',
          ),
          IconButton(
            icon: const Icon(Icons.import_contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuranIndexScreen()),
              );
            },
            tooltip: 'فهرس القرآن الكريم',
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search results panel
              if (quranProvider.isSearching && quranProvider.searchResults.isNotEmpty)
                Expanded(
                  child: Container(
                    color: layoutBgColor,
                    child: ListView.builder(
                      itemCount: quranProvider.searchResults.length,
                      itemBuilder: (context, index) {
                        final res = quranProvider.searchResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: themeMode == 'dark' ? const Color(0xFF2C2C2C) : Colors.white,
                          child: ListTile(
                            title: Text(
                              res['text'],
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                color: themeMode == 'dark' ? Colors.amber[200] : primaryColor,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Text(
                              'سورة ${res['surahName']} - الآية ${res['ayah']} - صفحة ${res['page']}',
                              textAlign: TextAlign.left,
                              style: TextStyle(color: themeMode == 'dark' ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            onTap: () {
                              quranProvider.toggleSearch(false);
                              _searchController.clear();
                              quranProvider.goToPage(res['page']);
                              _scrollToPage(res['page']);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                )
              else if (quranProvider.isSearching && quranProvider.searchResults.isEmpty)
                const Expanded(
                  child: Center(child: Text('لا توجد نتائج مطابقة لبحثك.')),
                )
              else
                // Continuous Vertical Scroll List
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    itemCount: 604,
                    separatorBuilder: (context, index) {
                      final nextPage = index + 2;
                      final verses = quranProvider.getVersesOnPage(nextPage);
                      final nextSurah = verses.isNotEmpty ? verses.first['surah'] as int : 1;
                      return QuranPageSeparator(
                        pageNumber: nextPage,
                        nextSurahNumber: nextSurah,
                      );
                    },
                    itemBuilder: (context, index) {
                      final pageNum = index + 1;
                      final pageVerses = quranProvider.getVersesOnPage(pageNum);

                      if (pageVerses.isEmpty) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: QuranPageWidget(
                          pageNumber: pageNum,
                          verses: pageVerses,
                          fontSize: appState.fontSize,
                          fontFamily: appState.quranFontFamily,
                          themeMode: themeMode,
                          activePlayingSurah: quranProvider.activePlayingSurah,
                          activePlayingAyah: quranProvider.activePlayingAyah,
                          selectedAyahSurah: quranProvider.selectedAyahSurah,
                          selectedAyahNumber: quranProvider.selectedAyahNumber,
                          onAyahTap: (surah, ayah) {
                            quranProvider.selectAyah(surah, ayah);
                            _showVerseActionsBottomSheet(
                              context, quranProvider, surah, ayah, quran.getVerse(surah, ayah));
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Audio player bottom panel
              AudioPlayerWidget(
                isPlaying: quranProvider.isPlaying,
                reciters: quranProvider.reciters,
                currentReciterId: quranProvider.currentReciterId,
                playbackSpeed: quranProvider.playbackSpeed,
                repeatTimes: quranProvider.repeatTimes,
                onPlayToggle: () {
                  if (quranProvider.isPlaying) {
                    quranProvider.pauseRecitation();
                  } else {
                    quranProvider.resumeRecitation();
                  }
                },
                onReciterChanged: quranProvider.changeReciter,
                onSpeedChanged: quranProvider.changePlaybackSpeed,
                onRepeatChanged: quranProvider.changeRepeatTimes,
                onDownload: quranProvider.downloadPageAudio,
              ),
            ],
          ),

          // Floating Auto Scroll control panel (right above the audio player)
          if (_showAutoScrollPanel)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                color: themeMode == 'dark' ? const Color(0xFF2C2C2C) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.teal),
                            onPressed: () => _adjustSpeed(-5.0),
                          ),
                          Text(
                            'السرعة: ${appState.autoScrollSpeed.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                            onPressed: () => _adjustSpeed(5.0),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isAutoScrolling ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: goldColor,
                          size: 36,
                        ),
                        onPressed: _toggleAutoScrolling,
                      ),
                      const Text(
                        'القراءة التلقائية',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating back-to-top button
          if (_showBackToTopBtn)
            Positioned(
              bottom: _showAutoScrollPanel ? 150 : 90,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                onPressed: () {
                  _isProgrammaticScroll = true;
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                  ).then((_) => _isProgrammaticScroll = false);
                },
                child: const Icon(Icons.arrow_upward),
              ),
            ),
        ],
      ),
    );
  }

  // --- Ayah options dialog sheet ---
  void _showVerseActionsBottomSheet(
      BuildContext context, QuranProvider provider, int surah, int ayah, String text) {
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
                provider.startRecitation(surah, ayah);
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
                try {
                  await DbHelper.addBookmark(
                    page: quran.getPageNumber(surah, ayah),
                    surah: surah,
                    ayah: ayah,
                    label: 'سورة ${quran.getSurahNameArabic(surah)} الآية $ayah',
                    surahName: quran.getSurahNameArabic(surah),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت الإضافة للعلامات المرجعية بنجاح!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل الحفظ: $e')),
                    );
                  }
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
    ).then((_) {
      provider.deselectAyah();
    });
  }

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

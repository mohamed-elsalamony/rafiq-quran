import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import 'audio_player_widget.dart';
import 'tafseer_widget.dart';
import 'quran_provider.dart';

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
  final TextEditingController _searchController = TextEditingController();
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      _pageController = PageController(initialPage: quranProvider.currentPage - 1);
      
      // Listen to provider changes to handle error alerts and controller syncing
      quranProvider.addListener(_onProviderChange);

      if (widget.initialPage != 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          quranProvider.goToPage(widget.initialPage);
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
    // Safely remove listener to prevent memory leak
    try {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      quranProvider.removeListener(_onProviderChange);
    } catch (_) {}
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
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

    // 3. Sync page controller
    if (_pageController.hasClients) {
      final targetPage = provider.currentPage - 1;
      if (_pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
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

  // --- Quick navigation dial ---
  void _showNavigationDialog(QuranProvider provider) {
    int tempPage = provider.currentPage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتقال سريع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      provider.goToPage(quran.getPageNumber(sNum, 1));
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
              provider.goToPage(tempPage);
            },
            child: const Text('انتقال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Hizb number calculator ---
  int _getHizbNumber(int page) {
    if (page <= 1) return 1;
    return (((page - 2) ~/ 10) + 1).clamp(1, 60);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final quranProvider = Provider.of<QuranProvider>(context);
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);
    final isDark = appState.isDarkMode;

    final currentVerses = quranProvider.getVersesOnPage(quranProvider.currentPage);
    final String titleText = quranProvider.isSearching
        ? 'البحث في المصحف'
        : (currentVerses.isNotEmpty ? 'سورة ${currentVerses.first['surahName']}' : 'القرآن الكريم');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: quranProvider.isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن آية أو سورة...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: quranProvider.performSearch,
              )
            : Text(
                titleText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
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
            icon: const Icon(Icons.import_contacts),
            onPressed: () => _showNavigationDialog(quranProvider),
            tooltip: 'فهرس القرآن الكريم',
          )
        ],
      ),
      body: Column(
        children: [
          // Search results
          if (quranProvider.isSearching && quranProvider.searchResults.isNotEmpty)
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF121212) : Colors.grey[100],
                child: ListView.builder(
                  itemCount: quranProvider.searchResults.length,
                  itemBuilder: (context, index) {
                    final res = quranProvider.searchResults[index];
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
                          quranProvider.toggleSearch(false);
                          _searchController.clear();
                          quranProvider.goToPage(res['page']);
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
            // Main mushaf page views
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: 604,
                onPageChanged: (idx) {
                  quranProvider.goToPage(idx + 1);
                },
                itemBuilder: (context, pageIdx) {
                  final pageNum = pageIdx + 1;
                  final pageVerses = quranProvider.getVersesOnPage(pageNum);

                  if (pageVerses.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Container(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFDFBF7),
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Header information (Juz, Page, Hizb)
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
                                'الحزب ${_getHizbNumber(pageNum)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          // Bismillah view
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

                          // Text block for verses
                          RichText(
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                            text: TextSpan(
                              children: pageVerses.map((verse) {
                                final sNum = verse['surah'] as int;
                                final aNum = verse['ayah'] as int;
                                final isAudioPlaying = (quranProvider.activePlayingSurah == sNum &&
                                    quranProvider.activePlayingAyah == aNum);
                                final isTextSelected = (quranProvider.selectedAyahSurah == sNum &&
                                    quranProvider.selectedAyahNumber == aNum);

                                return TextSpan(
                                  text: '${verse['text']} ﴿${quran.getVerseEndSymbol(aNum)}﴾ ',
                                  style: GoogleFonts.amiri(
                                    fontSize: appState.fontSize,
                                    fontWeight: FontWeight.w500,
                                    height: 2.0,
                                    color: isAudioPlaying
                                        ? accentColor
                                        : isTextSelected
                                            ? Colors.teal
                                            : (isDark ? Colors.grey[200] : Colors.black87),
                                    backgroundColor: isAudioPlaying
                                        ? accentColor.withOpacity(0.2)
                                        : isTextSelected
                                            ? Colors.teal.withOpacity(0.15)
                                            : Colors.transparent,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      quranProvider.selectAyah(sNum, aNum);
                                      _showVerseActionsBottomSheet(
                                          context, quranProvider, sNum, aNum, verse['text']);
                                    },
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

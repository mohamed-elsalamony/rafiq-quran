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
  bool _isProgrammaticScroll = false;

  // Auto-scroll variables
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  bool _showAutoScrollPanel = false;
  late ScrollController _activePageScrollController;

  @override
  void initState() {
    super.initState();
    _activePageScrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      quranProvider.addListener(_onProviderChange);

      final int startPage = widget.initialPage != 1 ? widget.initialPage : quranProvider.currentPage;
      _pageController = PageController(initialPage: startPage - 1);

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
    _autoScrollTimer?.cancel();
    _activePageScrollController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    try {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      quranProvider.removeListener(_onProviderChange);
    } catch (_) {}
    super.dispose();
  }

  void _scrollToPage(int pageNum) {
    if (!_pageController.hasClients) return;
    _isProgrammaticScroll = true;
    _pageController.animateToPage(
      pageNum - 1,
      duration: const Duration(milliseconds: 300),
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

    // 3. Sync page change externally
    if (!_isProgrammaticScroll && _pageController.hasClients) {
      final currentPageIndex = _pageController.page?.round() ?? 0;
      if (currentPageIndex + 1 != provider.currentPage) {
        _scrollToPage(provider.currentPage);
      }
    }
  }

  // Auto Scroll logic customized for PageView
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final appState = Provider.of<AppState>(context, listen: false);
    final double step = appState.autoScrollSpeed / 20.0;
    
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_activePageScrollController.hasClients && _isAutoScrolling) {
        final maxScroll = _activePageScrollController.position.maxScrollExtent;
        final currentScroll = _activePageScrollController.offset;
        
        if (currentScroll >= maxScroll) {
          final quranProvider = Provider.of<QuranProvider>(context, listen: false);
          if (quranProvider.currentPage < 604) {
            _stopAutoScroll();
            // Go to next page
            quranProvider.goToPage(quranProvider.currentPage + 1);
            // Wait 2 seconds for new page to load, then resume auto scroll from top of new page
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _showAutoScrollPanel) {
                setState(() {
                  _isAutoScrolling = true;
                });
                _startAutoScroll();
              }
            });
          } else {
            _stopAutoScroll();
          }
        } else {
          _activePageScrollController.jumpTo(currentScroll + step);
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

  void _showSurahIndexBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String modalSearchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final appState = Provider.of<AppState>(context);
            final isDark = appState.isDarkMode;
            final primaryColor = const Color(0xFF0F5A47);
            final Color goldColor = const Color(0xFFD4AF37);

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      'فهرس المصحف الشريف',
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? goldColor : primaryColor,
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: TextField(
                          textAlign: TextAlign.right,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              modalSearchQuery = val.trim();
                            });
                          },
                        ),
                      ),
                    ),
                    
                    TabBar(
                      labelColor: goldColor,
                      unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                      indicatorColor: goldColor,
                      tabs: const [
                        Tab(text: 'السور'),
                        Tab(text: 'الأجزاء والأرباع'),
                      ],
                    ),
                    
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSurahTabList(context, isDark, primaryColor, goldColor, modalSearchQuery),
                          _buildJuzTabList(context, isDark, primaryColor, goldColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSurahTabList(BuildContext context, bool isDark, Color primaryColor, Color goldColor, String query) {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final List<int> filteredSurahs = [];
    for (int i = 1; i <= 114; i++) {
      final name = quran.getSurahNameArabic(i);
      final englishName = quran.getSurahName(i);
      if (name.contains(query) || 
          englishName.toLowerCase().contains(query.toLowerCase()) || 
          i.toString() == query) {
        filteredSurahs.add(i);
      }
    }

    if (filteredSurahs.isEmpty) {
      return const Center(child: Text('لا توجد نتائج مطابقة لبحثك.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredSurahs.length,
      itemBuilder: (context, index) {
        final sNum = filteredSurahs[index];
        final isMeccan = quran.getPlaceOfRevelation(sNum) == 'Makkah';
        final totalAyahs = quran.getVerseCount(sNum);
        final startPage = quran.getPageNumber(sNum, 1);
        final name = quran.getSurahNameArabic(sNum);

        return Card(
          margin: const EdgeInsets.only(bottom: 10.0),
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: goldColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$sNum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? goldColor : primaryColor,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: GoogleFonts.amiri(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'صفحة $startPage',
                  style: TextStyle(color: goldColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(
                  '$totalAyahs آية',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Text(
                  isMeccan ? 'مكية 🕋' : 'مدنية 🕌',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet instantly to avoid any conflict
              if (quranProvider.isPlaying) {
                quranProvider.pauseRecitation();
              }
              quranProvider.goToPage(startPage);
            },
          ),
        );
      },
    );
  }

  Widget _buildJuzTabList(BuildContext context, bool isDark, Color primaryColor, Color goldColor) {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    
    final List<Map<String, dynamic>> juzList = List.generate(30, (index) {
      final juzNum = index + 1;
      final List<int> juzStartPages = [
        1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 
        201, 221, 242, 262, 282, 302, 322, 342, 362, 382, 
        402, 422, 442, 462, 482, 502, 522, 542, 562, 582
      ];
      final page = juzStartPages[index];
      return {
        'number': juzNum,
        'name': 'الجزء $juzNum',
        'page': page,
        'surahName': quran.getSurahNameArabic(quran.getPageData(page).first['surah']),
      };
    });

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: juzList.length,
      itemBuilder: (context, index) {
        final juz = juzList[index];
        return Card(
          margin: EdgeInsets.zero,
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.pop(context); // Close bottom sheet instantly
              if (quranProvider.isPlaying) {
                quranProvider.pauseRecitation();
              }
              quranProvider.goToPage(juz['page']);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    juz['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ص ${juz['page']}',
                        style: TextStyle(color: goldColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'سورة ${juz['surahName']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final quranProvider = Provider.of<QuranProvider>(context);
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color goldColor = const Color(0xFFD4AF37);

    final themeMode = appState.quranThemeMode;
    final Color layoutBgColor = themeMode == 'dark'
        ? const Color(0xFF1E1E1E)
        : (themeMode == 'sepia' ? const Color(0xFFF4ECD8) : const Color(0xFFFDFBF7));

    final currentVerses = quranProvider.getVersesOnPage(quranProvider.currentPage);
    final String titleText = currentVerses.isNotEmpty ? 'سورة ${currentVerses.first['surahName']}' : 'القرآن الكريم';

    // Verify if we can pop back to home
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: layoutBgColor,
      appBar: AppBar(
        backgroundColor: themeMode == 'dark'
            ? const Color(0xFF1A1A1A)
            : (themeMode == 'sepia' ? const Color(0xFFE8DECA) : primaryColor),
        foregroundColor: themeMode == 'dark' || themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white,
        
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            onPressed: () => _showReaderSettingsBottomSheet(context),
            tooltip: 'تخصيص قارئ القرآن',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final int? targetPage = await showSearch<int?>(
                context: context,
                delegate: QuranSearchDelegate(
                  provider: quranProvider,
                  themeMode: themeMode,
                ),
              );
              if (targetPage != null) {
                if (quranProvider.isPlaying) {
                  quranProvider.pauseRecitation();
                }
                quranProvider.goToPage(targetPage);
              }
            },
            tooltip: 'بحث في المصحف',
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: () => _showSurahIndexBottomSheet(context),
            tooltip: 'فهرس القرآن الكريم',
          ),
        ],

        // Center: current Surah name with auto-resize
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            titleText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              fontSize: 20,
              color: themeMode == 'dark' ? Colors.amber[200] : (themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white),
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: themeMode == 'dark' ? Colors.amber[200] : (themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Horizontal Swipe PageView Reader
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  reverse: true, // Swiping RTL
                  physics: const ClampingScrollPhysics(),
                  allowImplicitScrolling: true,
                  itemCount: 604,
                  onPageChanged: (index) {
                    final targetPage = index + 1;
                    if (quranProvider.currentPage != targetPage) {
                      quranProvider.setCurrentPageFromScroll(targetPage);
                    }
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

                    final bool isActive = (quranProvider.currentPage - 1) == index;

                    return SingleChildScrollView(
                      controller: isActive ? _activePageScrollController : null,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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

              // Audio player bottom panel (now with auto scroll toggle)
              AudioPlayerWidget(
                isPlaying: quranProvider.isPlaying,
                reciters: quranProvider.reciters,
                currentReciterId: quranProvider.currentReciterId,
                playbackSpeed: quranProvider.playbackSpeed,
                repeatTimes: quranProvider.repeatTimes,
                isAutoScrollOn: _showAutoScrollPanel,
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
                onAutoScrollToggle: () {
                  setState(() {
                    _showAutoScrollPanel = !_showAutoScrollPanel;
                    if (_showAutoScrollPanel) {
                      _isAutoScrolling = true;
                      _startAutoScroll();
                    } else {
                      _stopAutoScroll();
                    }
                  });
                },
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
                        'التشغيل التلقائي للصفحات',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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

// Custom Search Delegate for Quran Surahs and Verses
class QuranSearchDelegate extends SearchDelegate<int?> {
  final QuranProvider provider;
  final String themeMode;

  QuranSearchDelegate({required this.provider, required this.themeMode});

  @override
  String get searchFieldLabel => 'ابحث عن سورة أو آية...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF0F5A47);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: themeMode == 'dark' ? const Color(0xFF1A1A1A) : (themeMode == 'sepia' ? const Color(0xFFE8DECA) : primaryColor),
        foregroundColor: themeMode == 'dark' || themeMode == 'sepia' ? const Color(0xFF5B4636) : Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestionsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionsList(context);
  }

  Widget _buildSuggestionsList(BuildContext context) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return Container(
        color: themeMode == 'dark' ? const Color(0xFF121212) : const Color(0xFFF9FBF9),
        child: const Center(
          child: Text('اكتب كلمة للبحث عن آية أو سورة...'),
        ),
      );
    }

    final Color primaryColor = const Color(0xFF0F5A47);
    final Color goldColor = const Color(0xFFD4AF37);
    final isDark = themeMode == 'dark';

    // 1. Search Surah Names
    final List<int> matchedSurahs = [];
    for (int i = 1; i <= 114; i++) {
      final name = quran.getSurahNameArabic(i);
      final englishName = quran.getSurahName(i);
      if (name.contains(trimmedQuery) || 
          englishName.toLowerCase().contains(trimmedQuery.toLowerCase())) {
        matchedSurahs.add(i);
      }
    }

    // 2. Search Verses (limit to top 30 for performance)
    final List<Map<String, dynamic>> matchedVerses = [];
    int verseMatchesCount = 0;
    for (int s = 1; s <= 114; s++) {
      if (verseMatchesCount >= 30) break;
      final count = quran.getVerseCount(s);
      final sName = quran.getSurahNameArabic(s);
      for (int v = 1; v <= count; v++) {
        final text = quran.getVerse(s, v);
        if (text.contains(trimmedQuery)) {
          matchedVerses.add({
            'surah': s,
            'ayah': v,
            'text': text,
            'surahName': sName,
            'page': quran.getPageNumber(s, v),
          });
          verseMatchesCount++;
          if (verseMatchesCount >= 30) break;
        }
      }
    }

    return Container(
      color: themeMode == 'dark' ? const Color(0xFF1E1E1E) : (themeMode == 'sepia' ? const Color(0xFFF4ECD8) : const Color(0xFFFDFBF7)),
      child: ListView(
        children: [
          // Surah Results Header
          if (matchedSurahs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'السور المطابقة:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? goldColor : primaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            ...matchedSurahs.map((sNum) {
              final page = quran.getPageNumber(sNum, 1);
              return ListTile(
                leading: Icon(Icons.menu_book, color: goldColor),
                title: Text(
                  'سورة ${quran.getSurahNameArabic(sNum)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                subtitle: Text(
                  'صفحة البداية: $page | آياتها: ${quran.getVerseCount(sNum)}',
                  textAlign: TextAlign.right,
                ),
                onTap: () {
                  close(context, page);
                },
              );
            }),
            const Divider(),
          ],

          // Verse Results Header
          if (matchedVerses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'الآيات المطابقة:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? goldColor : primaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            ...matchedVerses.map((verse) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                child: ListTile(
                  title: Text(
                    verse['text'],
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      color: isDark ? Colors.amber[100] : primaryColor,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(
                    'سورة ${verse['surahName']} - الآية ${verse['ayah']} - صفحة ${verse['page']}',
                    textAlign: TextAlign.left,
                  ),
                  onTap: () {
                    close(context, verse['page'] as int);
                  },
                ),
              );
            }),
          ],

          if (matchedSurahs.isEmpty && matchedVerses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('لا توجد نتائج مطابقة لمصطلح البحث.'),
              ),
            ),
        ],
      ),
    );
  }
}

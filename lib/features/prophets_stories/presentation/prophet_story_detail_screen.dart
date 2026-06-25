import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/prophets_stories_service.dart';

class ProphetStoryDetailScreen extends StatefulWidget {
  final ProphetStory story;
  final int? initialChapterId;
  const ProphetStoryDetailScreen(
      {super.key, required this.story, this.initialChapterId});

  @override
  State<ProphetStoryDetailScreen> createState() =>
      _ProphetStoryDetailScreenState();
}

class _ProphetStoryDetailScreenState extends State<ProphetStoryDetailScreen> {
  late ProphetChapter _chapter;
  bool _isFav = false;
  final ProphetsStoriesService _service = ProphetsStoriesService();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    int chapId = widget.initialChapterId ?? 0;
    _chapter = widget.story.chapters.firstWhere(
      (c) => c.id == chapId,
      orElse: () => widget.story.chapters.first,
    );
    _loadFavoriteState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteState() async {
    final fav = await _service.isFavorite(_chapter.id);
    if (mounted) {
      setState(() {
        _isFav = fav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _service.toggleFavorite(_chapter.id);
    await _loadFavoriteState();
  }

  void _saveProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveProphetReadingPosition(
      storyId: widget.story.id,
      chapterId: _chapter.id,
    );
  }

  void _shareContent() {
    final shareText =
        '${_chapter.title}\n\n${_chapter.content}\n\nالمصدر: ${_chapter.source}';
    Share.share(shareText);
  }

  void _copyToClipboard() {
    final copyText =
        '${_chapter.title}\n\n${_chapter.content}\n\nالمصدر: ${_chapter.source}';
    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ نص الفصل بنجاح!', textAlign: TextAlign.right),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeMode = appState.quranThemeMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    // Dynamic style based on reader theme mode
    Color backgroundColor;
    Color textColor;
    Color cardColor;
    if (themeMode == 'dark') {
      backgroundColor = const Color(0xFF121212);
      textColor = Colors.grey[200]!;
      cardColor = const Color(0xFF1E1E1E);
    } else if (themeMode == 'sepia') {
      backgroundColor = const Color(0xFFF4ECD8);
      textColor = const Color(0xFF5B4636);
      cardColor = const Color(0xFFEFE6D0);
    } else {
      backgroundColor = const Color(0xFFF4F6F4);
      textColor = Colors.black87;
      cardColor = Colors.white;
    }

    // Dynamic font family selection
    TextStyle contentTextStyle;
    if (appState.quranFontFamily == 'Scheherazade') {
      contentTextStyle = GoogleFonts.scheherazadeNew(
        fontSize: appState.fontSize + 4,
        height: 1.8,
        color: textColor,
      );
    } else {
      contentTextStyle = GoogleFonts.amiri(
        fontSize: appState.fontSize,
        height: 1.8,
        color: textColor,
      );
    }

    int currentIndex = widget.story.chapters.indexWhere((c) => c.id == _chapter.id);
    bool hasPrevious = currentIndex > 0;
    bool hasNext = currentIndex < widget.story.chapters.length - 1;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor:
            themeMode == 'dark' ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.story.name} - ${_chapter.title}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: _isFav ? Colors.red : Colors.white,
            ),
            tooltip: 'حفظ في المفضلة',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'نسخ الفصل',
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة الفصل',
            onPressed: _shareContent,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Settings and Chapter Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: themeMode == 'dark'
                    ? const Color(0xFF252525)
                    : Colors.grey.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: themeMode == 'dark'
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Font Resize Buttons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_circle_outline,
                            color: themeMode == 'dark'
                                ? Colors.white70
                                : primaryColor,
                            size: 20),
                        onPressed: () {
                          if (appState.fontSize < 36.0) {
                            appState.setFontSize(appState.fontSize + 2);
                          }
                        },
                      ),
                      Text(
                        'حجم الخط',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeMode == 'dark'
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: themeMode == 'dark'
                                ? Colors.white70
                                : primaryColor,
                            size: 20),
                        onPressed: () {
                          if (appState.fontSize > 16.0) {
                            appState.setFontSize(appState.fontSize - 2);
                          }
                        },
                      ),
                    ],
                  ),

                  // Chapter badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_added_rounded,
                            size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'الفصل ${currentIndex + 1} من ${widget.story.chapters.length}',
                          style: const TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Scroll Area
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Chapter Title displayed at the top of content
                    Text(
                      _chapter.title,
                      style: TextStyle(
                        fontSize: appState.fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: themeMode == 'dark' ? accentColor : primaryColor,
                        fontFamily: 'Amiri',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 80,
                        height: 2,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Narrative Content Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SelectableText(
                          _chapter.content,
                          style: contentTextStyle,
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Linked Quranic Verses Header
                    if (_chapter.verses.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'الآيات القرآنية ذات الصلة',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: themeMode == 'dark'
                                    ? Colors.teal[100]
                                    : Colors.teal.shade800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 16, color: accentColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Linked Verses list
                      ..._chapter.verses.map((verse) {
                        Color verseCardColor;
                        if (themeMode == 'dark') {
                          verseCardColor = const Color(0xFF162320);
                        } else if (themeMode == 'sepia') {
                          verseCardColor = const Color(0xFFEBE0C9);
                        } else {
                          verseCardColor = const Color(0xFFEDF6F3);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: accentColor.withOpacity(0.3), width: 1),
                          ),
                          color: verseCardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '﴿ ${verse.text} ﴾',
                                  style: GoogleFonts.amiri(
                                    fontSize: appState.fontSize + 2,
                                    fontWeight: FontWeight.bold,
                                    color: themeMode == 'dark' ? accentColor : primaryColor,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'سورة ${verse.surah} - الآية ${verse.number}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: themeMode == 'dark'
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                    ],

                    // Citation Footer Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeMode == 'dark'
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeMode == 'dark'
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: accentColor),
                              const SizedBox(width: 8),
                              Text(
                                'المصدر والمراجع',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: themeMode == 'dark'
                                      ? Colors.white70
                                      : primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _chapter.source,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.6,
                              color: themeMode == 'dark'
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: themeMode == 'dark'
              ? const Color(0xFF1E1E1E)
              : (themeMode == 'sepia' ? const Color(0xFFEFE6D0) : Colors.white),
          border: Border(
            top: BorderSide(
              color: themeMode == 'dark'
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.15),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Chapter Button (on the right for RTL)
            if (hasPrevious)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final prevChapter = widget.story.chapters[currentIndex - 1];
                    setState(() {
                      _chapter = prevChapter;
                    });
                    _loadFavoriteState();
                    _saveProgress();
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_ios, size: 16), // Right pointing in RTL (Previous)
                  label: const Text(
                    'الفصل السابق',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeMode == 'dark' ? accentColor : primaryColor,
                    side: BorderSide(
                      color: themeMode == 'dark' ? accentColor : primaryColor,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),

            const SizedBox(width: 16),

            // Next Chapter Button (on the left for RTL)
            if (hasNext)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final nextChapter = widget.story.chapters[currentIndex + 1];
                    setState(() {
                      _chapter = nextChapter;
                    });
                    _loadFavoriteState();
                    _saveProgress();
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white), // Left pointing in RTL (Next)
                  label: const Text(
                    'الفصل التالي',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}

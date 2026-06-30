import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/aldaa_wadawaa_service.dart';

class AldaaWadawaaDetailScreen extends StatefulWidget {
  final AldaaWadawaaChapter chapter;

  const AldaaWadawaaDetailScreen({
    super.key,
    required this.chapter,
  });

  @override
  State<AldaaWadawaaDetailScreen> createState() =>
      _AldaaWadawaaDetailScreenState();
}

class _AldaaWadawaaDetailScreenState extends State<AldaaWadawaaDetailScreen> {
  final AldaaWadawaaService _bookService = AldaaWadawaaService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    // Save reading position when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.saveAldaaWadawaaReadingPosition(chapterId: widget.chapter.id);
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _bookService.isFavorite(widget.chapter.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _bookService.toggleFavorite(widget.chapter.id);
    await _checkFavoriteStatus();
  }

  void _shareContent(BuildContext context) {
    final textToShare =
        "${widget.chapter.title}\n\n${widget.chapter.content}\n\nالمصدر: كتاب الداء والدواء (الجواب الكافي لمن سأل عن الدواء الشافي) - طبعة مجمع الفقه الإسلامي (صفحة ${widget.chapter.page})";
    Share.share(textToShare);
  }

  void _copyToClipboard(BuildContext context) {
    final textToCopy =
        "${widget.chapter.title}\n\n${widget.chapter.content}\n\nالمصدر: كتاب الداء والدواء (الجواب الكافي لمن سأل عن الدواء الشافي) - طبعة مجمع الفقه الإسلامي (صفحة ${widget.chapter.page})";
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ النص إلى الحافظة', textAlign: TextAlign.right),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeMode = appState.quranThemeMode;
    const accentColor = Color(0xFFD4AF37);
    const primaryColor = Color(0xFF0F5A47);

    // Dynamic style based on reader theme mode
    Color backgroundColor;
    Color textColor;
    if (themeMode == 'dark') {
      backgroundColor = const Color(0xFF1E1E1E);
      textColor = Colors.grey[200]!;
    } else if (themeMode == 'sepia') {
      backgroundColor = const Color(0xFFF4ECD8);
      textColor = const Color(0xFF5B4636);
    } else {
      backgroundColor = const Color(0xFFFDFBF7);
      textColor = Colors.black87;
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor:
            themeMode == 'dark' ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'قارئ الكتاب',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? accentColor : Colors.white,
            ),
            tooltip: 'حفظ في المفضلة',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'نسخ الفصل',
            onPressed: () => _copyToClipboard(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة الفصل',
            onPressed: () => _shareContent(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Page Badge / Settings Bar
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

                  // Page number badge
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
                        const Icon(Icons.menu_book,
                            size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'صفحة ${widget.chapter.page}',
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

            // Book Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Chapter Title displayed at the top of content
                    Text(
                      widget.chapter.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: appState.fontSize + 2,
                        color: accentColor,
                        height: 1.5,
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

                    // Main Text
                    SelectableText(
                      widget.chapter.content,
                      style: contentTextStyle,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 40),

                    // Previous / Next Chapter Navigation Buttons
                    _buildNavigationButtons(context, primaryColor, accentColor, themeMode),
                    const SizedBox(height: 30),

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
                                'معلومات الكتاب والمصدر',
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
                            'الكتاب: الداء والدواء (الجواب الكافي لمن سأل عن الدواء الشافي)\nالمؤلف: الإمام ابن قيم الجوزية رحمه الله\nالطبعة المعتمدة: طبعة مجمع الفقه الإسلامي بجدة (بإشراف الشيخ بكر أبو زيد رحمه الله)\nالصفحة التقريبية في الطبعة المحققة: ${widget.chapter.page}',
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
      BuildContext context, Color primaryColor, Color accentColor, String themeMode) {
    final prevChapter = _bookService.getChapterById(widget.chapter.id - 1);
    final nextChapter = _bookService.getChapterById(widget.chapter.id + 1);

    Color btnBgColor;
    Color btnTextColor;
    if (themeMode == 'dark') {
      btnBgColor = const Color(0xFF2C2C2C);
      btnTextColor = Colors.white;
    } else if (themeMode == 'sepia') {
      btnBgColor = const Color(0xFFEADBBE);
      btnTextColor = const Color(0xFF5B4636);
    } else {
      btnBgColor = const Color(0xFFE8F3EF);
      btnTextColor = primaryColor;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Button
        Expanded(
          child: prevChapter != null
              ? Card(
                  elevation: 1,
                  color: btnBgColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AldaaWadawaaDetailScreen(chapter: prevChapter),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.arrow_back,
                                  size: 14, color: btnTextColor),
                              const SizedBox(width: 4),
                              Text(
                                'الفصل السابق',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: btnTextColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prevChapter.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: btnTextColor,
                              fontFamily: 'Amiri',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        // Next Button
        Expanded(
          child: nextChapter != null
              ? Card(
                  elevation: 1,
                  color: btnBgColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AldaaWadawaaDetailScreen(chapter: nextChapter),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'الفصل التالي',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: btnTextColor.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward,
                                  size: 14, color: btnTextColor),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextChapter.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: btnTextColor,
                              fontFamily: 'Amiri',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

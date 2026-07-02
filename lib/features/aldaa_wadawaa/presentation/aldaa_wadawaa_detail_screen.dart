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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.saveAldaaWadawaaReadingPosition(chapterId: widget.chapter.id);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _bookService.isFavorite(widget.chapter.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    await _bookService.toggleFavorite(widget.chapter.id);
    await _checkFavoriteStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة',
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Amiri'),
          ),
          backgroundColor: _isFavorite
              ? const Color(0xFF0F5A47)
              : Colors.grey[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  void _shareContent(BuildContext context) {
    final textToShare =
        '${widget.chapter.title}\n\n${widget.chapter.content}\n\nالمصدر: كتاب الداء والدواء (الجواب الكافي) للإمام ابن القيم رحمه الله';
    Share.share(textToShare);
  }

  void _copyToClipboard(BuildContext context) {
    final textToCopy =
        '${widget.chapter.title}\n\n${widget.chapter.content}\n\nالمصدر: كتاب الداء والدواء للإمام ابن القيم رحمه الله (ص ${widget.chapter.page})';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ النص إلى الحافظة',
            textAlign: TextAlign.right),
        backgroundColor: const Color(0xFF0F5A47),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeMode = appState.quranThemeMode;
    const accentColor = Color(0xFFD4AF37);
    const primaryColor = Color(0xFF0F5A47);

    // ألوان حسب وضع القراءة
    Color backgroundColor;
    Color textColor;
    Color cardColor;
    if (themeMode == 'dark') {
      backgroundColor = const Color(0xFF1A1A1A);
      textColor = const Color(0xFFE8E8E8);
      cardColor = const Color(0xFF252525);
    } else if (themeMode == 'sepia') {
      backgroundColor = const Color(0xFFF5EACF);
      textColor = const Color(0xFF4A3728);
      cardColor = const Color(0xFFEAD9B8);
    } else {
      backgroundColor = const Color(0xFFFDFBF7);
      textColor = const Color(0xFF1A1A1A);
      cardColor = const Color(0xFFF0F0F0);
    }

    // نمط الخط
    TextStyle contentTextStyle;
    if (appState.quranFontFamily == 'Scheherazade') {
      contentTextStyle = GoogleFonts.scheherazadeNew(
        fontSize: appState.fontSize + 4,
        height: 2.0,
        color: textColor,
      );
    } else {
      contentTextStyle = GoogleFonts.amiri(
        fontSize: appState.fontSize + 2,
        height: 1.9,
        color: textColor,
      );
    }

    // معلومات الموضع
    final totalChapters = _bookService.totalChapters;
    final currentIndex = _bookService.getChapterIndex(widget.chapter.id);
    final chapterNum = currentIndex >= 0 ? currentIndex + 1 : widget.chapter.id;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor:
            themeMode == 'dark' ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الداء والدواء',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Amiri',
              ),
            ),
            if (totalChapters > 0)
              Text(
                'الفصل $chapterNum من $totalChapters',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  fontFamily: 'Amiri',
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? accentColor : Colors.white70,
            ),
            tooltip: _isFavorite ? 'إزالة من المفضلة' : 'حفظ في المفضلة',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: 'نسخ الفصل',
            onPressed: () => _copyToClipboard(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'مشاركة الفصل',
            onPressed: () => _shareContent(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // شريط الإعدادات العلوي
            _buildSettingsBar(appState, themeMode, primaryColor, accentColor,
                cardColor, textColor, chapterNum, totalChapters),

            // محتوى الفصل
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 20.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // عنوان الفصل
                    _buildChapterTitle(accentColor, appState.fontSize),
                    const SizedBox(height: 20),

                    // نص الفصل
                    SelectableText(
                      widget.chapter.content,
                      style: contentTextStyle,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 32),

                    // أزرار التنقل
                    _buildNavigationButtons(
                        context, primaryColor, accentColor, themeMode, cardColor),
                    const SizedBox(height: 24),

                    // معلومات الكتاب
                    _buildBookInfo(themeMode, primaryColor, accentColor),
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

  Widget _buildChapterTitle(Color accentColor, double fontSize) {
    return Column(
      children: [
        Text(
          widget.chapter.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize + 4,
            color: accentColor,
            height: 1.5,
            fontFamily: 'Amiri',
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsBar(
    AppState appState,
    String themeMode,
    Color primaryColor,
    Color accentColor,
    Color cardColor,
    Color textColor,
    int chapterNum,
    int totalChapters,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: themeMode == 'dark'
            ? const Color(0xFF252525)
            : Colors.grey.withOpacity(0.06),
        border: Border(
          bottom: BorderSide(
            color: themeMode == 'dark'
                ? Colors.grey.withOpacity(0.1)
                : Colors.grey.withOpacity(0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          // أزرار حجم الخط
          _fontSizeButton(
            icon: Icons.text_increase_rounded,
            onTap: () {
              if (appState.fontSize < 36.0) {
                appState.setFontSize(appState.fontSize + 2);
              }
            },
            color: themeMode == 'dark' ? Colors.white70 : primaryColor,
          ),
          const SizedBox(width: 2),
          Text(
            'أ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: themeMode == 'dark' ? Colors.grey[400] : Colors.grey[700],
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(width: 2),
          _fontSizeButton(
            icon: Icons.text_decrease_rounded,
            onTap: () {
              if (appState.fontSize > 14.0) {
                appState.setFontSize(appState.fontSize - 2);
              }
            },
            color: themeMode == 'dark' ? Colors.white70 : primaryColor,
          ),

          const Spacer(),

          // وضع القراءة
          _themeButton(
            label: '☀',
            active: themeMode == 'light',
            onTap: () => appState.setQuranThemeMode('light'),
            activeColor: Colors.amber[700]!,
          ),
          const SizedBox(width: 4),
          _themeButton(
            label: '🌙',
            active: themeMode == 'dark',
            onTap: () => appState.setQuranThemeMode('dark'),
            activeColor: Colors.blueGrey,
          ),
          const SizedBox(width: 4),
          _themeButton(
            label: 'ب',
            active: themeMode == 'sepia',
            onTap: () => appState.setQuranThemeMode('sepia'),
            activeColor: const Color(0xFF8B6914),
          ),

          const Spacer(),

          // رقم الصفحة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 12, color: Color(0xFFD4AF37)),
                const SizedBox(width: 5),
                Text(
                  'ص ${widget.chapter.page}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fontSizeButton(
      {required IconData icon,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _themeButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 26,
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active
              ? Border.all(color: activeColor, width: 1.2)
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: active ? activeColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    Color primaryColor,
    Color accentColor,
    String themeMode,
    Color cardColor,
  ) {
    // في RTL العربي: "الفصل التالي" هو الفصل الأحدث (id+1) ويكون على اليمين
    // و"الفصل السابق" هو الأقدم (id-1) ويكون على اليسار
    final prevChapter = _bookService.getChapterById(widget.chapter.id - 1);
    final nextChapter = _bookService.getChapterById(widget.chapter.id + 1);

    Color btnBgColor;
    Color btnTextColor;
    if (themeMode == 'dark') {
      btnBgColor = const Color(0xFF2C2C2C);
      btnTextColor = Colors.white;
    } else if (themeMode == 'sepia') {
      btnBgColor = const Color(0xFFE8D5B0);
      btnTextColor = const Color(0xFF5B4636);
    } else {
      btnBgColor = const Color(0xFFE8F3EF);
      btnTextColor = primaryColor;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          // زر "الفصل التالي" على اليمين (في RTL)
          if (nextChapter != null)
            Expanded(
              child: _navButton(
                context: context,
                chapter: nextChapter,
                label: 'الفصل التالي',
                isNext: true,
                btnBgColor: btnBgColor,
                btnTextColor: btnTextColor,
                accentColor: accentColor,
              ),
            )
          else
            const Expanded(child: SizedBox()),

          if (prevChapter != null && nextChapter != null)
            const SizedBox(width: 10),

          // زر "الفصل السابق" على اليسار (في RTL)
          if (prevChapter != null)
            Expanded(
              child: _navButton(
                context: context,
                chapter: prevChapter,
                label: 'الفصل السابق',
                isNext: false,
                btnBgColor: btnBgColor,
                btnTextColor: btnTextColor,
                accentColor: accentColor,
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _navButton({
    required BuildContext context,
    required AldaaWadawaaChapter chapter,
    required String label,
    required bool isNext,
    required Color btnBgColor,
    required Color btnTextColor,
    required Color accentColor,
  }) {
    return Card(
      elevation: 1,
      color: btnBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  AldaaWadawaaDetailScreen(chapter: chapter),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Column(
            crossAxisAlignment:
                isNext ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment:
                    isNext ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: isNext
                    ? [
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: accentColor),
                        const SizedBox(width: 4),
                        Text(label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: btnTextColor.withOpacity(0.7),
                              fontFamily: 'Amiri',
                            )),
                      ]
                    : [
                        Text(label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: btnTextColor.withOpacity(0.7),
                              fontFamily: 'Amiri',
                            )),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_back_ios_rounded,
                            size: 12, color: accentColor),
                      ],
              ),
              const SizedBox(height: 4),
              Text(
                chapter.title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: btnTextColor,
                  fontFamily: 'Amiri',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: isNext ? TextAlign.start : TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookInfo(
      String themeMode, Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeMode == 'dark'
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeMode == 'dark'
              ? Colors.grey.withOpacity(0.15)
              : const Color(0xFF0F5A47).withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'معلومات الكتاب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: themeMode == 'dark' ? Colors.white70 : primaryColor,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'كتاب الداء والدواء (الجواب الكافي لمن سأل عن الدواء الشافي)\nتأليف: الإمام ابن قيم الجوزية رحمه الله\nالصفحة: ${widget.chapter.page}',
            style: TextStyle(
              fontSize: 11,
              height: 1.7,
              color: themeMode == 'dark' ? Colors.grey[400] : Colors.grey[600],
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

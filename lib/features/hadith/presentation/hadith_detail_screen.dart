import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/hadith_service.dart';

class HadithDetailScreen extends StatefulWidget {
  final Hadith hadith;
  const HadithDetailScreen({super.key, required this.hadith});

  @override
  State<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends State<HadithDetailScreen> {
  final HadithService _service = HadithService();
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final fav = await _service.isFavorite(widget.hadith.id);
    if (mounted) {
      setState(() {
        _isFav = fav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _service.toggleFavorite(widget.hadith.id);
    final fav = await _service.isFavorite(widget.hadith.id);
    if (mounted) {
      setState(() {
        _isFav = fav;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFav ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة',
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'الحديث الشريف',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: _isFav ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'حفظ في المفضلة',
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hadith Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hadith Text
                      Text(
                        '« ${widget.hadith.text} »',
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.8,
                          color: isDark ? accentColor : primaryColor,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const Divider(height: 32),

                      // Source / Rawi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.bookmark_outline,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'رواه: ${widget.hadith.source}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Explanation Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'شرح وتفسير الحديث',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.info_outline,
                              color: isDark ? accentColor : primaryColor),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        widget.hadith.explanation,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: isDark ? Colors.grey[300] : Colors.black87,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final shareText =
                          'الحديث الشريف:\n« ${widget.hadith.text} »\n\nرواه: ${widget.hadith.source}\n\nالشرح:\n${widget.hadith.explanation}';
                      Share.share(shareText);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('مشاركة الحديث'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final copyText =
                          '« ${widget.hadith.text} »\n\nرواه: ${widget.hadith.source}\n\nالشرح:\n${widget.hadith.explanation}';
                      Clipboard.setData(ClipboardData(text: copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الحديث بنجاح!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ الحديث'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

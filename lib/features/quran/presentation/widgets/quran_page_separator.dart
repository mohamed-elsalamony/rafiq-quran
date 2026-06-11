import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

class QuranPageSeparator extends StatelessWidget {
  final int pageNumber;
  final int nextSurahNumber;

  const QuranPageSeparator({
    super.key,
    required this.pageNumber,
    required this.nextSurahNumber,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color goldColor = const Color(0xFFD4AF37);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String surahName = quran.getSurahNameArabic(nextSurahNumber);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: goldColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Islamic Background Decorative Lines
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        goldColor.withOpacity(0.0),
                        goldColor.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: goldColor, size: 12),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: goldColor, size: 16),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: goldColor, size: 12),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        goldColor.withOpacity(0.5),
                        goldColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Surah Name Title Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              border: Border.all(
                color: goldColor.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'سورة $surahName',
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? goldColor : primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'الصفحة التالية: $pageNumber',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

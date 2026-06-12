import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

class QuranPageWidget extends StatefulWidget {
  final int pageNumber;
  final List<Map<String, dynamic>> verses;
  final double fontSize;
  final String fontFamily;
  final String themeMode; // 'light', 'dark', 'sepia'
  final int? activePlayingSurah;
  final int? activePlayingAyah;
  final int? selectedAyahSurah;
  final int? selectedAyahNumber;
  final Function(int surah, int ayah) onAyahTap;

  const QuranPageWidget({
    super.key,
    required this.pageNumber,
    required this.verses,
    required this.fontSize,
    required this.fontFamily,
    required this.themeMode,
    this.activePlayingSurah,
    this.activePlayingAyah,
    this.selectedAyahSurah,
    this.selectedAyahNumber,
    required this.onAyahTap,
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _initRecognizers();
  }

  @override
  void didUpdateWidget(covariant QuranPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses.length != widget.verses.length) {
      _disposeRecognizers();
      _initRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _initRecognizers() {
    for (int i = 0; i < widget.verses.length; i++) {
      final verse = widget.verses[i];
      final surah = verse['surah'] as int;
      final ayah = verse['ayah'] as int;
      _recognizers.add(
        TapGestureRecognizer()
          ..onTap = () {
            widget.onAyahTap(surah, ayah);
          },
      );
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Color _getTextColor(bool isAudioPlaying, bool isTextSelected) {
    if (isAudioPlaying) {
      return const Color(0xFFD4AF37); // Golden yellow
    }
    if (isTextSelected) {
      return Colors.teal;
    }
    if (widget.themeMode == 'dark') {
      return Colors.grey[200]!;
    }
    if (widget.themeMode == 'sepia') {
      return const Color(0xFF5B4636); // Sepia dark brown
    }
    return Colors.black87;
  }

  Color _getBgColor(bool isAudioPlaying, bool isTextSelected) {
    if (isAudioPlaying) {
      return const Color(0xFFD4AF37).withOpacity(0.2);
    }
    if (isTextSelected) {
      return Colors.teal.withOpacity(0.15);
    }
    return Colors.transparent;
  }

  TextStyle _getQuranTextStyle(bool isAudioPlaying, bool isTextSelected) {
    final textColor = _getTextColor(isAudioPlaying, isTextSelected);
    final bgColor = _getBgColor(isAudioPlaying, isTextSelected);

    if (widget.fontFamily == 'Scheherazade') {
      return GoogleFonts.scheherazadeNew(
        fontSize: widget.fontSize + 4,
        fontWeight: FontWeight.w500,
        height: 1.8,
        color: textColor,
        backgroundColor: bgColor,
      );
    } else {
      return GoogleFonts.amiri(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w500,
        height: 2.0,
        color: textColor,
        backgroundColor: bgColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0F5A47);
    const Color goldColor = Color(0xFFD4AF37);

    int getHizbNumber(int page) {
      if (page <= 1) return 1;
      return (((page - 2) ~/ 10) + 1).clamp(1, 60);
    }

    // Group verses by surah to display Surah headers and Basmalahs correctly in-line
    final List<List<Map<String, dynamic>>> surahGroups = [];
    if (widget.verses.isNotEmpty) {
      List<Map<String, dynamic>> currentGroup = [widget.verses.first];
      for (int i = 1; i < widget.verses.length; i++) {
        final verse = widget.verses[i];
        final prevVerse = widget.verses[i - 1];
        if (verse['surah'] == prevVerse['surah']) {
          currentGroup.add(verse);
        } else {
          surahGroups.add(currentGroup);
          currentGroup = [verse];
        }
      }
      surahGroups.add(currentGroup);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الجزء ${quran.getJuzNumber(widget.verses.first['surah'], widget.verses.first['ayah'])}',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeMode == 'sepia'
                    ? const Color(0xFF8C7565)
                    : Colors.grey,
                fontFamily: 'Outfit',
              ),
            ),
            Text(
              'صفحة ${widget.pageNumber}',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeMode == 'sepia'
                    ? const Color(0xFF8C7565)
                    : Colors.grey,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            Text(
              'الحزب ${getHizbNumber(widget.pageNumber)}',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeMode == 'sepia'
                    ? const Color(0xFF8C7565)
                    : Colors.grey,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        const Divider(height: 20),
        ...surahGroups.map((group) {
          final firstVerse = group.first;
          final int sNum = firstVerse['surah'] as int;
          final int aNum = firstVerse['ayah'] as int;

          // Show Surah header only when a new Surah starts (ayah == 1)
          final bool showHeader = aNum == 1;
          final bool showBasmalah = showHeader && sNum != 1 && sNum != 9;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeader)
                SurahHeaderBanner(
                  surahNumber: sNum,
                  themeMode: widget.themeMode,
                ),
              if (showBasmalah)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    quran.basmala,
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: widget.themeMode == 'dark'
                          ? Colors.amber[100]
                          : (widget.themeMode == 'sepia'
                              ? const Color(0xFF8C3E15)
                              : primaryColor),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              RichText(
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: List.generate(group.length, (idx) {
                    final verse = group[idx];
                    final sVal = verse['surah'] as int;
                    final aVal = verse['ayah'] as int;
                    final isAudioPlaying = (widget.activePlayingSurah == sVal &&
                        widget.activePlayingAyah == aVal);
                    final isTextSelected = (widget.selectedAyahSurah == sVal &&
                        widget.selectedAyahNumber == aVal);

                    // Find index of this verse in global widget.verses to match recognizer
                    final globalIdx = widget.verses.indexWhere(
                        (v) => v['surah'] == sVal && v['ayah'] == aVal);

                    return TextSpan(
                      text:
                          '${verse['text']} ﴿${quran.getVerseEndSymbol(aVal)}﴾ ',
                      style: _getQuranTextStyle(isAudioPlaying, isTextSelected),
                      recognizer:
                          (globalIdx != -1 && globalIdx < _recognizers.length)
                              ? _recognizers[globalIdx]
                              : null,
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
        const SizedBox(height: 120),
      ],
    );
  }
}

class SurahHeaderBanner extends StatelessWidget {
  final int surahNumber;
  final String themeMode;

  const SurahHeaderBanner({
    super.key,
    required this.surahNumber,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0F5A47);
    const Color goldColor = Color(0xFFD4AF37);
    final isDark = themeMode == 'dark';

    final String surahName = quran.getSurahNameArabic(surahNumber);
    final String revelationPlace =
        quran.getPlaceOfRevelation(surahNumber) == 'Makyah' ? 'مكية' : 'مدنية';
    final int versesCount = quran.getVerseCount(surahNumber);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: goldColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: goldColor, size: 12),
              const SizedBox(width: 8),
              Text(
                'سورة $surahName',
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? goldColor : primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              Icon(Icons.star, color: goldColor, size: 12),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'نزلت في: $revelationPlace | آياتها: $versesCount',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }
}

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
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color goldColor = const Color(0xFFD4AF37);

    int getHizbNumber(int page) {
      if (page <= 1) return 1;
      return (((page - 2) ~/ 10) + 1).clamp(1, 60);
    }

    final hasBasmalah = widget.verses.isNotEmpty &&
        widget.verses.first['ayah'] == 1 &&
        widget.verses.first['surah'] != 1 &&
        widget.verses.first['surah'] != 9;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الجزء ${quran.getJuzNumber(widget.verses.first['surah'], widget.verses.first['ayah'])}',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeMode == 'sepia' ? const Color(0xFF8C7565) : Colors.grey,
                fontFamily: 'Outfit',
              ),
            ),
            Text(
              'صفحة ${widget.pageNumber}',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeMode == 'sepia' ? const Color(0xFF8C7565) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            Text(
              'الحزب ${getHizbNumber(widget.pageNumber)}',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeMode == 'sepia' ? const Color(0xFF8C7565) : Colors.grey,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
        const Divider(height: 20),
        if (hasBasmalah)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              quran.basmala,
              style: GoogleFonts.amiri(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: widget.themeMode == 'dark'
                    ? Colors.amber[100]
                    : (widget.themeMode == 'sepia' ? const Color(0xFF8C3E15) : primaryColor),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        RichText(
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: List.generate(widget.verses.length, (idx) {
              final verse = widget.verses[idx];
              final sNum = verse['surah'] as int;
              final aNum = verse['ayah'] as int;
              final isAudioPlaying = (widget.activePlayingSurah == sNum && widget.activePlayingAyah == aNum);
              final isTextSelected = (widget.selectedAyahSurah == sNum && widget.selectedAyahNumber == aNum);

              return TextSpan(
                text: '${verse['text']} ﴿${quran.getVerseEndSymbol(aNum)}﴾ ',
                style: _getQuranTextStyle(isAudioPlaying, isTextSelected),
                recognizer: idx < _recognizers.length ? _recognizers[idx] : null,
              );
            }),
          ),
        ),
      ],
    );
  }
}

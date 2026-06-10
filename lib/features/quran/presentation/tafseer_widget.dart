import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/tafseer_service.dart';

class TafseerWidget extends StatefulWidget {
  final int surah;
  final int ayah;
  final String verseText;

  const TafseerWidget({
    super.key,
    required this.surah,
    required this.ayah,
    required this.verseText,
  });

  @override
  State<TafseerWidget> createState() => _TafseerWidgetState();
}

class _TafseerWidgetState extends State<TafseerWidget> {
  String _tafseerText = 'جاري تحميل التفسير...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTafseer();
  }

  Future<void> _loadTafseer() async {
    final text = await TafseerService.getTafseer(widget.surah, widget.ayah);
    if (mounted) {
      setState(() {
        _tafseerText = text;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0F5A47);

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس لوحة التفسير
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'التفسير الميسر',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amber[200] : primaryColor,
                ),
              ),
              const SizedBox(width: 48), // لموازنة زر الإغلاق
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // نص الآية المفسرة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Text(
              widget.verseText,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.8,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 16),

          // نص التفسير
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Text(
                      _tafseerText,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

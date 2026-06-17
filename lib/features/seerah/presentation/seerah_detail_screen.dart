import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/seerah_service.dart';

class SeerahDetailScreen extends StatefulWidget {
  final SeerahEvent event;
  const SeerahDetailScreen({super.key, required this.event});

  @override
  State<SeerahDetailScreen> createState() => _SeerahDetailScreenState();
}

class _SeerahDetailScreenState extends State<SeerahDetailScreen> {
  @override
  void initState() {
    super.initState();
    _saveProgress();
  }

  void _saveProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveSeerahReadingPosition(eventId: widget.event.id);
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
        title: Text(
          widget.event.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stage Header Tag
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accentColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    widget.event.stage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                widget.event.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),

              // Content Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.event.content,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.7,
                          color: isDark ? Colors.grey[200] : Colors.black87,
                        ),
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                      const Divider(height: 32),

                      // Citations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.bookmark_outline,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'المصدر: ${widget.event.source}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
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
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final shareText =
                          '${widget.event.title}\n\n${widget.event.content}\n\nالمصدر: ${widget.event.source}';
                      Share.share(shareText);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('مشاركة المقطع'),
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
                          '${widget.event.title}\n\n${widget.event.content}\n\nالمصدر: ${widget.event.source}';
                      Clipboard.setData(ClipboardData(text: copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ النص بنجاح!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ النص'),
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

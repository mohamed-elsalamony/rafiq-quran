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

  @override
  void initState() {
    super.initState();
    int chapId = widget.initialChapterId ?? 0;
    _chapter = widget.story.chapters.firstWhere(
      (c) => c.id == chapId,
      orElse: () => widget.story.chapters.first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress();
    });
  }

  void _saveProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveProphetReadingPosition(
      storyId: widget.story.id,
      chapterId: _chapter.id,
    );
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
          '${widget.story.name} - ${_chapter.title}',
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
              // Chapter Title
              Text(
                _chapter.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? accentColor : primaryColor,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Narrative Content
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
                        _chapter.content,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.7,
                          color: isDark ? Colors.grey[200] : Colors.black87,
                        ),
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                      const Divider(height: 32),

                      // Citation Source
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.bookmark_outline,
                              size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _chapter.source,
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
              const SizedBox(height: 20),

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
                          color:
                              isDark ? Colors.teal[100] : Colors.teal.shade800,
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: accentColor.withOpacity(0.3), width: 1),
                    ),
                    color: isDark
                        ? const Color(0xFF162320)
                        : const Color(0xFFEDF6F3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '﴿ ${verse.text} ﴾',
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? accentColor : primaryColor,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سورة ${verse.surah} - الآية ${verse.number}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
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

              // Share/Copy Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final shareText =
                          '${_chapter.title}\n\n${_chapter.content}\n\nالمصدر: ${_chapter.source}';
                      Share.share(shareText);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('مشاركة الفصل'),
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
                          '${_chapter.title}\n\n${_chapter.content}\n\nالمصدر: ${_chapter.source}';
                      Clipboard.setData(ClipboardData(text: copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ نص الفصل بنجاح!')),
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

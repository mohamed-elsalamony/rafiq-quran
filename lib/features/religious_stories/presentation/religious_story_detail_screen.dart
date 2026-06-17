import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/religious_stories_service.dart';

class ReligiousStoryDetailScreen extends StatefulWidget {
  final ReligiousStory story;
  const ReligiousStoryDetailScreen({super.key, required this.story});

  @override
  State<ReligiousStoryDetailScreen> createState() =>
      _ReligiousStoryDetailScreenState();
}

class _ReligiousStoryDetailScreenState
    extends State<ReligiousStoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress();
    });
  }

  void _saveProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveReligiousStoryReadingPosition(storyId: widget.story.id);
  }

  void _shareStory() {
    final story = widget.story;
    String shareText = '📚 قصة وعبرة من التراث الإسلامي: ${story.title}\n\n'
        '• الآية أو الحديث المرتبط:\n${story.referenceText}\n\n'
        '• سرد القصة:\n${story.storyText}\n\n'
        '• الدرس المستخلص:\n${story.lesson}\n\n'
        '• المصدر المعتمد:\n${story.source}\n\n'
        'تمت المشاركة من تطبيق رفيق القرآن الكريم';

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    final textStyle = TextStyle(
      fontSize:
          appState.fontSize - 4, // Adjust size dynamically based on settings
      height: 1.8,
      color: isDark ? Colors.grey[300] : Colors.grey[900],
      fontFamily: 'Amiri',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.story.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareStory,
            tooltip: 'مشاركة القصة',
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark
                          ? const Color(0xFF1D3C34)
                          : const Color(0xFFE8F3EF),
                      child: const Icon(
                        Icons.collections_bookmark_rounded,
                        size: 32,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.story.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? accentColor : primaryColor,
                        fontFamily: 'Amiri',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2E2215)
                            : const Color(0xFFFAF5ED),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF4C3E2A)
                              : Colors.amber[100]!,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        'التصنيف: ${widget.story.category}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? accentColor : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Verse or Hadith Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: accentColor, width: 1.2)),
              color: isDark ? const Color(0xFF1A211D) : const Color(0xFFEDF5F1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'الآية أو الحديث المرتبط بالقصة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? accentColor : primaryColor,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.bookmark_added_outlined,
                            color: accentColor, size: 18),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      widget.story.referenceText,
                      style: TextStyle(
                        fontSize: appState.fontSize - 3,
                        height: 1.8,
                        color: isDark ? Colors.amber[100] : primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy,
                              size: 16, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: widget.story.referenceText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ النص المرتبط بنجاح',
                                    textAlign: TextAlign.center),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'نسخ النص المرتبط',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Narrative Section
            _buildSectionCard(
              title: 'سرد القصة كاملة',
              content: widget.story.storyText,
              icon: Icons.menu_book_rounded,
              isDark: isDark,
              primaryColor: primaryColor,
              accentColor: accentColor,
              textStyle: textStyle,
            ),

            // Lesson Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'الدرس المستخلص (ماذا نتعلم؟)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? accentColor : primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.lightbulb_outline, color: accentColor),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2E2215)
                            : const Color(0xFFFAF5ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF4C3E2A)
                              : Colors.amber[100]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.story.lesson,
                        style: textStyle,
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy,
                              size: 16, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.story.lesson));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ الدرس المستخلص بنجاح',
                                    textAlign: TextAlign.center),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'نسخ الدرس المستخلص',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Source Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'المصدر بالتفصيل: ${widget.story.source}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    required Color accentColor,
    required TextStyle textStyle,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? accentColor : primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: accentColor),
              ],
            ),
            const Divider(height: 24),
            Text(
              content,
              style: textStyle,
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ $title بنجاح',
                            textAlign: TextAlign.center),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: 'نسخ النص',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

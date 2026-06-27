import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/companions_service.dart';

class CompanionDetailScreen extends StatefulWidget {
  final Companion companion;
  const CompanionDetailScreen({super.key, required this.companion});

  @override
  State<CompanionDetailScreen> createState() => _CompanionDetailScreenState();
}

class _CompanionDetailScreenState extends State<CompanionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress();
    });
  }

  void _saveProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveCompanionReadingPosition(companionId: widget.companion.id);
  }

  void _shareCompanion() {
    final companion = widget.companion;
    String shareText = 'ترجمة الصحابي الجليل: ${companion.name}\n\n'
        '• النسب والنشأة:\n${companion.lineage}\n\n'
        '• قصة إسلامه:\n${companion.islam}\n\n'
        '• مواقفه مع الرسول ﷺ:\n${companion.moments}\n\n'
        '• مناقبه وصفاته:\n${companion.virtues}\n\n';

    if (companion.hadiths.isNotEmpty) {
      shareText += '• من رواياته للحديث:\n';
      for (var h in companion.hadiths) {
        shareText += '- $h\n';
      }
      shareText += '\n';
    }

    shareText += 'المصادر: ${companion.sources}\n';
    shareText += 'تمت المشاركة من تطبيق رفيق القرآن الكريم';

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    final textStyle = TextStyle(
      fontSize: 16,
      height: 1.8,
      color: isDark ? Colors.grey[350] : Colors.grey[800],
      fontFamily: 'Amiri',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.companion.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCompanion,
            tooltip: 'مشاركة الترجمة',
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
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: primaryColor,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.companion.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? accentColor : primaryColor,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: widget.companion.categories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1D3C34)
                                : const Color(0xFFE8F3EF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? primaryColor : Colors.teal[100]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? accentColor : primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lineage
            _buildSectionCard(
              title: 'النسب والنشأة والمولد',
              content: widget.companion.lineage,
              icon: Icons.account_tree_rounded,
              isDark: isDark,
              primaryColor: primaryColor,
              accentColor: accentColor,
              textStyle: textStyle,
            ),

            // Islam
            _buildSectionCard(
              title: 'إسلامه وكيف أسلم',
              content: widget.companion.islam,
              icon: Icons.brightness_5,
              isDark: isDark,
              primaryColor: primaryColor,
              accentColor: accentColor,
              textStyle: textStyle,
            ),

            // Moments
            _buildSectionCard(
              title: 'مواقفه مع الرسول ﷺ والغزوات',
              content: widget.companion.moments,
              icon: Icons.star_rounded,
              isDark: isDark,
              primaryColor: primaryColor,
              accentColor: accentColor,
              textStyle: textStyle,
            ),

            // Virtues
            _buildSectionCard(
              title: 'أبرز صفاته ومناقبه وفضائله',
              content: widget.companion.virtues,
              icon: Icons.workspace_premium,
              isDark: isDark,
              primaryColor: primaryColor,
              accentColor: accentColor,
              textStyle: textStyle,
            ),

            // Hadiths
            if (widget.companion.hadiths.isNotEmpty)
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
                            'رواياته من الحديث النبوي الشريف',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? accentColor : primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.menu_book, color: accentColor),
                        ],
                      ),
                      const Divider(height: 24),
                      ...widget.companion.hadiths.map((hadith) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252525)
                                  : const Color(0xFFFAF9F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  hadith,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.8,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[900],
                                    fontFamily: 'Amiri',
                                  ),
                                  textAlign: TextAlign.justify,
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
                                        Clipboard.setData(
                                            ClipboardData(text: hadith));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('تم نسخ الحديث بنجاح',
                                                textAlign: TextAlign.center),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      tooltip: 'نسخ الحديث',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Sources card
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
                        'المصادر المعتمدة: ${widget.companion.sources}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  tooltip: 'نسخ المقطع',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

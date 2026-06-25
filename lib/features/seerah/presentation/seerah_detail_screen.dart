import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/seerah_service.dart';

class SeerahDetailScreen extends StatefulWidget {
  final SeerahEvent event;
  const SeerahDetailScreen({super.key, required this.event});

  @override
  State<SeerahDetailScreen> createState() => _SeerahDetailScreenState();
}

class _SeerahDetailScreenState extends State<SeerahDetailScreen> {
  late SeerahEvent _currentEvent;
  final SeerahService _service = SeerahService();
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _saveProgress();
    _checkFavorite();
  }

  void _saveProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveSeerahReadingPosition(eventId: _currentEvent.id);
  }

  Future<void> _checkFavorite() async {
    final fav = await _service.isFavorite(_currentEvent.id);
    if (mounted) {
      setState(() {
        _isFav = fav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _service.toggleFavorite(_currentEvent.id);
    _checkFavorite();
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
          'تفاصيل الحدث',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 16,
          ),
        ),
        centerTitle: true,
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stage Tag & Time/Location info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
                          ),
                          child: Text(
                            _currentEvent.stage,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                        if (_currentEvent.hijriDate != null)
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                _currentEvent.hijriDate!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Location Info
                    if (_currentEvent.location.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'المكان: ${_currentEvent.location}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Title
                    Text(
                      _currentEvent.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                        fontFamily: 'Amiri',
                        height: 1.4,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),

                    // Characters Section
                    if (_currentEvent.characters.isNotEmpty) ...[
                      const Text(
                        'الشخصيات المرتبطة:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        textDirection: TextDirection.rtl,
                        children: _currentEvent.characters.map((c) {
                          return Chip(
                            label: Text(
                              c,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white : primaryColor,
                              ),
                            ),
                            backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8F3EF),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Main Narrative content
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _currentEvent.content,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.7,
                                color: isDark ? Colors.grey[200] : Colors.black87,
                              ),
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                            ),
                            const Divider(height: 32),
                            // Citation/Source
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.bookmark_outline, size: 16, color: Colors.teal),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'المصدر: ${_currentEvent.source}',
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
                    const SizedBox(height: 16),

                    // Associated Verses Section
                    if (_currentEvent.verses != null && _currentEvent.verses!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Text(
                          'الآيات القرآنية المرتبطة:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      ..._currentEvent.verses!.map((verse) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF152A22) : const Color(0xFFF1F8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '﴿ ${verse['text']} ﴾',
                                style: GoogleFonts.amiri(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFBCE3D5) : primaryColor,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '[ سورة ${verse['surah']} • آية ${verse['number']} ]',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                    ],

                    // Graded Hadiths Section
                    if (_currentEvent.hadiths != null && _currentEvent.hadiths!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Text(
                          'الأحاديث الصحيحة المرتبطة:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      ..._currentEvent.hadiths!.map((hadith) {
                        final grade = hadith['grade'] ?? 'صحيح';
                        final isSahih = grade.contains('صحيح');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '« ${hadith['text']} »',
                                style: GoogleFonts.amiri(
                                  fontSize: 17,
                                  color: isDark ? Colors.grey[300] : Colors.grey[900],
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSahih ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSahih ? Colors.green.withOpacity(0.4) : Colors.orange.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      grade,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSahih ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'رواه: ${hadith['source']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                    ],

                    // Lessons Learned Section
                    if (_currentEvent.lessons != null && _currentEvent.lessons!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: Text(
                          'الدروس والفوائد المستفادة:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _currentEvent.lessons!.map((lesson) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      color: accentColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        lesson,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                                        ),
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Copy & Share buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            final shareText = '${_currentEvent.title}\n\n${_currentEvent.content}\n\nالمصدر: ${_currentEvent.source}';
                            Share.share(shareText);
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('مشاركة المقطع'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            final copyText = '${_currentEvent.title}\n\n${_currentEvent.content}\n\nالمصدر: ${_currentEvent.source}';
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Chronological Navigation Row at bottom
            _buildNavRow(primaryColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow(Color primaryColor, bool isDark) {
    final allEvents = _service.getAllEvents();
    final currentIndex = allEvents.indexWhere((e) => e.id == _currentEvent.id);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < allEvents.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Event (chronologically previous - smaller id. Renders on right in RTL)
            if (hasPrev)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentEvent = allEvents[currentIndex - 1];
                    _saveProgress();
                    _checkFavorite();
                  });
                },
                icon: const Icon(Icons.chevron_right),
                label: const Text('الحدث السابق'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              )
            else
              const SizedBox(),

            // Next Event (chronologically next - larger id. Renders on left in RTL)
            if (hasNext)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentEvent = allEvents[currentIndex + 1];
                    _saveProgress();
                    _checkFavorite();
                  });
                },
                icon: const Icon(Icons.chevron_left),
                label: const Text('الحدث التالي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              )
            else
              const SizedBox(),
          ],
        ),
      ),
    );
  }
}

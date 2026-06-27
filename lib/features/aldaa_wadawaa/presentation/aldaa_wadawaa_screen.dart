import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/aldaa_wadawaa_service.dart';
import 'aldaa_wadawaa_category_screen.dart';
import 'aldaa_wadawaa_detail_screen.dart';

class AldaaWadawaaScreen extends StatefulWidget {
  const AldaaWadawaaScreen({super.key});

  @override
  State<AldaaWadawaaScreen> createState() => _AldaaWadawaaScreenState();
}

class _AldaaWadawaaScreenState extends State<AldaaWadawaaScreen> {
  final AldaaWadawaaService _bookService = AldaaWadawaaService();
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'الدعاء والشفاء',
      'icon': Icons.healing_rounded,
      'desc':
          'أهمية الدعاء وشروطه، وكيف يكون الدعاء سلاحاً للمؤمن ودواءً للقلب',
      'chapterIds': [1, 2, 3, 4],
    },
    {
      'name': 'المعاصي وآثارها',
      'icon': Icons.warning_amber_rounded,
      'desc': 'آثار الذنوب والمعاصي في حرمان العبد وحجب إجابة الدعاء',
      'chapterIds': [5],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  Future<void> _loadBookData() async {
    await _bookService.loadChapters();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    final lastReadId = appState.lastReadAldaaWadawaaChapterId;
    final lastReadChapter =
        lastReadId > 0 ? _bookService.getChapterById(lastReadId) : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'كتاب الداء والدواء',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 16,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor))
            : Column(
                children: [
                  // Resume Reading Card
                  if (lastReadChapter != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Card(
                        color: isDark
                            ? const Color(0xFF1B3D34)
                            : const Color(0xFFE8F3EF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AldaaWadawaaDetailScreen(
                                    chapter: lastReadChapter),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_filled,
                                    color: accentColor, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'متابعة القراءة من حيث توقفت',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'آخر فصل: ${lastReadChapter.title} (صفحة ${lastReadChapter.page})',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_back_ios,
                                    size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Categories Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final String name = cat['name'] as String;
                        final IconData icon = cat['icon'] as IconData;
                        final String desc = cat['desc'] as String;
                        final List<int> chapterIds =
                            cat['chapterIds'] as List<int>;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AldaaWadawaaCategoryScreen(
                                    categoryName: name,
                                    chapterIds: chapterIds,
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: isDark
                                        ? const Color(0xFF1D3C34)
                                        : const Color(0xFFE8F3EF),
                                    child: Icon(
                                      icon,
                                      size: 30,
                                      color:
                                          isDark ? accentColor : primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

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
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<int> _favChapterIds = [];
  String _searchQuery = '';
  List<AldaaWadawaaChapter> _searchResults = [];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'الدعاء وعلاج البلاء',
      'icon': Icons.healing_rounded,
      'desc': 'أهمية الدعاء وشروطه، والالحاح فيه وعلاقته بالقدر وكيف يكون سلاحاً ودواءً للقلب',
      'chapterIds': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    },
    {
      'name': 'عقوبات الذنوب والمعاصي',
      'icon': Icons.warning_amber_rounded,
      'desc': 'تفصيل آثار الذنوب والمعاصي في حرمان العبد وتأثيرها على العقل والبدن ومحق البركة',
      'chapterIds': [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38],
    },
    {
      'name': 'الحدود والذنوب الكبرى',
      'icon': Icons.gavel_rounded,
      'desc': 'التحذير من كبائر الذنوب والشرك والقتل والزنا واللوط وأحكام الجنايات والحدود الشرعية',
      'chapterIds': [39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53],
    },
    {
      'name': 'أدوية القلوب وتجريد التوحيد',
      'icon': Icons.favorite_rounded,
      'desc': 'سبيل عيش القلب السليم وصلاحه والتخلص من الشرك في المحبة والإرادات والنيات',
      'chapterIds': [54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67],
    },
    {
      'name': 'علاج العشق والشهوات',
      'icon': Icons.heart_broken_rounded,
      'desc': 'بيان داء عشق الصور والتعلق بالخلق ومفاسده، وسبل العلاج بغض البصر وصيانة الجوارح',
      'chapterIds': [68, 69, 70, 71, 72],
    },
    {
      'name': 'التوبة النصوح والخاتمة',
      'icon': Icons.verified_user_rounded,
      'desc': 'حقيقة التوبة النصوح وشروط قبولها للنجاة في الدنيا والآخرة وخاتمة كتاب الجواب الكافي',
      'chapterIds': [73, 74, 75],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookData() async {
    await _bookService.loadChapters();
    final favIds = await _bookService.getFavoriteChapterIds();
    if (mounted) {
      setState(() {
        _favChapterIds = favIds;
        _isLoading = false;
        // Refresh search results if search is active
        if (_searchQuery.isNotEmpty) {
          _searchResults = _bookService.searchChapters(_searchQuery);
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _searchResults = _bookService.searchChapters(query);
    });
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: _searchQuery.isNotEmpty
              ? null
              : const TabBar(
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: accentColor,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
                  tabs: [
                    Tab(text: 'فهرس الفصول'),
                    Tab(text: 'أقسام الكتاب'),
                    Tab(text: 'المفضلة والإشارات'),
                  ],
                ),
        ),
        body: Container(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryColor))
              : Column(
                  children: [
                    // Global Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: TextField(
                          controller: _searchController,
                          textAlign: TextAlign.right,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'ابحث في الكتاب كاملاً (بالعنوان والمحتوى)...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // Main Content / Search Results
                    Expanded(
                      child: _searchQuery.isNotEmpty
                          ? _buildSearchResults(isDark, primaryColor, accentColor, appState)
                          : _buildTabContent(isDark, primaryColor, accentColor, lastReadChapter, appState),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
      bool isDark, Color primaryColor, Color accentColor, AppState appState) {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج بحث مطابقة',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final chapter = _searchResults[index];

        // Find a search snippet
        String snippet = chapter.content;
        final cleanQuery = _searchQuery.toLowerCase();
        final matchIdx = snippet.toLowerCase().indexOf(cleanQuery);
        if (matchIdx != -1) {
          final start = (matchIdx - 30).clamp(0, snippet.length);
          final end = (matchIdx + cleanQuery.length + 60).clamp(0, snippet.length);
          snippet = "...${snippet.substring(start, end).trim()}...";
        } else if (snippet.length > 120) {
          snippet = "${snippet.substring(0, 120).trim()}...";
        }

        return _buildChapterCard(
            chapter, snippet, isDark, primaryColor, accentColor, appState);
      },
    );
  }

  Widget _buildTabContent(
      bool isDark,
      Color primaryColor,
      Color accentColor,
      AldaaWadawaaChapter? lastReadChapter,
      AppState appState) {
    return Column(
      children: [
        // Resume Reading Card
        if (lastReadChapter != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              color: isDark ? const Color(0xFF1B3D34) : const Color(0xFFE8F3EF),
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
                  ).then((_) => _loadBookData());
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_filled,
                          color: accentColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'متابعة القراءة من حيث توقفت',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
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

        // Tabs Content
        Expanded(
          child: TabBarView(
            children: [
              // Tab 1: فهرس الفصول
              _buildChaptersList(isDark, primaryColor, accentColor, appState),

              // Tab 2: أقسام الكتاب
              _buildCategoriesGrid(isDark, primaryColor, accentColor),

              // Tab 3: المفضلة والإشارات
              _buildFavoritesList(isDark, primaryColor, accentColor, appState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersList(
      bool isDark, Color primaryColor, Color accentColor, AppState appState) {
    final allChapters = _bookService.getAllChapters();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: allChapters.length,
      itemBuilder: (context, index) {
        final chapter = allChapters[index];
        String snippet = chapter.content;
        if (snippet.length > 120) {
          snippet = "${snippet.substring(0, 120).trim()}...";
        }
        return _buildChapterCard(
            chapter, snippet, isDark, primaryColor, accentColor, appState);
      },
    );
  }

  Widget _buildFavoritesList(
      bool isDark, Color primaryColor, Color accentColor, AppState appState) {
    final allChapters = _bookService.getAllChapters();
    final favChapters =
        allChapters.where((c) => _favChapterIds.contains(c.id)).toList();

    if (favChapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_outline_rounded,
                  size: 64,
                  color: isDark ? Colors.grey[700] : Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'لا توجد علامات مرجعية أو مفضلة بعد',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'يمكنك حفظ الفصول المفضلة بالضغط على علامة النجمة في أعلى صفحة القارئ للرجوع إليها لاحقاً.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: favChapters.length,
      itemBuilder: (context, index) {
        final chapter = favChapters[index];
        String snippet = chapter.content;
        if (snippet.length > 120) {
          snippet = "${snippet.substring(0, 120).trim()}...";
        }
        return _buildChapterCard(
            chapter, snippet, isDark, primaryColor, accentColor, appState);
      },
    );
  }

  Widget _buildCategoriesGrid(
      bool isDark, Color primaryColor, Color accentColor) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final String name = cat['name'] as String;
        final IconData icon = cat['icon'] as IconData;
        final String desc = cat['desc'] as String;
        final List<int> chapterIds = cat['chapterIds'] as List<int>;

        return Card(
          elevation: 2.5,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AldaaWadawaaCategoryScreen(
                    categoryName: name,
                    chapterIds: chapterIds,
                  ),
                ),
              ).then((_) => _loadBookData());
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isDark
                        ? const Color(0xFF1D3C34)
                        : const Color(0xFFE8F3EF),
                    child: Icon(
                      icon,
                      size: 26,
                      color: isDark ? accentColor : primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Amiri',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${chapterIds.length} فصول',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterCard(
      AldaaWadawaaChapter chapter,
      String snippet,
      bool isDark,
      Color primaryColor,
      Color accentColor,
      AppState appState) {
    final isLastRead = appState.lastReadAldaaWadawaaChapterId == chapter.id;
    final isFav = _favChapterIds.contains(chapter.id);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isLastRead ? accentColor : Colors.transparent,
          width: isLastRead ? 1.5 : 0.0,
        ),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AldaaWadawaaDetailScreen(
                  chapter: chapter),
            ),
          ).then((_) => _loadBookData());
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chapter.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isLastRead
                                  ? accentColor
                                  : (isDark ? Colors.white : primaryColor),
                              fontFamily: 'Amiri',
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        if (isFav)
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.star_rounded,
                                color: accentColor, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snippet,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.45,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ص ${chapter.page}',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

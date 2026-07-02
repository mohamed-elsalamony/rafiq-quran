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

class _AldaaWadawaaScreenState extends State<AldaaWadawaaScreen>
    with SingleTickerProviderStateMixin {
  final AldaaWadawaaService _bookService = AldaaWadawaaService();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  bool _isLoading = true;
  List<int> _favChapterIds = [];
  String _searchQuery = '';
  List<AldaaWadawaaChapter> _searchResults = [];

  static const Color _primaryColor = Color(0xFF0F5A47);
  static const Color _accentColor = Color(0xFFD4AF37);

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'الدعاء وعلاج البلاء',
      'icon': Icons.healing_rounded,
      'desc': 'أهمية الدعاء وشروطه والإلحاح فيه وعلاقته بالقدر',
      'chapterIds': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      'color': const Color(0xFF1B6B52),
    },
    {
      'name': 'عقوبات الذنوب والمعاصي',
      'icon': Icons.warning_amber_rounded,
      'desc': 'آثار الذنوب على العقل والبدن ومحق البركة والنعم',
      'chapterIds': [
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        31, 32, 33, 34, 35, 36, 37, 38
      ],
      'color': const Color(0xFF8B4513),
    },
    {
      'name': 'الحدود والذنوب الكبرى',
      'icon': Icons.gavel_rounded,
      'desc': 'التحذير من كبائر الذنوب وأحكام الحدود الشرعية',
      'chapterIds': [39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53],
      'color': const Color(0xFF6B2D2D),
    },
    {
      'name': 'أدوية القلوب والتوحيد',
      'icon': Icons.favorite_rounded,
      'desc': 'سبيل صلاح القلب والتخلص من الشرك في المحبة والإرادات',
      'chapterIds': [54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67],
      'color': const Color(0xFF0F5A47),
    },
    {
      'name': 'علاج العشق والشهوات',
      'icon': Icons.heart_broken_rounded,
      'desc': 'داء عشق الصور وسبل العلاج بغض البصر وصيانة الجوارح',
      'chapterIds': [68, 69, 70, 71, 72],
      'color': const Color(0xFF6B4C8B),
    },
    {
      'name': 'التوبة النصوح والخاتمة',
      'icon': Icons.verified_user_rounded,
      'desc': 'حقيقة التوبة النصوح وشروط قبولها للنجاة في الدارين',
      'chapterIds': [73, 74, 75],
      'color': const Color(0xFF2E5D8A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookData() async {
    await _bookService.loadChapters();
    final favIds = await _bookService.getFavoriteChapterIds();
    if (mounted) {
      setState(() {
        _favChapterIds = favIds;
        _isLoading = false;
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

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final lastReadId = appState.lastReadAldaaWadawaaChapterId;
    final lastReadChapter =
        lastReadId > 0 ? _bookService.getChapterById(lastReadId) : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'كتاب الداء والدواء',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 17,
          ),
        ),
        bottom: _searchQuery.isNotEmpty
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: _accentColor,
                unselectedLabelColor: Colors.white60,
                indicatorColor: _accentColor,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    fontFamily: 'Amiri'),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12, fontFamily: 'Amiri'),
                tabs: const [
                  Tab(text: 'فهرس الفصول'),
                  Tab(text: 'أقسام الكتاب'),
                  Tab(text: 'المفضلة'),
                ],
              ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryColor))
            : Column(
                children: [
                  // شريط البحث
                  _buildSearchBar(isDark),

                  // المحتوى الرئيسي
                  Expanded(
                    child: _searchQuery.isNotEmpty
                        ? _buildSearchResults(isDark, appState)
                        : _buildTabContent(isDark, lastReadChapter, appState),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // أيقونة البحث على اليمين (RTL)
              Padding(
                padding: const EdgeInsets.only(right: 10, left: 4),
                child: Icon(
                  Icons.search_rounded,
                  color: _searchQuery.isNotEmpty
                      ? _primaryColor
                      : Colors.grey[400],
                  size: 22,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Amiri',
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث في الكتاب بالعنوان أو المحتوى...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'Amiri',
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              // زر مسح البحث
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _searchQuery.isNotEmpty
                    ? IconButton(
                        key: const ValueKey('clear'),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.grey, size: 20),
                        onPressed: _clearSearch,
                      )
                    : const SizedBox(width: 8, key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    bool isDark,
    AldaaWadawaaChapter? lastReadChapter,
    AppState appState,
  ) {
    return Column(
      children: [
        // بطاقة متابعة القراءة
        if (lastReadChapter != null) _buildResumeCard(isDark, lastReadChapter),

        // التبويبات
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChaptersList(isDark, appState),
              _buildCategoriesGrid(isDark),
              _buildFavoritesList(isDark, appState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumeCard(bool isDark, AldaaWadawaaChapter chapter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Card(
        elevation: 1.5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? const Color(0xFF1B3D34) : const Color(0xFFE6F3EE),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AldaaWadawaaDetailScreen(chapter: chapter),
              ),
            ).then((_) => _loadBookData());
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: _accentColor, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'متابعة القراءة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Amiri',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[600],
                          fontFamily: 'Amiri',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_back_ios_rounded,
                    size: 13, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, AppState appState) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج لـ "$_searchQuery"',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: 'Amiri'),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            '${_searchResults.length} نتيجة',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontFamily: 'Amiri',
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final chapter = _searchResults[index];
              String snippet = chapter.content;
              final cleanQuery = _searchQuery.toLowerCase();
              final matchIdx = snippet.toLowerCase().indexOf(cleanQuery);
              if (matchIdx != -1) {
                final start = (matchIdx - 20).clamp(0, snippet.length);
                final end =
                    (matchIdx + cleanQuery.length + 80).clamp(0, snippet.length);
                snippet = '...${snippet.substring(start, end).trim()}...';
              } else if (snippet.length > 100) {
                snippet = '${snippet.substring(0, 100).trim()}...';
              }
              return _buildChapterCard(chapter, snippet, isDark, appState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersList(bool isDark, AppState appState) {
    final allChapters = _bookService.getAllChapters();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: allChapters.length,
      itemBuilder: (context, index) {
        final chapter = allChapters[index];
        String snippet = chapter.content;
        if (snippet.length > 100) {
          snippet = '${snippet.substring(0, 100).trim()}...';
        }
        return _buildChapterCard(chapter, snippet, isDark, appState);
      },
    );
  }

  Widget _buildFavoritesList(bool isDark, AppState appState) {
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
              Icon(Icons.star_border_rounded,
                  size: 64,
                  color: isDark ? Colors.grey[700] : Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'لا توجد فصول محفوظة',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط على النجمة داخل الفصل لحفظه هنا',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  height: 1.5,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: favChapters.length,
      itemBuilder: (context, index) {
        final chapter = favChapters[index];
        String snippet = chapter.content;
        if (snippet.length > 100) {
          snippet = '${snippet.substring(0, 100).trim()}...';
        }
        return _buildChapterCard(chapter, snippet, isDark, appState);
      },
    );
  }

  Widget _buildCategoriesGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final String name = cat['name'] as String;
        final IconData icon = cat['icon'] as IconData;
        final String desc = cat['desc'] as String;
        final List<int> chapterIds = cat['chapterIds'] as List<int>;
        final Color catColor = cat['color'] as Color;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AldaaWadawaaCategoryScreen(
                    categoryName: name,
                    chapterIds: chapterIds,
                  ),
                ),
              ).then((_) => _loadBookData());
            },
            child: Column(
              children: [
                // رأس الكارد
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        catColor,
                        catColor.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, size: 30, color: Colors.white),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // جسم الكارد
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Expanded(
                          child: Text(
                            desc,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              height: 1.4,
                              fontFamily: 'Amiri',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: catColor.withOpacity(0.25)),
                          ),
                          child: Text(
                            '${chapterIds.length} فصلاً',
                            style: TextStyle(
                              fontSize: 10,
                              color: catColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                            ),
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
      },
    );
  }

  Widget _buildChapterCard(
    AldaaWadawaaChapter chapter,
    String snippet,
    bool isDark,
    AppState appState,
  ) {
    final isLastRead = appState.lastReadAldaaWadawaaChapterId == chapter.id;
    final isFav = _favChapterIds.contains(chapter.id);
    final chapterIndex = _bookService.getChapterIndex(chapter.id);
    final chapterNum = chapterIndex >= 0 ? chapterIndex + 1 : chapter.id;

    return Card(
      elevation: isLastRead ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLastRead
              ? _accentColor
              : (isFav
                  ? _accentColor.withOpacity(0.3)
                  : Colors.transparent),
          width: isLastRead ? 1.5 : (isFav ? 1.0 : 0.0),
        ),
      ),
      color: isDark
          ? (isLastRead
              ? const Color(0xFF1F2D28)
              : const Color(0xFF1E1E1E))
          : (isLastRead
              ? const Color(0xFFF0F8F4)
              : Colors.white),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AldaaWadawaaDetailScreen(chapter: chapter),
            ),
          ).then((_) => _loadBookData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رقم الفصل
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isLastRead
                      ? _accentColor.withOpacity(0.15)
                      : (isDark
                          ? Colors.grey[800]
                          : const Color(0xFFE8F3EF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$chapterNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLastRead
                          ? _accentColor
                          : (isDark ? Colors.white70 : _primaryColor),
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // العنوان والمقتطف
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isFav)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.star_rounded,
                                color: _accentColor, size: 15),
                          ),
                        if (isLastRead)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'آخر قراءة',
                              style: TextStyle(
                                fontSize: 9,
                                color: _accentColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            chapter.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isLastRead
                                  ? _accentColor
                                  : (isDark ? Colors.white : _primaryColor),
                              fontFamily: 'Amiri',
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      snippet,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.5,
                        fontFamily: 'Amiri',
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // رقم الصفحة
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'ص\n${chapter.page}',
                  style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    fontFamily: 'Amiri',
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
  }
}

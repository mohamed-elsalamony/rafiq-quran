import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/hadith_service.dart';
import 'hadith_detail_screen.dart';

class HadithCategoryScreen extends StatefulWidget {
  final String categoryKey;
  final String categoryName;
  const HadithCategoryScreen(
      {super.key, required this.categoryKey, required this.categoryName});

  @override
  State<HadithCategoryScreen> createState() => _HadithCategoryScreenState();
}

class _HadithCategoryScreenState extends State<HadithCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HadithService _service = HadithService();
  List<Hadith> _allHadiths = [];
  List<Hadith> _filteredHadiths = [];
  List<int> _favoriteIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHadithData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHadithData() async {
    await _service.loadHadiths();
    final favIds = await _service.getFavoriteHadithIds();

    if (mounted) {
      setState(() {
        _allHadiths = _service.getAllHadiths();
        _favoriteIds = favIds;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Hadith> baseList = [];

    switch (widget.categoryKey) {
      case 'all':
        baseList = _allHadiths;
        break;
      case 'Nawawi':
        baseList = _service.getHadithsByCategory('Nawawi');
        break;
      case 'Bukhari':
        baseList = _service.getHadithsByCategory('Bukhari');
        break;
      case 'Muslim':
        baseList = _service.getHadithsByCategory('Muslim');
        break;
      case 'Riyad':
        baseList = _service.getHadithsByCategory('Riyad');
        break;
      case 'favorite':
        baseList =
            _allHadiths.where((h) => _favoriteIds.contains(h.id)).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      baseList = baseList
          .where((h) =>
              h.text.contains(_searchQuery) ||
              h.explanation.contains(_searchQuery) ||
              h.source.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    _filteredHadiths = baseList;
  }

  void _applySearch(String val) {
    setState(() {
      _searchQuery = val.trim();
      _applyFilters();
    });
  }

  Future<void> _toggleFavorite(int hadithId) async {
    await _service.toggleFavorite(hadithId);
    final favIds = await _service.getFavoriteHadithIds();
    setState(() {
      _favoriteIds = favIds;
      _applyFilters();
    });
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
          widget.categoryName,
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
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  onChanged: _applySearch,
                  decoration: InputDecoration(
                    hintText: 'ابحث في الأحاديث...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch('');
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

            // Hadiths List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : _filteredHadiths.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'لا توجد أحداث متوفرة في هذا القسم'
                                : 'لا توجد نتائج بحث مطابقة',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredHadiths.length,
                          itemBuilder: (context, index) {
                            final hadith = _filteredHadiths[index];
                            final isFav = _favoriteIds.contains(hadith.id);
                            String snippet = hadith.text;
                            if (snippet.length > 120) {
                              snippet = '${snippet.substring(0, 120)}...';
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HadithDetailScreen(hadith: hadith),
                                    ),
                                  ).then((_) => _loadHadithData());
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'حديث ${index + 1}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? accentColor
                                                    : primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '« $snippet »',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : Colors.black87,
                                                height: 1.5,
                                                fontFamily: 'Amiri',
                                              ),
                                              textAlign: TextAlign.right,
                                              textDirection: TextDirection.rtl,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'رواه: ${hadith.source}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          isFav
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              isFav ? Colors.red : Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _toggleFavorite(hadith.id),
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

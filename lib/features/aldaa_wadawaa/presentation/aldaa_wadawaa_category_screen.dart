import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/aldaa_wadawaa_service.dart';
import 'aldaa_wadawaa_detail_screen.dart';

class AldaaWadawaaCategoryScreen extends StatefulWidget {
  final String categoryName;
  final List<int> chapterIds;
  const AldaaWadawaaCategoryScreen({
    super.key,
    required this.categoryName,
    required this.chapterIds,
  });

  @override
  State<AldaaWadawaaCategoryScreen> createState() =>
      _AldaaWadawaaCategoryScreenState();
}

class _AldaaWadawaaCategoryScreenState
    extends State<AldaaWadawaaCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AldaaWadawaaService _bookService = AldaaWadawaaService();
  List<AldaaWadawaaChapter> _filteredChapters = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
    _applyFilter();
  }

  void _applyFilter() {
    if (mounted) {
      setState(() {
        final allChapters = _bookService.getAllChapters();
        final categoryChapters =
            allChapters.where((c) => widget.chapterIds.contains(c.id)).toList();

        if (_searchQuery.isEmpty) {
          _filteredChapters = categoryChapters;
        } else {
          _filteredChapters = categoryChapters
              .where((c) =>
                  c.title.contains(_searchQuery) ||
                  c.content.contains(_searchQuery) ||
                  c.page.toString().contains(_searchQuery))
              .toList();
        }
        _isLoading = false;
      });
    }
  }

  void _applySearch(String val) {
    _searchQuery = val.trim();
    _applyFilter();
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
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
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
                    hintText: 'ابحث في فصول هذا القسم...',
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

            // Chapters List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : _filteredChapters.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'لا توجد فصول متوفرة في هذا القسم'
                                : 'لا توجد نتائج بحث مطابقة',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredChapters.length,
                          itemBuilder: (context, index) {
                            final chapter = _filteredChapters[index];
                            String snippet = chapter.content;
                            if (snippet.length > 120) {
                              snippet = '${snippet.substring(0, 120)}...';
                            }

                            final isLastRead =
                                appState.lastReadAldaaWadawaaChapterId ==
                                    chapter.id;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isLastRead
                                      ? accentColor
                                      : Colors.transparent,
                                  width: isLastRead ? 1.5 : 0.0,
                                ),
                              ),
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AldaaWadawaaDetailScreen(
                                              chapter: chapter),
                                    ),
                                  ).then((_) => setState(() {}));
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
                                              chapter.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isLastRead
                                                    ? accentColor
                                                    : (isDark
                                                        ? Colors.white
                                                        : primaryColor),
                                                fontFamily: 'Amiri',
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              snippet,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.right,
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ص ${chapter.page}',
                                          style: const TextStyle(
                                            color: accentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
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
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

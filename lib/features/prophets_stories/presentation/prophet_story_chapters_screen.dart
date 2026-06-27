import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/prophets_stories_service.dart';
import 'prophet_story_detail_screen.dart';

class ProphetStoryChaptersScreen extends StatefulWidget {
  final ProphetStory story;
  const ProphetStoryChaptersScreen({super.key, required this.story});

  @override
  State<ProphetStoryChaptersScreen> createState() =>
      _ProphetStoryChaptersScreenState();
}

class _ProphetStoryChaptersScreenState
    extends State<ProphetStoryChaptersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProphetsStoriesService _service = ProphetsStoriesService();
  List<ProphetChapter> _filteredChapters = [];
  Set<int> _favoriteChapterIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredChapters = widget.story.chapters;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final ids = await _service.getFavoriteChapterIds();
    if (mounted) {
      setState(() {
        _favoriteChapterIds = ids.toSet();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String val) {
    setState(() {
      _searchQuery = val.trim();
      if (_searchQuery.isEmpty) {
        _filteredChapters = widget.story.chapters;
      } else {
        _filteredChapters = widget.story.chapters.where((chapter) {
          return chapter.title.contains(_searchQuery) ||
              chapter.content.contains(_searchQuery) ||
              chapter.source.contains(_searchQuery);
        }).toList();
      }
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
          'فصول قصة ${widget.story.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 18,
          ),
        ),
        centerTitle: false,
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
                    hintText: 'ابحث في فصول القصة...',
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
              child: _filteredChapters.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'لا توجد فصول متوفرة'
                            : 'لا توجد نتائج بحث مطابقة',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
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

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
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
                                      ProphetStoryDetailScreen(
                                    story: widget.story,
                                    initialChapterId: chapter.id,
                                  ),
                                ),
                              ).then((_) => _loadFavorites());
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isDark
                                        ? const Color(0xFF1D3C34)
                                        : const Color(0xFFE8F3EF),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark ? accentColor : primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chapter.title,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? accentColor
                                                      : primaryColor,
                                                  fontFamily: 'Amiri',
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            if (_favoriteChapterIds.contains(chapter.id))
                                              const Padding(
                                                padding: EdgeInsets.only(right: 8.0),
                                                child: Icon(Icons.favorite, color: Colors.red, size: 16),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          snippet,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                        ),
                                        if (chapter.verses.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.menu_book_rounded,
                                                size: 14,
                                                color: isDark
                                                    ? accentColor
                                                    : primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'الآيات المرتبطة: ${chapter.verses.length}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? accentColor
                                                      : primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_back_ios,
                                    size: 14,
                                    color: Colors.grey,
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

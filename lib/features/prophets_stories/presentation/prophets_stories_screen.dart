import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/prophets_stories_service.dart';
import 'prophet_story_chapters_screen.dart';
import 'prophet_story_detail_screen.dart';

class ProphetsStoriesScreen extends StatefulWidget {
  const ProphetsStoriesScreen({super.key});

  @override
  State<ProphetsStoriesScreen> createState() => _ProphetsStoriesScreenState();
}

class _ProphetsStoriesScreenState extends State<ProphetsStoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProphetsStoriesService _service = ProphetsStoriesService();
  List<ProphetStory> _filteredStories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _service.loadStories();
    if (mounted) {
      setState(() {
        _filteredStories = _service.getAllStories();
        _isLoading = false;
      });
    }
  }

  void _applySearch(String val) {
    setState(() {
      _searchQuery = val.trim();
      _filteredStories = _service.searchStories(_searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
          foregroundColor: Colors.white,
          title: const Text(
            'موسوعة قصص الأنبياء',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: accentColor,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'الأنبياء عليهم السلام', icon: Icon(Icons.people_outline)),
              Tab(text: 'المفضلة', icon: Icon(Icons.favorite_border)),
            ],
          ),
        ),
        body: Container(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
          child: TabBarView(
            children: [
              // Tab 1: All Prophets Grid
              Column(
                children: [
                  // Resume Reading Button
                  if (appState.lastProphetStoryId > 0)
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
                            final story =
                                _service.getStoryById(appState.lastProphetStoryId);
                            if (story != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProphetStoryDetailScreen(
                                    story: story,
                                    initialChapterId: appState.lastProphetChapterId,
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            }
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'متابعة القراءة من حيث توقفت',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      FutureBuilder(
                                        future: _service.loadStories().then((_) =>
                                            _service.getStoryById(
                                                appState.lastProphetStoryId)),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            final story =
                                                snapshot.data as ProphetStory;
                                            final chap = story.chapters.firstWhere(
                                                (c) =>
                                                    c.id ==
                                                    appState.lastProphetChapterId,
                                                orElse: () => story.chapters.first);
                                            return Text(
                                              'قصة ${story.name} - ${chap.title}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.grey[300]
                                                      : Colors.grey[600]),
                                            );
                                          }
                                          return const SizedBox();
                                        },
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
                          hintText: 'ابحث عن نبي أو قصة...',
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

                  // Prophets Grid
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: primaryColor))
                        : _filteredStories.isEmpty
                            ? const Center(
                                child: Text(
                                  'لا توجد نتائج بحث مطابقة',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _filteredStories.length,
                                itemBuilder: (context, index) {
                                  final story = _filteredStories[index];

                                  return Card(
                                    elevation: 3,
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
                                                ProphetStoryChaptersScreen(
                                                    story: story),
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
                                                Icons.person_outline_rounded,
                                                size: 30,
                                                color: isDark
                                                    ? accentColor
                                                    : primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              story.name,
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
                                                story.summary,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                  height: 1.3,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
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

              // Tab 2: Favorites View
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _service.getFavoriteChapters(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: primaryColor));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد فصول مفضلة حالياً',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final favs = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favs.length,
                    itemBuilder: (context, index) {
                      final item = favs[index];
                      final story = item['story'] as ProphetStory;
                      final chapter = item['chapter'] as ProphetChapter;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProphetStoryDetailScreen(
                                  story: story,
                                  initialChapterId: chapter.id,
                                ),
                              ),
                            ).then((_) => setState(() {}));
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
                                  child: Icon(Icons.favorite,
                                      size: 20,
                                      color: isDark ? accentColor : primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chapter.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? accentColor : primaryColor,
                                          fontFamily: 'Amiri',
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'من قصة: ${story.name}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_back_ios,
                                    size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

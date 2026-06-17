import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/religious_stories_service.dart';
import 'religious_stories_category_screen.dart';
import 'religious_story_detail_screen.dart';

class ReligiousStoriesListScreen extends StatefulWidget {
  const ReligiousStoriesListScreen({super.key});

  @override
  State<ReligiousStoriesListScreen> createState() =>
      _ReligiousStoriesListScreenState();
}

class _ReligiousStoriesListScreenState
    extends State<ReligiousStoriesListScreen> {
  final ReligiousStoriesService _service = ReligiousStoriesService();
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'الصبر والابتلاء',
      'icon': Icons.self_improvement,
      'desc': 'قصص ملهمة عن الصبر والرضا بقضاء الله وقدره',
      'color': Colors.blue,
    },
    {
      'name': 'الأمانة',
      'icon': Icons.shield_outlined,
      'desc': 'دروس في الصدق وحفظ العهود وأداء الأمانات',
      'color': Colors.teal,
    },
    {
      'name': 'الإخلاص',
      'icon': Icons.favorite_border_rounded,
      'desc': 'عن الأعمال الصالحة المخلصة الخالية من الرياء',
      'color': Colors.red,
    },
    {
      'name': 'الأخلاق والتواضع',
      'icon': Icons.handshake_outlined,
      'desc': 'تواضع الكبار ورفعة أخلاق السلف الصالح',
      'color': Colors.indigo,
    },
    {
      'name': 'التوبة والعفو',
      'icon': Icons.refresh_rounded,
      'desc': 'قصص عن المغفرة وفسحة التوبة ورحمة الله الواسعة',
      'color': Colors.orange,
    },
    {
      'name': 'الجود والكرم',
      'icon': Icons.volunteer_activism_outlined,
      'desc': 'الإيثار وتقديم حاجة المحتاج على النفس',
      'color': Colors.green,
    },
    {
      'name': 'الحياة وكيف تعيش',
      'icon': Icons.spa_outlined,
      'desc': 'وصايا تربوية وحكم عملية لبناء شخصية المسلم',
      'color': Colors.purple,
    },
    {
      'name': 'الزواج والأسرة',
      'icon': Icons.family_restroom_rounded,
      'desc': 'تأسيس البيوت الصالحة على طاعة الله ورسوله',
      'color': Colors.pink,
    },
    {
      'name': 'التوكل على الله',
      'icon': Icons.cloud_queue_rounded,
      'desc': 'اليقين بالله والتوكل الصادق مع بذل الأسباب',
      'color': Colors.cyan,
    },
    {
      'name': 'حب الوالدين',
      'icon': Icons.people_outline_rounded,
      'desc': 'عظم بر الوالدين وأثره المبارك في استجابة الدعاء',
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.loadStories();
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'قصص وعبر إسلامية هادفة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor))
            : Column(
                children: [
                  // Resume Reading Card
                  if (appState.lastReadReligiousStoryId > 0)
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
                            final story = _service.getStoryById(
                                appState.lastReadReligiousStoryId);
                            if (story != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReligiousStoryDetailScreen(story: story),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'متابعة القراءة من حيث توقفت',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                        textAlign: TextAlign.right,
                                      ),
                                      const SizedBox(height: 2),
                                      FutureBuilder(
                                        future: _service.loadStories().then(
                                            (_) => _service.getStoryById(
                                                appState
                                                    .lastReadReligiousStoryId)),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            final story =
                                                snapshot.data as ReligiousStory;
                                            return Text(
                                              'آخر قصة: ${story.title}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.grey[300]
                                                      : Colors.grey[600]),
                                              textAlign: TextAlign.right,
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
                        final String categoryName = cat['name'] as String;
                        final IconData icon = cat['icon'] as IconData;
                        final String desc = cat['desc'] as String;
                        final Color color = cat['color'] as Color;

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
                                      ReligiousStoriesCategoryScreen(
                                    categoryName: categoryName,
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
                                        ? color.withOpacity(0.12)
                                        : color.withOpacity(0.08),
                                    child: Icon(
                                      icon,
                                      size: 30,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    categoryName,
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

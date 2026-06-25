import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/seerah_service.dart';
import 'seerah_stage_events_screen.dart';
import 'seerah_detail_screen.dart';

class SeerahScreen extends StatefulWidget {
  const SeerahScreen({super.key});

  @override
  State<SeerahScreen> createState() => _SeerahScreenState();
}

class _SeerahScreenState extends State<SeerahScreen> {
  final SeerahService _service = SeerahService();
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SeerahEvent> _searchResults = [];

  final List<Map<String, dynamic>> _stages = [
    {
      'name': 'مرحلة مكة',
      'icon': Icons.explore_outlined,
      'desc': 'من النسب والمولد المبارك، طفولته ونشأته، وحتى الهجرة للحبشة وشعب أبي طالب والطائف',
    },
    {
      'name': 'مرحلة الهجرة',
      'icon': Icons.trending_flat_rounded,
      'desc': 'بيعة العقبة، وتآمر دار الندوة، ونوم علي بالفراش، وغار ثور، وحتى دخول المدينة وبناء المسجد والمؤاخاة',
    },
    {
      'name': 'مرحلة المدينة',
      'icon': Icons.mosque_rounded,
      'desc': 'المجتمع المدني وتأسيس الدولة وتشريع الأذان والصوم وزكاة الفطر وتحويل القبلة ونقض بني قينقاع',
    },
    {
      'name': 'الغزوات',
      'icon': Icons.shield_outlined,
      'desc': 'المعارك الكبرى الفاصلة من بدر، أحد، حمراء الأسد، بني النضير، الخندق، بني قريظة، خيبر ومؤتة وتبوك',
    },
    {
      'name': 'فتح مكة وحجة الوداع',
      'icon': Icons.verified_outlined,
      'desc': 'دخول مكة والوفود وإكمال الدين وتمام النعمة وخطبة الوداع التاريخية',
    },
    {
      'name': 'الوفاة',
      'icon': Icons.hourglass_empty_rounded,
      'desc': 'مرض النبي ﷺ، إمامة أبي الصديق للصلاة، اللحظات الأخيرة والوفاة ووداع سيد الخلق',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.loadEvents();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _searchResults = _service.searchEvents(query);
    });
  }

  Widget _buildAppBarTitle(Color primaryColor) {
    if (_isSearching) {
      return TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'ابحث في السيرة النبوية والقصص...',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
        onChanged: _onSearchChanged,
      );
    }
    return const Text(
      'السيرة النبوية المطهرة',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
        fontSize: 16,
      ),
    );
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
          title: _buildAppBarTitle(primaryColor),
          centerTitle: !_isSearching,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
          ],
          bottom: _isSearching || _isLoading
              ? null
              : const TabBar(
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(
                      text: 'أقسام السيرة',
                      icon: Icon(Icons.menu_book_rounded, size: 20),
                    ),
                    Tab(
                      text: 'المفضلة',
                      icon: Icon(Icons.favorite_rounded, size: 20),
                    ),
                  ],
                ),
        ),
        body: Container(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor))
              : _searchQuery.isNotEmpty
                  ? _buildSearchResults(isDark, primaryColor, accentColor)
                  : TabBarView(
                      children: [
                        // Tab 1: Stages & Resume Card
                        _buildStagesTab(appState, isDark, primaryColor, accentColor),
                        
                        // Tab 2: Favorites List
                        _buildFavoritesTab(isDark, primaryColor, accentColor),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildStagesTab(AppState appState, bool isDark, Color primaryColor, Color accentColor) {
    return Column(
      children: [
        // Resume Reading Card
        if (appState.lastSeerahEventId > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              color: isDark ? const Color(0xFF1B3D34) : const Color(0xFFE8F3EF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  final event = _service.getEventById(appState.lastSeerahEventId);
                  if (event != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeerahDetailScreen(event: event),
                      ),
                    ).then((_) => setState(() {}));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_filled, color: accentColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'متابعة القراءة من حيث توقفت',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            FutureBuilder(
                              future: _service.loadEvents().then(
                                  (_) => _service.getEventById(appState.lastSeerahEventId)),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  final event = snapshot.data as SeerahEvent;
                                  return Text(
                                    'قسم: ${event.stage} - ${event.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                                    ),
                                    textDirection: TextDirection.rtl,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Stages Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: _stages.length,
            itemBuilder: (context, index) {
              final stage = _stages[index];
              final String name = stage['name'] as String;
              final IconData icon = stage['icon'] as IconData;
              final String desc = stage['desc'] as String;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeerahStageEventsScreen(stage: name),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isDark ? const Color(0xFF1D3C34) : const Color(0xFFE8F3EF),
                          child: Icon(
                            icon,
                            size: 26,
                            color: isDark ? accentColor : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
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
    );
  }

  Widget _buildFavoritesTab(bool isDark, Color primaryColor, Color accentColor) {
    return FutureBuilder<List<SeerahEvent>>(
      future: _service.getFavoriteEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد أحداث في المفضلة بعد',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'انقر على أيقونة القلب في تفاصيل الحدث لحفظه هنا وقراءته لاحقاً',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final favs = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favs.length,
          itemBuilder: (context, index) {
            final event = favs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.15),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textDirection: TextDirection.rtl,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    event.stage,
                    style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                trailing: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeerahDetailScreen(event: event),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(bool isDark, Color primaryColor, Color accentColor) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'لم نجد أي نتائج لـ "$_searchQuery"',
              style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final event = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textDirection: TextDirection.rtl,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                const SizedBox(height: 4),
                Text(
                  event.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      event.stage,
                      style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold),
                    ),
                    if (event.location.isNotEmpty)
                      Text(
                        event.location,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeerahDetailScreen(event: event),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        );
      },
    );
  }
}

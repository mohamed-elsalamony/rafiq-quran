import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/hadith_service.dart';

class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({super.key});

  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<Hadith> _allHadiths = [];
  List<Hadith> _filteredHadiths = [];
  List<int> _favoriteIds = [];
  
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadHadithData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHadithData() async {
    final service = HadithService();
    await service.loadHadiths();
    final favIds = await service.getFavoriteHadithIds();
    
    if (mounted) {
      setState(() {
        _allHadiths = service.getAllHadiths();
        _favoriteIds = favIds;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    final service = HadithService();
    List<Hadith> baseList = [];

    // Filter by tab category
    switch (_tabController.index) {
      case 0: // الكل
        baseList = _allHadiths;
        break;
      case 1: // الأربعون النووية
        baseList = service.getHadithsByCategory('Nawawi');
        break;
      case 2: // صحيح البخاري
        baseList = service.getHadithsByCategory('Bukhari');
        break;
      case 3: // صحيح مسلم
        baseList = service.getHadithsByCategory('Muslim');
        break;
      case 4: // رياض الصالحين
        baseList = service.getHadithsByCategory('Riyad');
        break;
      case 5: // المفضلة
        baseList = _allHadiths.where((h) => _favoriteIds.contains(h.id)).toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      baseList = baseList.where((h) =>
          h.text.contains(_searchQuery) ||
          h.explanation.contains(_searchQuery) ||
          h.source.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    _filteredHadiths = baseList;
  }

  Future<void> _toggleFavorite(int hadithId) async {
    final service = HadithService();
    await service.toggleFavorite(hadithId);
    final favIds = await service.getFavoriteHadithIds();
    setState(() {
      _favoriteIds = favIds;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0F5A47);
    final Color goldColor = const Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'مكتبة الأحاديث الشريفة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: goldColor,
          unselectedLabelColor: Colors.white70,
          indicatorColor: goldColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'الأربعون النووية'),
            Tab(text: 'صحيح البخاري'),
            Tab(text: 'صحيح مسلم'),
            Tab(text: 'رياض الصالحين'),
            Tab(text: 'المفضلة ❤️'),
          ],
        ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن حديث أو كلمة بالمتن...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _applyFilters();
                    });
                  },
                ),
              ),
            ),

            // Hadith List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredHadiths.isEmpty
                      ? Center(
                          child: Text(
                            _tabController.index == 5
                                ? 'قائمة المفضلة فارغة حالياً.'
                                : 'لا توجد نتائج مطابقة لبحثك.',
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredHadiths.length,
                          itemBuilder: (context, index) {
                            final hadith = _filteredHadiths[index];
                            final isFav = _favoriteIds.contains(hadith.id);
                            return _buildHadithCard(hadith, isFav, isDark, primaryColor, goldColor);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHadithCard(
    Hadith hadith,
    bool isFav,
    bool isDark,
    Color primaryColor,
    Color goldColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text Content
            Text(
              hadith.text,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? goldColor : primaryColor,
                height: 1.6,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            
            // Source label
            Text(
              'رواه: ${hadith.source}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.left,
            ),
            const Divider(height: 20),

            // Expandable explanation
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                dense: true,
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'الشرح والفوائد التربوية',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                  textAlign: TextAlign.right,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      hadith.explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 12),

            // Row actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '${hadith.text} [رواه ${hadith.source}]'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الحديث إلى الحافظة!')),
                        );
                      },
                      tooltip: 'نسخ الحديث',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20, color: Colors.grey),
                      onPressed: () {
                        Share.share('${hadith.text} \n\n[رواه ${hadith.source}]');
                      },
                      tooltip: 'مشاركة الحديث',
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                    size: 24,
                  ),
                  onPressed: () => _toggleFavorite(hadith.id),
                  tooltip: 'إضافة للمفضلة',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

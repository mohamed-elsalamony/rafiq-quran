import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/companions_service.dart';
import 'companions_category_screen.dart';
import 'companion_detail_screen.dart';

class CompanionsListScreen extends StatefulWidget {
  const CompanionsListScreen({super.key});

  @override
  State<CompanionsListScreen> createState() => _CompanionsListScreenState();
}

class _CompanionsListScreenState extends State<CompanionsListScreen> {
  final CompanionsService _service = CompanionsService();
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'العشرة المبشرون بالجنة',
      'icon': Icons.star_rounded,
      'desc': 'الذين بشرهم النبي ﷺ بالجنة في مجلس واحد',
    },
    {
      'name': 'أهل بدر',
      'icon': Icons.shield_outlined,
      'desc': 'شهدوا غزوة بدر الكبرى ولهم فضل عظيم',
    },
    {
      'name': 'أهل الصفة',
      'icon': Icons.home_rounded,
      'desc': 'فقراء المهاجرين الذين سكنوا مسجد النبي ﷺ',
    },
    {
      'name': 'السابقون الأولون',
      'icon': Icons.history_toggle_off_rounded,
      'desc': 'أول من دخلوا في الإسلام وعضدوا الدعوة بمكة',
    },
    {
      'name': 'باقي الصحابة الكرام',
      'icon': Icons.group_rounded,
      'desc': 'رواة الحديث والمجاهدون الأجلاء مرتبين أبجدياً',
    },
    {
      'name': 'الصحابيات الجليلات',
      'icon': Icons.favorite_border_rounded,
      'desc': 'نساء مؤمنات نصرن الإسلام وبذلن الغالي والنفيس',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.loadCompanions();
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
          'الصحابة الكرام رضي الله عنهم',
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
                  if (appState.lastCompanionId > 0)
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
                            final companion = _service
                                .getCompanionById(appState.lastCompanionId);
                            if (companion != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CompanionDetailScreen(
                                      companion: companion),
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
                                      ),
                                      const SizedBox(height: 2),
                                      FutureBuilder(
                                        future: _service.loadCompanions().then(
                                            (_) => _service.getCompanionById(
                                                appState.lastCompanionId)),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            final companion =
                                                snapshot.data as Companion;
                                            return Text(
                                              'سيرة الصحابي: ${companion.name}',
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
                                      CompanionsCategoryScreen(
                                    categoryName: categoryName ==
                                            'باقي الصحابة الكرام'
                                        ? 'باقي الصحابة'
                                        : (categoryName == 'الصحابيات الجليلات'
                                            ? 'الصحابيات'
                                            : categoryName),
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

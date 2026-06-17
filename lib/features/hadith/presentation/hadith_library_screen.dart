import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import 'hadith_category_screen.dart';

class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({super.key});

  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _MicroHadithCategory {
  final String key;
  final String name;
  final IconData icon;
  final String desc;

  _MicroHadithCategory({
    required this.key,
    required this.name,
    required this.icon,
    required this.desc,
  });
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> {
  final List<_MicroHadithCategory> _categories = [
    _MicroHadithCategory(
      key: 'all',
      name: 'جميع الأحاديث',
      icon: Icons.auto_stories_outlined,
      desc: 'قراءة وتصفح جميع الأحاديث الشريفة المتوفرة بالمكتبة',
    ),
    _MicroHadithCategory(
      key: 'Nawawi',
      name: 'الأربعون النووية',
      icon: Icons.bookmark_added_outlined,
      desc: 'أربعون حديثاً جمعها الإمام النووي تشتمل على جوامع الكلم',
    ),
    _MicroHadithCategory(
      key: 'Bukhari',
      name: 'صحيح البخاري',
      icon: Icons.verified_user_outlined,
      desc: 'أصح الكتب المصنفة في الحديث الشريف للإمام البخاري',
    ),
    _MicroHadithCategory(
      key: 'Muslim',
      name: 'صحيح مسلم',
      icon: Icons.verified_outlined,
      desc: 'الكتاب الموثق الصحيح المروي عن الإمام مسلم بن الحجاج',
    ),
    _MicroHadithCategory(
      key: 'Riyad',
      name: 'رياض الصالحين',
      icon: Icons.park_outlined,
      desc: 'كتاب شامل لأحاديث الترغيب والترهيب والآداب للإمام النووي',
    ),
    _MicroHadithCategory(
      key: 'favorite',
      name: 'الأحاديث المفضلة',
      icon: Icons.favorite_border_rounded,
      desc: 'الأحاديث الشريفة التي قمت بحفظها للرجوع إليها لاحقاً',
    ),
  ];

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
          'مكتبة الأحاديث الشريفة',
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
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HadithCategoryScreen(
                        categoryKey: cat.key,
                        categoryName: cat.name,
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
                          cat.icon,
                          size: 30,
                          color: isDark ? accentColor : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          cat.desc,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
    );
  }
}

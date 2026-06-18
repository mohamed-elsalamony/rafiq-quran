import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_state.dart';
import 'quran_provider.dart';

class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({super.key});

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Static Juz data with starting pages, surahs, and names
  final List<Map<String, dynamic>> _juzList = List.generate(30, (index) {
    final juzNum = index + 1;
    // Approximated Quran Juz starting pages
    final List<int> juzStartPages = [
      1,
      22,
      42,
      62,
      82,
      102,
      121,
      142,
      162,
      182,
      201,
      221,
      242,
      262,
      282,
      302,
      322,
      342,
      362,
      382,
      402,
      422,
      442,
      462,
      482,
      502,
      522,
      542,
      562,
      582
    ];
    final page = juzStartPages[index];
    return {
      'number': juzNum,
      'name': 'الجزء $juzNum',
      'page': page,
      'surahName':
          quran.getSurahNameArabic(quran.getPageData(page).first['surah']),
    };
  });

  // Static Hizb data with starting pages (each Juz contains 2 Hizbs)
  final List<Map<String, dynamic>> _hizbList = List.generate(60, (index) {
    final hizbNum = index + 1;
    // Estimated Hizb starting pages
    final List<int> hizbStartPages = [
      1,
      11,
      22,
      32,
      42,
      52,
      62,
      72,
      82,
      92,
      102,
      111,
      121,
      131,
      142,
      151,
      162,
      172,
      182,
      192,
      201,
      211,
      221,
      231,
      242,
      252,
      262,
      272,
      282,
      292,
      302,
      312,
      322,
      332,
      342,
      352,
      362,
      372,
      382,
      392,
      402,
      412,
      422,
      432,
      442,
      452,
      462,
      472,
      482,
      492,
      502,
      512,
      522,
      532,
      542,
      552,
      562,
      572,
      582,
      592
    ];
    final page = hizbStartPages[index];
    return {
      'number': hizbNum,
      'name': 'الحزب $hizbNum',
      'page': page,
      'surahName':
          quran.getSurahNameArabic(quran.getPageData(page).first['surah']),
    };
  });

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final quranProvider = Provider.of<QuranProvider>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color goldColor = Color(0xFFD4AF37);

    // List of Surahs filtered by search
    final List<int> filteredSurahs = [];
    for (int i = 1; i <= 114; i++) {
      final arabicName = quran.getSurahNameArabic(i);
      final englishName = quran.getSurahName(i);
      if (arabicName.contains(_searchQuery) ||
          englishName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.toString() == _searchQuery) {
        filteredSurahs.add(i);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'فهرس القرآن الكريم',
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
          tabs: const [
            Tab(text: 'السور'),
            Tab(text: 'الأجزاء والأحزاب'),
          ],
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: Column(
          children: [
            // Search Bar (Only shown for Surah tab or as global)
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
                  decoration: const InputDecoration(
                    hintText: 'البحث باسم السورة أو رقمها...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
            ),

            // Tab contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Tab Surahs
                  filteredSurahs.isEmpty
                      ? const Center(child: Text('لا توجد نتائج مطابقة.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: filteredSurahs.length,
                          itemBuilder: (context, index) {
                            final sNum = filteredSurahs[index];
                            final isMeccan =
                                quran.getPlaceOfRevelation(sNum) == 'Makkah';
                            final totalAyahs = quran.getVerseCount(sNum);
                            final startPage = quran.getPageNumber(sNum, 1);

                            // Check if this Surah contains the last read position
                            final isLastRead = appState.lastSurahRead == sNum;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              borderOnForeground: true,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.teal.withOpacity(0.1)
                                        : primaryColor.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isLastRead
                                          ? goldColor
                                          : primaryColor.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$sNum',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLastRead
                                            ? goldColor
                                            : primaryColor,
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isLastRead)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: goldColor.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'آخر قراءة',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: goldColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    Text(
                                      quran.getSurahNameArabic(sNum),
                                      style: GoogleFonts.amiri(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'صفحة $startPage',
                                      style: TextStyle(
                                          color: goldColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$totalAyahs آية',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isMeccan ? 'مكية 🕋' : 'مدنية 🕌',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_back_ios,
                                  size: 14,
                                  color: isLastRead ? goldColor : Colors.grey,
                                ),
                                onTap: () {
                                  if (quranProvider.isPlaying) {
                                    quranProvider.pauseRecitation();
                                  }
                                  quranProvider.goToPage(startPage);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),

                  // 2. Tab Juz and Hizb
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Header Juz
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'فهرس الأجزاء (30 جزءاً)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _juzList.length,
                        itemBuilder: (context, index) {
                          final juz = _juzList[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                if (quranProvider.isPlaying) {
                                  quranProvider.pauseRecitation();
                                }
                                quranProvider.goToPage(juz['page']);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      juz['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ص ${juz['page']}',
                                          style: TextStyle(
                                              color: goldColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'سورة ${juz['surahName']}',
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Header Hizb
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'فهرس الأحزاب (60 حزباً)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _hizbList.length,
                        itemBuilder: (context, index) {
                          final hizb = _hizbList[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                if (quranProvider.isPlaying) {
                                  quranProvider.pauseRecitation();
                                }
                                quranProvider.goToPage(hizb['page']);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hizb['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ص ${hizb['page']}',
                                          style: TextStyle(
                                              color: goldColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'سورة ${hizb['surahName']}',
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

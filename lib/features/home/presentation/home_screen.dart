import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/hadith_service.dart';
import '../../../core/services/prophet_blessing_service.dart';
import '../../quran/presentation/quran_screen.dart';
import '../../hifz_khatma/presentation/hifz_khatma_screen.dart';
import '../../hadith/presentation/hadith_library_screen.dart';
import '../../prayer_times/presentation/qibla_compass_screen.dart';
import '../../prayer_times/presentation/prayer_provider.dart';
import 'prophet_blessing_screen.dart';
import 'package:adhan/adhan.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChanged;
  const HomeScreen({super.key, required this.onTabChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _timeUntilNextPrayer = '--:--:--';
  String _nextPrayerName = '';
  Timer? _prayerTimer;
  Map<String, dynamic>? _lastBookmark;
  List<Map<String, dynamic>> _khatmaPlans = [];
  Hadith? _hadithOfDay;

  @override
  void initState() {
    super.initState();
    _startPrayerTimer();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    super.dispose();
  }

  void _loadDashboardData() async {
    final bookmarks = await DbHelper.getBookmarks();
    final khatmas = await DbHelper.getKhatmaPlans();

    final hadithService = HadithService();
    final hadith = await hadithService.getHadithOfDay();

    if (mounted) {
      setState(() {
        if (bookmarks.isNotEmpty) {
          _lastBookmark = bookmarks.last;
        } else {
          _lastBookmark = null;
        }
        _khatmaPlans = khatmas;
        _hadithOfDay = hadith;
      });
    }
  }

  void _startPrayerTimer() {
    _updatePrayerTime();
    _prayerTimer?.cancel();
    _prayerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updatePrayerTime();
    });
  }

  void _updatePrayerTime() {
    if (!mounted) return;
    try {
      final prayerProvider =
          Provider.of<PrayerProvider>(context, listen: false);
      final times = prayerProvider.prayerTimes;
      final now = DateTime.now();

      var next = times.nextPrayer();
      if (next == Prayer.none) {
        next = Prayer.fajr;
      }

      DateTime? nextTime = times.timeForPrayer(next);
      if (nextTime == null || nextTime.isBefore(now)) {
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowCoords = Coordinates(prayerProvider.currentCity.latitude,
            prayerProvider.currentCity.longitude);
        final tomorrowTimes = PrayerService.getPrayerTimes(
            tomorrowCoords, prayerProvider.currentCity.method,
            date: tomorrow);
        nextTime = tomorrowTimes.timeForPrayer(next);
      }

      if (nextTime != null) {
        final diff = nextTime.difference(now);
        final hours = diff.inHours;
        final mins = diff.inMinutes % 60;
        final secs = diff.inSeconds % 60;

        String prayerStr = '';
        switch (next) {
          case Prayer.fajr:
            prayerStr = 'الفجر';
            break;
          case Prayer.dhuhr:
            prayerStr = 'الظهر';
            break;
          case Prayer.asr:
            prayerStr = 'العصر';
            break;
          case Prayer.maghrib:
            prayerStr = 'المغرب';
            break;
          case Prayer.isha:
            prayerStr = 'العشاء';
            break;
          default:
            prayerStr = 'الفجر';
            break;
        }

        setState(() {
          _nextPrayerName = prayerStr;
          _timeUntilNextPrayer =
              '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        });
      }
    } catch (e) {
      debugPrint("Error updating home prayer countdown: $e");
    }
  }

  String _formatAudioPosition(int ms) {
    if (ms <= 0) return '00:00';
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final prayerProvider = Provider.of<PrayerProvider>(context);
    const Color primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);
    final isDark = appState.isDarkMode;

    const String ayahOfDayText =
        "إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ";
    const String ayahOfDayReference = "سورة الإسراء - الآية 9";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F2520), const Color(0xFF0B1412)]
                : [const Color(0xFFF0F5F2), const Color(0xFFFAFBF9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // 2. Next Prayer Card with Live Ticking Countdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162A25) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF23443B) : const Color(0xFFE2ECE9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF23443B) : const Color(0xFFE2ECE9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mosque_outlined,
                          size: 32,
                          color: isDark ? accentColor : primaryColor,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDark ? accentColor : primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'الصلاة القادمة: $_nextPrayerName',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _timeUntilNextPrayer,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : primaryColor,
                                  fontFamily: 'Outfit',
                                  letterSpacing: 1,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'التوقيت لمدينة: ${prayerProvider.currentCity.nameArabic}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Grid of Features (9 items, 3x3 layout)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                  children: [
                    _buildGridItem(context, 'المصحف', Icons.menu_book_outlined,
                        () => widget.onTabChanged(0), isDark),
                    _buildGridItem(context, 'المواقيت', Icons.mosque_outlined,
                        () => widget.onTabChanged(4), isDark),
                    _buildGridItem(context, 'الأذكار', Icons.wb_sunny_outlined,
                        () => widget.onTabChanged(1), isDark),
                    _buildGridItem(context, 'السبحة', Icons.touch_app_outlined,
                        () => widget.onTabChanged(3), isDark),
                    _buildGridItem(
                        context,
                        'القبلة',
                        Icons.explore_outlined,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const QiblaCompassScreen())),
                        isDark),
                    _buildGridItem(
                        context,
                        'الحفظ والورد',
                        Icons.bookmark_added_outlined,
                        () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const HifzKhatmaScreen()))
                            .then((_) => _loadDashboardData()),
                        isDark),
                    _buildGridItem(
                        context,
                        'الأحاديث',
                        Icons.auto_stories_outlined,
                        () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const HadithLibraryScreen()))
                            .then((_) => _loadDashboardData()),
                        isDark),
                    _buildGridItem(
                        context,
                        'صلوات النبي',
                        'ﷺ',
                        () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProphetBlessingScreen()))
                            .then((_) => _loadDashboardData()),
                        isDark),
                    _buildGridItem(
                        context,
                        'الإعدادات',
                        Icons.settings_outlined,
                        () => Navigator.pushNamed(context, '/settings'),
                        isDark),
                  ],
                ),
                const SizedBox(height: 24),

                // 9. Ayah of the Day
                _buildSectionCard(
                  title: 'آية اليوم',
                  isDark: isDark,
                  accentColor: accentColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '﴿ $ayahOfDayText ﴾',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? accentColor : primaryColor,
                          fontFamily: 'Amiri',
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            ayahOfDayReference,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.bookmark_outline,
                              color: accentColor.withOpacity(0.6), size: 16),
                        ],
                      ),
                    ],
                  ),
                  color: isDark
                      ? const Color(0xFF152A24)
                      : const Color(0xFFEDF6F2),
                ),
                const SizedBox(height: 24),

                // 4. Hadith of the Day (Moved to Middle)
                if (_hadithOfDay != null)
                  _buildSectionCard(
                    title: 'حديث اليوم',
                    isDark: isDark,
                    accentColor: accentColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          _hadithOfDay!.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[200] : Colors.black87,
                            height: 1.6,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'رواه: ${_hadithOfDay!.source}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HadithLibraryScreen()),
                            ).then((_) => _loadDashboardData());
                          },
                          icon: const Icon(Icons.library_books,
                              size: 16, color: Colors.teal),
                          label: const Text('تصفح مكتبة الأحاديث الشريفة',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal)),
                          style: OutlinedButton.styleFrom(
                            side:
                                BorderSide(color: accentColor.withOpacity(0.5)),
                          ),
                        ),
                      ],
                    ),
                    color: isDark
                        ? const Color(0xFF15222E)
                        : const Color(0xFFEDF5FA),
                  ),
                const SizedBox(height: 24),

                // 5. Prophet Blessing Counter Campaign Card
                Consumer<ProphetBlessingService>(
                  builder: (context, blessingService, child) {
                    return _buildSectionCard(
                      title: 'مليونية الصلاة على النبي ﷺ',
                      isDark: isDark,
                      accentColor: accentColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'صلواتك اليوم: ${blessingService.personalCount}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'العداد العالمي: ${blessingService.globalCount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.favorite,
                                    color: accentColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ProphetBlessingScreen()),
                                  ).then((_) => _loadDashboardData());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                ),
                                child: const Text('شارك الآن',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      color: isDark
                          ? const Color(0xFF162520)
                          : const Color(0xFFEAF5F0),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 6. Continue Reading / Listening Card
                _buildSectionCard(
                  title: 'متابعة من حيث توقفت',
                  isDark: isDark,
                  accentColor: accentColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.grey.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuranScreen(
                                  initialPage: appState.lastPageRead,
                                  initialSurah: appState.lastSurahRead,
                                ),
                              ),
                            ).then((_) => _loadDashboardData());
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'آخر ما قرأت في المصحف',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                        textAlign: TextAlign.right,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'سورة ${quran.getSurahNameArabic(appState.lastSurahRead)} - الصفحة ${appState.lastPageRead}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.chrome_reader_mode_outlined,
                                      color: accentColor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuranScreen(
                                          initialPage: appState.lastPageRead,
                                          initialSurah: appState.lastSurahRead,
                                        ),
                                      ),
                                    ).then((_) => _loadDashboardData());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text('اقرأ الآن',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.grey.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuranScreen(
                                  initialPage: quran.getPageNumber(
                                      appState.lastAudioSurah,
                                      appState.lastAudioAyah),
                                  initialSurah: appState.lastAudioSurah,
                                  autoPlay: true,
                                ),
                              ),
                            ).then((_) => _loadDashboardData());
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'آخر تلاوة استمعت إليها',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                        textAlign: TextAlign.right,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'سورة ${quran.getSurahNameArabic(appState.lastAudioSurah)} (${appState.lastAudioReciter}) عند ${_formatAudioPosition(appState.lastAudioPositionMs)}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.play_circle_outline,
                                      color: accentColor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuranScreen(
                                          initialPage: quran.getPageNumber(
                                              appState.lastAudioSurah,
                                              appState.lastAudioAyah),
                                          initialSurah: appState.lastAudioSurah,
                                          autoPlay: true,
                                        ),
                                      ),
                                    ).then((_) => _loadDashboardData());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                  child: const Text('استمع',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                const SizedBox(height: 24),

                // 7. Khatma Plan
                if (_khatmaPlans.isNotEmpty)
                  _buildSectionCard(
                    title: 'خطة الختمة الحالية',
                    isDark: isDark,
                    accentColor: accentColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _khatmaPlans.map((khatma) {
                        final total =
                            khatma['endPage'] - khatma['startPage'] + 1;
                        final current =
                            khatma['currentPage'] - khatma['startPage'] + 1;
                        final percent =
                            total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(percent * 100).toInt()}%',
                                  style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  khatma['title'] ?? 'ختمة القرآن الكبرى',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accentColor),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'الصفحة الحالية: ${khatma['currentPage']} من ${khatma['endPage']}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  )
                else
                  _buildSectionCard(
                    title: 'خطة الختمة',
                    isDark: isDark,
                    accentColor: accentColor,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'لم تقم بإنشاء خطة ختمة قرآني بعد. أنشئ خطتك المخصصة لتتبع وردك اليومي ونسبة الإنجاز.',
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                              height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HifzKhatmaScreen()),
                            ).then((_) => _loadDashboardData());
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('إنشاء خطة ختمة جديدة',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: accentColor.withOpacity(0.5),
                                  width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                const SizedBox(height: 24),

                // 8. Bookmarks Card
                if (_lastBookmark != null)
                  _buildSectionCard(
                    title: 'آخر العلامات المرجعية',
                    isDark: isDark,
                    accentColor: accentColor,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.02)
                            : Colors.grey.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark,
                              color: accentColor, size: 24),
                        ),
                        title: Text(
                          'سورة ${_lastBookmark!['surahName']} - الآية ${_lastBookmark!['ayah']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          textAlign: TextAlign.right,
                        ),
                        subtitle: Text(
                          'صفحة ${_lastBookmark!['page']} - ${_lastBookmark!['label']}',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600]),
                          textAlign: TextAlign.right,
                        ),
                        trailing: Icon(Icons.arrow_back_ios,
                            size: 14, color: accentColor),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuranScreen(
                                initialPage: _lastBookmark!['page'],
                                initialSurah: _lastBookmark!['surah'],
                              ),
                            ),
                          ).then((_) => _loadDashboardData());
                        },
                      ),
                    ),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ProphetBlessingScreen()),
          ).then((_) => _loadDashboardData());
        },
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Text(
          'ﷺ',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    dynamic icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    const primaryColor = Color(0xFF0F5A47);
    const accentColor = Color(0xFFD4AF37);

    Widget iconWidget;
    if (icon is IconData) {
      iconWidget = Icon(
        icon,
        size: 28,
        color: isDark ? accentColor : primaryColor,
      );
    } else {
      iconWidget = Text(
        icon.toString(),
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: isDark ? accentColor : primaryColor,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : primaryColor.withOpacity(0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: iconWidget,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: isDark ? Colors.amber[100] : primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required Color color,
    required bool isDark,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 16,
            thickness: 0.5,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          child,
        ],
      ),
    );
  }
}

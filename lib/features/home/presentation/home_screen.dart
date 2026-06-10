import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import '../../../core/services/prayer_service.dart';
import '../../quran/presentation/quran_screen.dart';
import 'package:adhan/adhan.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChanged;
  const HomeScreen({super.key, required this.onTabChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _timeUntilNextPrayer = '';
  String _nextPrayerName = '';
  Timer? _prayerTimer;
  Map<String, dynamic>? _lastBookmark;
  List<Map<String, dynamic>> _khatmaPlans = [];

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
    if (mounted) {
      setState(() {
        if (bookmarks.isNotEmpty) {
          _lastBookmark = bookmarks.last;
        }
        _khatmaPlans = khatmas;
      });
    }
  }

  void _startPrayerTimer() {
    _updatePrayerTime();
    _prayerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updatePrayerTime();
    });
  }

  void _updatePrayerTime() {
    // إحداثيات مكة الافتراضية
    final coords = Coordinates(21.4225, 39.8262);
    final todayTimes = PrayerService.getPrayerTimes(coords, CalculationMethod.umm_al_qura);
    final now = DateTime.now();
    
    // إيجاد الصلاة القادمة
    Prayer next = todayTimes.nextPrayer();
    if (next == Prayer.none) {
      next = Prayer.fajr;
    }
    
    DateTime nextTime = todayTimes.timeForPrayer(next) ?? now;
    if (nextTime.isBefore(now)) {
      // الصلاة القادمة غداً
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = PrayerService.getPrayerTimes(coords, CalculationMethod.umm_al_qura, date: tomorrow);
      nextTime = tomorrowTimes.timeForPrayer(next) ?? now;
    }

    final diff = nextTime.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;

    String prayerStr = '';
    switch (next) {
      case Prayer.fajr: prayerStr = 'الفجر'; break;
      case Prayer.dhuhr: prayerStr = 'الظهر'; break;
      case Prayer.asr: prayerStr = 'العصر'; break;
      case Prayer.maghrib: prayerStr = 'المغرب'; break;
      case Prayer.isha: prayerStr = 'العشاء'; break;
      default: prayerStr = 'الفجر'; break;
    }

    if (mounted) {
      setState(() {
        _nextPrayerName = prayerStr;
        _timeUntilNextPrayer = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);
    final isDark = appState.isDarkMode;

    // آية اليوم وذكر اليوم افتراضيين
    const String ayahOfDayText = "إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ";
    const String ayahOfDayReference = "سورة الإسراء - الآية 9";
    const String zekrOfDayText = "سبحان الله وبحمده، عدد خلقه ورضا نفسه وزنة عرشه ومداد كلماته.";

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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // رأس الصفحة والترحيب
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: accentColor, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'رفيق القرآن',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                                color: isDark ? Colors.white : primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مرحباً بك في رفيقك اليومي للعبادة والقرآن',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                        color: accentColor,
                        onPressed: () {
                          appState.toggleDarkMode(!isDark);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // بطاقة مواقيت الصلاة الحالية القادمة
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0C4638), const Color(0xFF072C23)]
                          : [primaryColor, const Color(0xFF0A3E31)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'الصلاة القادمة: $_nextPrayerName',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white90,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '- $_timeUntilNextPrayer',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                                fontFamily: 'Outfit',
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'مواقيت الصلاة حسب توقيت مكة المكرمة',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.mosque,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // أزرار سريعة: متابعة القراءة واستكمال الاستماع
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        title: 'متابعة القراءة',
                        subtitle: 'سورة ${quran.getSurahNameArabic(appState.lastSurahRead)} - ص ${appState.lastPageRead}',
                        icon: Icons.chrome_reader_mode_outlined,
                        color: isDark ? const Color(0xFF1E2825) : Colors.white,
                        textColor: isDark ? Colors.white : Colors.black87,
                        borderColor: isDark ? accentColor.withOpacity(0.2) : primaryColor.withOpacity(0.15),
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        title: 'استكمال الاستماع',
                        subtitle: 'سورة ${quran.getSurahNameArabic(appState.lastAudioSurah)} (${appState.lastAudioReciter})',
                        icon: Icons.play_circle_outline,
                        color: isDark ? const Color(0xFF1E2825) : Colors.white,
                        textColor: isDark ? Colors.white : Colors.black87,
                        borderColor: isDark ? accentColor.withOpacity(0.2) : primaryColor.withOpacity(0.15),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuranScreen(
                                initialPage: quran.getPageNumber(appState.lastAudioSurah, appState.lastAudioAyah),
                                initialSurah: appState.lastAudioSurah,
                                autoPlay: true,
                              ),
                            ),
                          ).then((_) => _loadDashboardData());
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // آية اليوم
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
                          Icon(Icons.bookmark_outline, color: accentColor.withOpacity(0.6), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            ayahOfDayReference,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),
                  color: isDark ? const Color(0xFF152A24) : const Color(0xFFEDF6F2),
                ),
                const SizedBox(height: 24),

                // ذكر اليوم
                _buildSectionCard(
                  title: 'ذكر اليوم',
                  isDark: isDark,
                  accentColor: accentColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        zekrOfDayText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[200] : Colors.black87,
                          height: 1.5,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  color: isDark ? const Color(0xFF23231A) : const Color(0xFFFDFBF2),
                ),
                const SizedBox(height: 24),

                // الورد اليومي والختمات
                if (_khatmaPlans.isNotEmpty)
                  _buildSectionCard(
                    title: 'خطة الختمة الحالية',
                    isDark: isDark,
                    accentColor: accentColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _khatmaPlans.map((khatma) {
                        final total = khatma['endPage'] - khatma['startPage'] + 1;
                        final current = khatma['currentPage'] - khatma['startPage'] + 1;
                        final percent = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  khatma['title'] ?? 'ختمة القرآن الكبرى',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${(percent * 100).toInt()}%',
                                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'الصفحة الحالية: ${khatma['currentPage']} من ${khatma['endPage']}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.onTabChanged(2); // التبويب الثالث (الحفظ والختمات)
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('إنشاء خطة ختمة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: accentColor.withOpacity(0.5), width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                const SizedBox(height: 24),

                // العلامات المرجعية الأخيرة
                if (_lastBookmark != null)
                  _buildSectionCard(
                    title: 'آخر العلامات المرجعية',
                    isDark: isDark,
                    accentColor: accentColor,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark, color: accentColor, size: 24),
                        ),
                        title: Text(
                          'سورة ${_lastBookmark!['surahName']} - الآية ${_lastBookmark!['ayah']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          'صفحة ${_lastBookmark!['page']} - ${_lastBookmark!['label']}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: accentColor),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final Color accentColor = const Color(0xFFD4AF37);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 6,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
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

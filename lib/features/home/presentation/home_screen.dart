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
                ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                : [const Color(0xFFE8F0EC), const Color(0xFFF9FBF9)],
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
                        Text(
                          'رفيق القرآن',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                            color: isDark ? Colors.white : primaryColor,
                          ),
                        ),
                        Text(
                          'مرحباً بك في رفيقك اليومي',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      color: accentColor,
                      onPressed: () {
                        appState.toggleDarkMode(!isDark);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // بطاقة مواقيت الصلاة الحالية القادمة
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الصلاة القادمة: $_nextPrayerName',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.teal[100],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '- $_timeUntilNextPrayer',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'مواقيت الصلاة حسب توقيت مكة المكرمة',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.teal[200],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time_filled,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // أزرار سريعة: متابعة القراءة واستكمال الاستماع
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        title: 'متابعة القراءة',
                        subtitle: 'سورة ${quran.getSurahNameArabic(appState.lastSurahRead)} - ص ${appState.lastPageRead}',
                        icon: Icons.chrome_reader_mode,
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        textColor: isDark ? Colors.white : Colors.black87,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        title: 'استكمال الاستماع',
                        subtitle: 'سورة ${quran.getSurahNameArabic(appState.lastAudioSurah)} (${appState.lastAudioReciter})',
                        icon: Icons.play_circle_filled,
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        textColor: isDark ? Colors.white : Colors.black87,
                        onTap: () {
                          // تحويل المستخدم لشاشة القرآن مع تفعيل التلاوة
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
                const SizedBox(height: 20),

                // آية اليوم
                _buildSectionCard(
                  title: 'آية اليوم',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '﴿ $ayahOfDayText ﴾',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amber[200] : primaryColor,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ayahOfDayReference,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontDirection: TextDirection.rtl,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                  color: isDark ? const Color(0xFF1F2E2A) : const Color(0xFFF0F7F4),
                ),
                const SizedBox(height: 20),

                // ذكر اليوم
                _buildSectionCard(
                  title: 'ذكر اليوم',
                  child: Text(
                    zekrOfDayText,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[200] : Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  color: isDark ? const Color(0xFF2A281E) : const Color(0xFFFDFBF0),
                ),
                const SizedBox(height: 20),

                // الورد اليومي والختمات
                if (_khatmaPlans.isNotEmpty)
                  _buildSectionCard(
                    title: 'خطة الختمة الحالية',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _khatmaPlans.map((khatma) {
                        final total = khatma['endPage'] - khatma['startPage'] + 1;
                        final current = khatma['currentPage'] - khatma['startPage'] + 1;
                        final percent = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  khatma['title'] ?? 'ختمة القرآن الكبرى',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${(percent * 100).toInt()}%',
                                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الصفحة الحالية: ${khatma['currentPage']} من ${khatma['endPage']}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    color: isDark ? const Color(0xFF242424) : Colors.white,
                  )
                else
                  _buildSectionCard(
                    title: 'خطة الختمة',
                    child: Column(
                      children: [
                        Text(
                          'لم تقم بإنشاء خطة ختمة قرآني بعد. أنشئ خطتك المخصصة لتتبع وردك اليومي ونسبة الإنجاز.',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            // التبديل إلى تبويب الختمة أو فتح شاشتها
                            widget.onTabChanged(2); // التبويب الثالث (الحفظ والختمات)
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('إنشاء خطة ختمة جديدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    color: isDark ? const Color(0xFF242424) : Colors.white,
                  ),
                const SizedBox(height: 20),

                // العلامات المرجعية الأخيرة
                if (_lastBookmark != null)
                  _buildSectionCard(
                    title: 'آخر العلامات المرجعية',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.bookmark, color: accentColor, size: 28),
                      title: Text(
                        'سورة ${_lastBookmark!['surahName']} - الآية ${_lastBookmark!['ayah']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('صفحة ${_lastBookmark!['page']} - ${_lastBookmark!['label']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                    color: isDark ? const Color(0xFF242424) : Colors.white,
                  ),
                const SizedBox(height: 20),

                // اختصار رفيق الذكي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'هل لديك سؤال حول آية أو تفسير؟',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'اسأل مساعدك الذكي "رفيق الذكي" ليجيبك في الحال',
                              style: TextStyle(
                                color: Colors.blue.shade100,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.onTabChanged(4); // التبويب الخامس (رفيق الذكي)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3C72),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text(
                          'تحدث معه',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
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
    required VoidCallback onTap,
  }) {
    final Color accentColor = const Color(0xFFD4AF37);
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 32),
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
              const SizedBox(height: 4),
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
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textDirection: TextDirection.rtl,
          ),
          const Divider(height: 16, thickness: 0.5),
          child,
        ],
      ),
    );
  }
}

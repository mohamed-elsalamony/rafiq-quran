import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:adhan/adhan.dart';

// Core services
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/hadith_service.dart';
import '../../../core/services/prophet_blessing_service.dart';
import '../../../core/services/companions_service.dart';
import '../../../core/services/periodic_notification_helper.dart';

// Feature providers & screens
import '../../adhkar/presentation/adhkar_provider.dart';

// Feature screens
import '../../quran/presentation/quran_screen.dart';
import '../../hifz_khatma/presentation/hifz_khatma_screen.dart';
import '../../hadith/presentation/hadith_library_screen.dart';
import '../../prayer_times/presentation/prayer_provider.dart';
import '../../prayer_times/presentation/qibla_compass_screen.dart';
import '../../prophets_stories/presentation/prophets_stories_screen.dart';
import '../../seerah/presentation/seerah_screen.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../ai_assistant/presentation/ai_chat_screen.dart';
import '../../aldaa_wadawaa/presentation/aldaa_wadawaa_screen.dart';
import '../../companions/presentation/companions_list_screen.dart';
import '../../religious_stories/presentation/religious_stories_list_screen.dart';
import 'prophet_blessing_screen.dart';

// ═══════════════════════════════════════════════════════════
//  HomeScreen
// ═══════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final Function(int) onTabChanged;
  const HomeScreen({super.key, required this.onTabChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────
  static const _primary = Color(0xFF0F5A47);
  static const _accent = Color(0xFFD4AF37);
  static const _bgDark = Color(0xFF0E1A17);
  static const _bgLight = Color(0xFFF2F5F3);

  // ── Animation ──────────────────────────────────────────
  late AnimationController _animCtrl;

  // ── Prayer countdown ──────────────────────────────────
  String _timeUntilNextPrayer = '--:--:--';
  String _nextPrayerName = '';
  Timer? _prayerTimer;

  Map<String, dynamic>? _lastBookmark; // محفوظ للاستخدام المستقبلي
  List<Map<String, dynamic>> _khatmaPlans = [];
  Hadith? _hadithOfDay;
  Companion? _companionOfDay;
  String? _dailyDhikrTip;

  // ── Ayah of day (static for now) ─────────────────────
  static const _ayahText =
      'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ';
  static const _ayahRef = 'سورة الإسراء • الآية ٩';

  // ═══════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPrayerTimer();
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  //  Data loading
  // ═══════════════════════════════════════════════════════
  Future<void> _loadDashboardData() async {
    final bookmarks = await DbHelper.getBookmarks();
    final khatmas = await DbHelper.getKhatmaPlans();

    final hadithSvc = HadithService();
    final hadith = await hadithSvc.getHadithOfDay();

    final compSvc = CompanionsService();
    await compSvc.loadCompanions();
    final companion = compSvc.getCompanionOfDay();

    // Pick a random dhikr tip once
    final random = Random();
    String? dhikrTip;
    if (_dailyDhikrTip == null && PeriodicNotificationHelper.adhkar.isNotEmpty) {
      dhikrTip = PeriodicNotificationHelper.adhkar[random.nextInt(PeriodicNotificationHelper.adhkar.length)];
    }

    if (!mounted) return;
    setState(() {
      _lastBookmark = bookmarks.isNotEmpty ? bookmarks.last : null;
      _khatmaPlans = khatmas;
      _hadithOfDay = hadith;
      _companionOfDay = companion;
      if (dhikrTip != null) {
        _dailyDhikrTip = dhikrTip;
      }
    });
  }

  // ═══════════════════════════════════════════════════════
  //  Prayer timer
  // ═══════════════════════════════════════════════════════
  void _startPrayerTimer() {
    _updatePrayerTime();
    _prayerTimer?.cancel();
    _prayerTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updatePrayerTime());
  }

  void _updatePrayerTime() {
    if (!mounted) return;
    try {
      final pp = Provider.of<PrayerProvider>(context, listen: false);
      final times = pp.prayerTimes;
      final now = DateTime.now();

      var next = times.nextPrayer();
      if (next == Prayer.none) next = Prayer.fajr;

      DateTime? nextTime = times.timeForPrayer(next);
      if (nextTime == null || nextTime.isBefore(now)) {
        final tomorrow = now.add(const Duration(days: 1));
        final coords = Coordinates(
            pp.currentCity.latitude, pp.currentCity.longitude);
        final tTimes = PrayerService.getPrayerTimes(
            coords, pp.currentCity.method,
            date: tomorrow);
        nextTime = tTimes.timeForPrayer(next);
      }

      if (nextTime != null) {
        final diff = nextTime.difference(now);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        final s = diff.inSeconds % 60;
        const names = {
          Prayer.fajr: 'الفجر',
          Prayer.dhuhr: 'الظهر',
          Prayer.asr: 'العصر',
          Prayer.maghrib: 'المغرب',
          Prayer.isha: 'العشاء',
        };
        setState(() {
          _nextPrayerName = names[next] ?? 'الفجر';
          _timeUntilNextPrayer =
              '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        });
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════════════════════
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'ليلة مباركة 🌙';
    if (h < 12) return 'صباح الخير ☀️';
    if (h < 17) return 'مساء النور 🌿';
    if (h < 20) return 'مساء الخير 🌅';
    return 'ليلة طيبة 🌙';
  }

  String get _arabicDate {
    final n = DateTime.now();
    const months = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${n.day} ${months[n.month - 1]} ${n.year}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}م';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}ك';
    return count.toString();
  }

  String _safeArabicSurahName(int surah) {
    try {
      return quran.getSurahNameArabic(surah.clamp(1, 114));
    } catch (_) {
      return 'سورة البقرة';
    }
  }

  void _pushScreen(Widget screen) {
    Navigator.push(context, _slide(screen)).then((_) => _loadDashboardData());
  }

  Route _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
          child: FadeTransition(opacity: a, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      );

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? _bgDark : _bgLight,
      floatingActionButton: _buildFab(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _FadeSlide(ctrl: _animCtrl, delay: 0.0,
                      child: _buildHeroZone(isDark)),
                  const SizedBox(height: 20),
                  _FadeSlide(ctrl: _animCtrl, delay: 0.12,
                      child: _buildContinueRow(appState, isDark)),
                  const SizedBox(height: 20),
                  _FadeSlide(ctrl: _animCtrl, delay: 0.18,
                      child: _buildRemindersCard(isDark)),
                  const SizedBox(height: 20),
                  _FadeSlide(ctrl: _animCtrl, delay: 0.22,
                      child: _buildAyahCard(isDark)),
                  const SizedBox(height: 14),
                  if (_hadithOfDay != null)
                    _FadeSlide(ctrl: _animCtrl, delay: 0.30,
                        child: _buildHadithCard(isDark)),
                  if (_hadithOfDay != null) const SizedBox(height: 14),
                  _FadeSlide(ctrl: _animCtrl, delay: 0.38,
                      child: _buildQuickGrid(isDark)),
                  const SizedBox(height: 14),
                  _FadeSlide(ctrl: _animCtrl, delay: 0.45,
                      child: _buildMoreRow(isDark)),
                  const SizedBox(height: 14),
                  if (_khatmaPlans.isNotEmpty)
                    _FadeSlide(ctrl: _animCtrl, delay: 0.50,
                        child: _buildKhatmaCard(isDark)),
                  if (_khatmaPlans.isNotEmpty) const SizedBox(height: 14),
                  if (_companionOfDay != null)
                    _FadeSlide(ctrl: _animCtrl, delay: 0.55,
                        child: _buildCompanionCard(isDark)),
                  if (_companionOfDay != null) const SizedBox(height: 14),
                  _FadeSlide(ctrl: _animCtrl, delay: 0.60,
                      child: _buildBlessingCard(isDark)),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  FAB — مليونية الصلاة
  // ═══════════════════════════════════════════════════════
  Widget _buildFab(bool isDark) {
    return FloatingActionButton.extended(
      heroTag: 'home_fab',
      onPressed: () => _pushScreen(const ProphetBlessingScreen()),
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      label: Row(
        children: [
          Text('ﷺ',
              style: GoogleFonts.amiri(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(width: 6),
          const Text('صلِّ على النبي',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HERO ZONE — الصلاة القادمة والعد التنازلي
  // ═══════════════════════════════════════════════════════
  Widget _buildHeroZone(bool isDark) {
    final pp = Provider.of<PrayerProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [const Color(0xFF0D3D30), const Color(0xFF071F19)]
              : [_primary, const Color(0xFF073A2F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circle
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top row: greeting + settings ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _arabicDate,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // ── Center: countdown ──
              Center(
                child: Column(
                  children: [
                    Text(
                      _timeUntilNextPrayer,
                      style: GoogleFonts.outfit(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 3,
                        height: 1,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accent.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        'الصلاة القادمة • $_nextPrayerName',
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Bottom row: city + link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => widget.onTabChanged(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.schedule_rounded,
                              color: Colors.white70, size: 13),
                          SizedBox(width: 5),
                          Text('عرض المواقيت',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pp.currentCity.nameArabic,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white38, size: 13),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CONTINUE ROW — تابع رحلتك
  // ═══════════════════════════════════════════════════════
  Widget _buildContinueRow(AppState appState, bool isDark) {
    final readPage = appState.lastPageRead;
    final readSurah = appState.lastSurahRead.clamp(1, 114);
    final audioSurah = appState.lastAudioSurah.clamp(1, 114);
    final hasAudio = appState.lastAudioPositionMs > 0;
    final hasKhatma = _khatmaPlans.isNotEmpty;

    final cards = <Widget>[
      // ── قرآن ──
      _ContinueCard(
        icon: Icons.menu_book_rounded,
        iconColor: _primary,
        title: readPage > 1 ? 'أكمل القراءة' : 'ابدأ القراءة',
        subtitle:
            'سورة ${_safeArabicSurahName(readSurah)} • ص${readPage}',
        actionLabel: 'اقرأ',
        isDark: isDark,
        onTap: () => _pushScreen(QuranScreen(
            initialPage: readPage, initialSurah: readSurah)),
      ),
    ];

    // ── تلاوة صوتية ──
    if (hasAudio) {
      cards.add(_ContinueCard(
        icon: Icons.play_circle_outline_rounded,
        iconColor: const Color(0xFF1565C0),
        title: 'أكمل الاستماع',
        subtitle:
            'سورة ${_safeArabicSurahName(audioSurah)} • ${appState.lastAudioReciter}',
        actionLabel: 'استمع',
        isDark: isDark,
        onTap: () => _pushScreen(QuranScreen(
          initialPage: quran
              .getPageNumber(audioSurah, appState.lastAudioAyah.clamp(1, 286)),
          initialSurah: audioSurah,
          autoPlay: true,
        )),
      ));
    }

    // ── ختمة ──
    if (hasKhatma) {
      final k = _khatmaPlans.first;
      final total = (k['endPage'] as int) - (k['startPage'] as int) + 1;
      final current =
          (k['currentPage'] as int) - (k['startPage'] as int) + 1;
      final pct = total > 0 ? (current / total * 100).toInt() : 0;
      cards.add(_ContinueCard(
        icon: Icons.auto_graph_rounded,
        iconColor: _accent,
        title: 'خطة الختمة',
        subtitle: '$pct% منجز • ص${k['currentPage']}',
        actionLabel: 'تفاصيل',
        isDark: isDark,
        onTap: () => _pushScreen(const HifzKhatmaScreen()),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => widget.onTabChanged(0),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('فتح المصحف ←',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? _accent : _primary,
                        fontWeight: FontWeight.w600)),
              ),
              Text(
                'تابع رحلتك',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: false,
            padding: const EdgeInsets.only(right: 4),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  AYAH CARD — آية اليوم
  // ═══════════════════════════════════════════════════════
  Widget _buildAyahCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132820) : const Color(0xFFE8F4EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1D3F30)
              : const Color(0xFFC6E0D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'آية اليوم',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // نص الآية
          Text(
            '﴿ $_ayahText ﴾',
            style: GoogleFonts.amiri(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFD4E8DA) : _primary,
              height: 1.9,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          // مرجع
          Center(
            child: Text(
              _ayahRef,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HADITH CARD — حديث اليوم
  // ═══════════════════════════════════════════════════════
  Widget _buildHadithCard(bool isDark) {
    final h = _hadithOfDay!;
    return GestureDetector(
      onTap: () => _pushScreen(const HadithLibraryScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13202E) : const Color(0xFFE8EFF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1C3048)
                : const Color(0xFFBDD0EA),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 13, color: Color(0xFF1565C0)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'حديث اليوم',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '« ${h.text} »',
              style: GoogleFonts.amiri(
                fontSize: 15,
                height: 1.75,
                color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'رواه ${h.source}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  QUICK ACCESS GRID 4×2 — وصول سريع
  // ═══════════════════════════════════════════════════════
  Widget _buildQuickGrid(bool isDark) {
    final items = [
      _GItem('القرآن', Icons.menu_book_rounded,
          const Color(0xFF0F5A47), () => widget.onTabChanged(0)),
      _GItem('الأذكار', Icons.wb_sunny_rounded,
          const Color(0xFF1565C0), () => widget.onTabChanged(1)),
      _GItem('المواقيت', Icons.mosque_rounded,
          const Color(0xFF6A1B9A), () => widget.onTabChanged(4)),
      _GItem('التسبيح', Icons.fingerprint_rounded,
          const Color(0xFF00838F), () => widget.onTabChanged(3)),
      _GItem('الأحاديث', Icons.auto_stories_rounded,
          const Color(0xFFBF360C),
          () => _pushScreen(const HadithLibraryScreen())),
      _GItem('الأنبياء', Icons.stars_rounded,
          const Color(0xFF558B2F),
          () => _pushScreen(const ProphetsStoriesScreen())),
      _GItem('السيرة', Icons.history_edu_rounded,
          const Color(0xFF4527A0),
          () => _pushScreen(const SeerahScreen())),
      _GItem('رفيق AI', Icons.auto_awesome_rounded,
          const Color(0xFF8B2FC9),
          () => _pushScreen(const AiChatScreen())),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 12),
          child: Text(
            'وصول سريع',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.88,
          children: items.map((item) => _QuickGridItem(item: item, isDark: isDark)).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  MORE ROW — اكتشف المزيد
  // ═══════════════════════════════════════════════════════
  Widget _buildMoreRow(bool isDark) {
    final chips = [
      _MItem('الصحابة', Icons.group_rounded,
          () => _pushScreen(const CompanionsListScreen())),
      _MItem('القصص الهادفة', Icons.collections_bookmark_rounded,
          () => _pushScreen(const ReligiousStoriesListScreen())),
      _MItem('الداء والدواء', Icons.healing_rounded,
          () => _pushScreen(const AldaaWadawaaScreen())),
      _MItem('القبلة', Icons.explore_rounded,
          () => _pushScreen(const QiblaCompassScreen())),
      _MItem('حفظ وختمة', Icons.assignment_turned_in_rounded,
          () => _pushScreen(const HifzKhatmaScreen())),
      _MItem('حساب ومزامنة', Icons.cloud_sync_rounded,
          () => _pushScreen(const AuthScreen())),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 10),
          child: Text(
            'اكتشف المزيد',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: false,
            padding: const EdgeInsets.only(right: 4),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = chips[i];
              return GestureDetector(
                onTap: c.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2A26)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon,
                          size: 13,
                          color: isDark ? Colors.white54 : Colors.grey[600]),
                      const SizedBox(width: 5),
                      Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  KHATMA CARD — تقدم الختمة
  // ═══════════════════════════════════════════════════════
  Widget _buildKhatmaCard(bool isDark) {
    final k = _khatmaPlans.first;
    final total = (k['endPage'] as int) - (k['startPage'] as int) + 1;
    final current =
        (k['currentPage'] as int) - (k['startPage'] as int) + 1;
    final pct = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _pushScreen(const HifzKhatmaScreen()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F14) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? _accent.withOpacity(0.15)
                : _accent.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(pct * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      k['title'] ?? 'خطة الختمة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: pct),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الصفحة ${k['currentPage']} من ${k['endPage']}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  COMPANION CARD — صحابي اليوم
  // ═══════════════════════════════════════════════════════
  Widget _buildCompanionCard(bool isDark) {
    final c = _companionOfDay!;
    final bioText = c.virtues.isNotEmpty ? c.virtues : c.moments;
    final shortBio =
        bioText.length > 200 ? '${bioText.substring(0, 200)}...' : bioText;

    return GestureDetector(
      onTap: () => _pushScreen(const CompanionsListScreen()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2215) : const Color(0xFFF2F9EB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF283D1C)
                : const Color(0xFFC8DFB2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 13, color: Color(0xFF558B2F)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF558B2F),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'صحابي اليوم',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              c.name,
              style: GoogleFonts.amiri(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF9CCC65)
                    : const Color(0xFF33691E),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              shortBio,
              style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BLESSING CARD — مليونية الصلاة على النبي ﷺ
  // ═══════════════════════════════════════════════════════
  Widget _buildBlessingCard(bool isDark) {
    return Consumer<ProphetBlessingService>(
      builder: (_, svc, __) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [const Color(0xFF2A1F00), const Color(0xFF1A1200)]
                  : [const Color(0xFFFFF8E1), const Color(0xFFFEF3CC)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accent.withOpacity(isDark ? 0.25 : 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _pushScreen(const ProphetBlessingScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('شارك الآن',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Text(
                    'مليونية الصلاة على النبي ﷺ',
                    style: GoogleFonts.amiri(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? _accent : const Color(0xFF6D4C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // العدادات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BlessingCount(
                    label: 'عالمياً',
                    value: _formatCount(svc.globalCount),
                    isDark: isDark,
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: _accent.withOpacity(0.3),
                  ),
                  _BlessingCount(
                    label: 'صلواتك اليوم',
                    value: '${svc.personalCount}',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  //  REMINDERS CARD — التذكيرات اليومية المهمة
  // ═══════════════════════════════════════════════════════
  Widget _buildRemindersCard(bool isDark) {
    // Dynamic zekr based on hour
    final hour = DateTime.now().hour;
    String zekrCategory = 'أذكار الصباح';
    String zekrTitle = 'أذكار الصباح ☀️';
    String zekrSubtitle = 'هل تحصّنت اليوم؟ اقرأ أذكار الصباح لنور وبركة يومك.';
    IconData zekrIcon = Icons.wb_sunny_rounded;
    Color zekrColor = Colors.orange;

    if (hour >= 12 && hour < 17) {
      zekrCategory = 'أذكار المساء';
      zekrTitle = 'أذكار المساء 🌅';
      zekrSubtitle = 'أقبل المساء؛ حصّن نفسك بذكر الله الحكيم.';
      zekrIcon = Icons.wb_twilight_rounded;
      zekrColor = const Color(0xFFE65100);
    } else if (hour >= 17 || hour < 5) {
      zekrCategory = 'أذكار النوم والاستيقاظ';
      zekrTitle = 'أذكار النوم 🌙';
      zekrSubtitle = 'لا تنسَ أذكار النوم لتبيت في حفظ الله ورعايته.';
      zekrIcon = Icons.nightlight_round;
      zekrColor = const Color(0xFF7E57C2);
    }

    final hasKhatma = _khatmaPlans.isNotEmpty;
    final k = hasKhatma ? _khatmaPlans.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E1B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : _primary.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: _accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'التذكيرات اليومية المهمة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Zekr reminder tile
          _buildReminderTile(
            icon: zekrIcon,
            iconBg: zekrColor.withOpacity(0.1),
            iconColor: zekrColor,
            title: zekrTitle,
            subtitle: zekrSubtitle,
            actionLabel: 'ابدأ الآن',
            isDark: isDark,
            onTap: () {
              Provider.of<AdhkarProvider>(context, listen: false)
                  .setCategory(zekrCategory);
              widget.onTabChanged(1); // Go to Adhkar tab
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, thickness: 0.5, color: Colors.black12),
          ),

          // 2. Khatma daily progress reminder
          _buildReminderTile(
            icon: Icons.menu_book_rounded,
            iconBg: _primary.withOpacity(0.1),
            iconColor: _primary,
            title: 'وردك اليومي',
            subtitle: hasKhatma
                ? 'تابع قراءة وردك القرآني اليوم: من صفحة ${k!['currentPage']} إلى ${k['endPage']}.'
                : 'لم تقم بإنشاء خطة ختمة بعد. ابدأ الآن ونظّم قراءتك اليومية.',
            actionLabel: hasKhatma ? 'اقرأ' : 'أنشئ خطة',
            isDark: isDark,
            onTap: () {
              if (hasKhatma) {
                // Open Quran reader on the page
                final page = k!['currentPage'] as int;
                final surah = (quran.getPageData(page).first['surah'] as int).clamp(1, 114);
                _pushScreen(QuranScreen(initialPage: page, initialSurah: surah));
              } else {
                // Open Khatma screen
                _pushScreen(const HifzKhatmaScreen());
              }
            },
          ),

          if (_dailyDhikrTip != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, thickness: 0.5, color: Colors.black12),
            ),
            // 3. Daily Dhikr Tip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2622) : const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? _primary.withOpacity(0.1)
                      : _primary.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: _accent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'ذكر اليوم وتوصية روحيّة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? _accent : const Color(0xFF6D4C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dailyDhikrTip!,
                    style: GoogleFonts.amiri(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: iconColor.withOpacity(0.08),
            foregroundColor: iconColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Data models
// ═══════════════════════════════════════════════════════════
class _GItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GItem(this.label, this.icon, this.color, this.onTap);
}

class _MItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MItem(this.label, this.icon, this.onTap);
}

// ═══════════════════════════════════════════════════════════
//  _QuickGridItem
// ═══════════════════════════════════════════════════════════
class _QuickGridItem extends StatefulWidget {
  final _GItem item;
  final bool isDark;
  const _QuickGridItem({required this.item, required this.isDark});

  @override
  State<_QuickGridItem> createState() => _QuickGridItemState();
}

class _QuickGridItemState extends State<_QuickGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        item.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF182420) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? item.color.withOpacity(0.15)
                  : item.color.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, size: 23, color: item.color),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  _ContinueCard
// ═══════════════════════════════════════════════════════════
class _ContinueCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool isDark;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF182420) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? iconColor.withOpacity(0.15)
                : iconColor.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // action button
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // icon circle
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  _BlessingCount
// ═══════════════════════════════════════════════════════════
class _BlessingCount extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _BlessingCount(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF6D4C00),
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  _FadeSlide — Staggered animation wrapper
// ═══════════════════════════════════════════════════════════
class _FadeSlide extends StatelessWidget {
  final AnimationController ctrl;
  final double delay; // 0.0 → 1.0
  final Widget child;

  const _FadeSlide({
    required this.ctrl,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final end = (delay + 0.38).clamp(0.0, 1.0);

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(delay, end, curve: Curves.easeOut),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(delay, end, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

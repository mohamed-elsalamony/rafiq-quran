import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/prayer_service.dart';
import 'prayer_provider.dart';
import 'qibla_compass_screen.dart';

class PrayerQiblaScreen extends StatefulWidget {
  const PrayerQiblaScreen({super.key});

  @override
  State<PrayerQiblaScreen> createState() => _PrayerQiblaScreenState();
}

class _PrayerQiblaScreenState extends State<PrayerQiblaScreen> {
  bool _isInit = false;
  String _timeUntilNextPrayer = '--:--:--';
  String _nextPrayerName = '';
  Timer? _prayerTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final prayerProvider =
          Provider.of<PrayerProvider>(context, listen: false);
      prayerProvider.addListener(_onProviderChange);
      _startPrayerTimer();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    try {
      final prayerProvider =
          Provider.of<PrayerProvider>(context, listen: false);
      prayerProvider.removeListener(_onProviderChange);
    } catch (_) {}
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = Provider.of<PrayerProvider>(context, listen: false);

    if (provider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage!, textAlign: TextAlign.right),
              backgroundColor: Colors.amber[900],
            ),
          );
          provider.clearError();
        }
      });
    }

    if (provider.isDetectingLocation) {
      _showLocationLoadingDialog();
    }

    // Refresh calculations
    _updatePrayerTime();
  }

  void _startPrayerTimer() {
    _updatePrayerTime();
    _prayerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updatePrayerTime();
    });
  }

  void _updatePrayerTime() {
    if (!mounted) return;
    final provider = Provider.of<PrayerProvider>(context, listen: false);
    final times = provider.prayerTimes;
    final now = DateTime.now();

    // Identify next prayer
    var next = times.nextPrayer();
    if (next == Prayer.none) {
      next = Prayer.fajr;
    }

    DateTime? nextTime = times.timeForPrayer(next);
    if (nextTime == null || nextTime.isBefore(now)) {
      // If it's Fajr for tomorrow, calculate next day's times
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowCoords = Coordinates(
          provider.currentCity.latitude, provider.currentCity.longitude);
      final tomorrowTimes = PrayerService.getPrayerTimes(
          tomorrowCoords, provider.currentCity.method,
          date: tomorrow);
      nextTime = tomorrowTimes.timeForPrayer(next);
    }

    if (nextTime != null) {
      final diff = nextTime.difference(now);
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      final secs = diff.inSeconds % 60;

      String nameStr = '';
      switch (next) {
        case Prayer.fajr:
          nameStr = 'الفجر';
          break;
        case Prayer.dhuhr:
          nameStr = 'الظهر';
          break;
        case Prayer.asr:
          nameStr = 'العصر';
          break;
        case Prayer.maghrib:
          nameStr = 'المغرب';
          break;
        case Prayer.isha:
          nameStr = 'العشاء';
          break;
        default:
          nameStr = 'الفجر';
          break;
      }

      setState(() {
        _nextPrayerName = nameStr;
        _timeUntilNextPrayer =
            '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showLocationLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Selector<PrayerProvider, bool>(
          selector: (context, p) => p.isDetectingLocation,
          builder: (context, isDetecting, child) {
            if (!isDetecting) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context, rootNavigator: true).pop();
              });
            }

            return const AlertDialog(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('جاري تحديد موقعك الجغرافي...'),
                  SizedBox(width: 12),
                  CircularProgressIndicator(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getHijriDate() {
    try {
      final now = DateTime.now();
      final jd = now.difference(DateTime(1970, 1, 1)).inDays + 2440588;
      final l = jd - 1948440 + 10632;
      final n = ((l - 1) / 10631).floor();
      final l2 = l - 10631 * n + 354;
      final j = (((10985 - l2) / 30).floor() *
          ((l2 - 1) / 30).floor() *
          (l2 / 30).floor());
      final y = 30 * n + ((10630 - l2) / 354).floor() + j - 1;
      final m = (((l2 - 354 * j) / 30).floor() + 1);
      final d = (l2 - 354 * j - 30 * m + 30).floor() + 1;

      final List<String> hijriMonths = [
        'محرم',
        'صفر',
        'ربيع الأول',
        'ربيع الآخر',
        'جمادى الأولى',
        'جمادى الآخرة',
        'رجب',
        'شعبان',
        'رمضان',
        'شوال',
        'ذو القعدة',
        'ذو الحجة'
      ];
      return '$d ${hijriMonths[m - 1]} $y هـ';
    } catch (_) {
      return '';
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    try {
      final localTime = time.toLocal();
      final hour = localTime.hour > 12
          ? localTime.hour - 12
          : (localTime.hour == 0 ? 12 : localTime.hour);
      final min = localTime.minute.toString().padLeft(2, '0');
      final period = localTime.hour >= 12 ? 'م' : 'ص';
      return '$hour:$min $period';
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color goldColor = Color(0xFFD4AF37);

    // List of prayers with mapping keys for alarms
    final List<Map<String, dynamic>> prayersList = [
      {
        'key': 'Fajr',
        'name': 'الفجر',
        'time': prayerProvider.prayerTimes.fajr,
        'icon': Icons.wb_twilight
      },
      {
        'key': 'Sunrise',
        'name': 'الشروق',
        'time': prayerProvider.prayerTimes.sunrise,
        'icon': Icons.light_mode
      },
      {
        'key': 'Dhuhr',
        'name': 'الظهر',
        'time': prayerProvider.prayerTimes.dhuhr,
        'icon': Icons.wb_sunny
      },
      {
        'key': 'Asr',
        'name': 'العصر',
        'time': prayerProvider.prayerTimes.asr,
        'icon': Icons.cloud
      },
      {
        'key': 'Maghrib',
        'name': 'المغرب',
        'time': prayerProvider.prayerTimes.maghrib,
        'icon': Icons.nights_stay
      },
      {
        'key': 'Isha',
        'name': 'العشاء',
        'time': prayerProvider.prayerTimes.isha,
        'icon': Icons.dark_mode
      },
    ];

    final nextPrayer = prayerProvider.prayerTimes.nextPrayer();
    final currentPrayer = prayerProvider.prayerTimes.currentPrayer();

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0E1A17) : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'مواقيت الصلاة والقبلة',
          style: GoogleFonts.amiri(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QiblaCompassScreen()),
              );
            },
            tooltip: 'بوصلة القبلة',
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: prayerProvider.detectLocation,
            tooltip: 'تحديد موقعي',
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF0E1A17) : const Color(0xFFF2F5F3),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Choose city card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Location Mode Row
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.teal),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'تحديد الموقع تلقائياً (GPS)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: prayerProvider.isAutoGps,
                            activeColor: goldColor,
                            onChanged: (val) {
                              prayerProvider.setAutoGps(val);
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (prayerProvider.isAutoGps)
                            Row(
                              children: [
                                const Icon(Icons.gps_fixed,
                                    size: 16, color: Colors.teal),
                                const SizedBox(width: 6),
                                Text(
                                  'الوضع التلقائي نشط',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.teal[200]
                                        : primaryColor,
                                  ),
                                ),
                              ],
                            )
                          else
                            DropdownButton<String>(
                              value: prayerProvider.selectedCityName ==
                                      'موقعي الحالي'
                                  ? 'موقعي الحالي'
                                  : prayerProvider.selectedCityName,
                              underline: const SizedBox(),
                              dropdownColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.amber[200] : primaryColor,
                                fontFamily: 'Outfit',
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: 'موقعي الحالي',
                                    child: Text('📍 موقعي الحالي')),
                                ...PrayerService.defaultCities.keys.map((city) {
                                  return DropdownMenuItem(
                                      value: city, child: Text(city));
                                }),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  if (val == 'موقعي الحالي') {
                                    prayerProvider.detectLocation();
                                  } else {
                                    prayerProvider.selectCity(val);
                                  }
                                }
                              },
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _getHijriDate(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.grey[200]
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                DateTime.now()
                                    .toLocal()
                                    .toString()
                                    .substring(0, 10),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pre-Prayer Alarms Card
              _buildPreAlarmCard(isDark, primaryColor, goldColor, prayerProvider),
              const SizedBox(height: 20),

              // Dynamic countdown card
              Container(
                padding: const EdgeInsets.all(20.0),
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
                    color: goldColor.withOpacity(0.4),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'المتبقي لصلاة $_nextPrayerName',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: goldColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _timeUntilNextPrayer,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                        fontFamily: 'Outfit',
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'حساب المواقيت لمدينة: ${prayerProvider.currentCity.nameArabic}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5 Prayers Horizontal Timeline
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: Column(
                    children: [
                      const Text(
                        'مخطط الصلوات اليومي',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: prayersList
                            .where((p) => p['key'] != 'Sunrise')
                            .map((pr) {
                          final String pKey = pr['key'];
                          final String name = pr['name'];
                          final String formattedTime = _formatTime(pr['time'])
                              .split(' ')
                              .first; // get numbers only
                          final String period =
                              _formatTime(pr['time']).split(' ').last;

                          // Check if it's the current active prayer
                          final bool isCurrent =
                              currentPrayer.name == pKey.toLowerCase();

                          return Expanded(
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? primaryColor.withOpacity(0.15)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCurrent
                                          ? goldColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    pr['icon'],
                                    color: isCurrent ? goldColor : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isCurrent
                                          ? primaryColor
                                          : (isDark
                                              ? Colors.grey[300]
                                              : Colors.black87),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$formattedTime $period',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Outfit',
                                      color:
                                          isCurrent ? goldColor : Colors.grey,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Prayer list details with consistent RTL alignment
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: isDark ? const Color(0xFF182420) : Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.access_time_rounded,
                                color: primaryColor, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'جدول الصلوات',
                            style: GoogleFonts.amiri(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prayersList.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final pr = prayersList[index];
                        final String pKey = pr['key'];
                        final String name = pr['name'];
                        final IconData icon = pr['icon'];

                        final isNext = (nextPrayer.name == 'fajr' &&
                                name == 'الفجر') ||
                            (nextPrayer.name == 'dhuhr' && name == 'الظهر') ||
                            (nextPrayer.name == 'asr' && name == 'العصر') ||
                            (nextPrayer.name == 'maghrib' && name == 'المغرب') ||
                            (nextPrayer.name == 'isha' && name == 'العشاء');

                        final bool hasAlarm = pKey != 'Sunrise';
                        final bool isAlarmOn = hasAlarm &&
                            (prayerProvider.alarmsEnabled[pKey] ?? true);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          color: isNext
                              ? (isDark
                                  ? Colors.teal.shade900.withOpacity(0.35)
                                  : Colors.teal.shade50)
                              : Colors.transparent,
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // LEFT SIDE: alarm icon + time
                              if (hasAlarm)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 36, minHeight: 36),
                                  icon: Icon(
                                    isAlarmOn
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_off_outlined,
                                    color: isAlarmOn ? goldColor : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      prayerProvider.toggleAlarm(pKey),
                                  tooltip: isAlarmOn
                                      ? 'تعطيل منبه الأذان'
                                      : 'تفعيل منبه الأذان',
                                )
                              else
                                const SizedBox(width: 36),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  _formatTime(pr['time']),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isNext
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isNext
                                        ? goldColor
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                    fontFamily: 'Outfit',
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              // SPACER
                              const Spacer(),
                              // RIGHT SIDE: prayer name + icon
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isNext
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isNext
                                      ? primaryColor
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                  fontFamily: 'Amiri',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: isNext
                                      ? primaryColor.withOpacity(0.12)
                                      : (isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.shade100),
                                  shape: BoxShape.circle,
                                  border: isNext
                                      ? Border.all(
                                          color: goldColor.withOpacity(0.5),
                                          width: 1.5)
                                      : null,
                                ),
                                child: Icon(
                                  icon,
                                  size: 18,
                                  color: isNext ? goldColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Pre-Alarm Card (extracted for cleanliness)
  // ═══════════════════════════════════════════════════════
  Widget _buildPreAlarmCard(
    bool isDark,
    Color primaryColor,
    Color goldColor,
    dynamic prayerProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182420) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.timer_outlined, color: goldColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تنبيهات قبل الصلاة',
                    style: GoogleFonts.amiri(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Switch(
                  value: prayerProvider.preAlarmsEnabled,
                  activeColor: goldColor,
                  onChanged: prayerProvider.setPreAlarmsEnabled,
                ),
              ],
            ),
            // Minutes picker (shown only when enabled)
            if (prayerProvider.preAlarmsEnabled) ...[
              const Divider(height: 20),
              Text(
                'اختر وقت التنبيه قبل الصلاة:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 15, 30].map((mins) {
                  final isSelected =
                      prayerProvider.preAlarmMinutes == mins;
                  return GestureDetector(
                    onTap: () => prayerProvider.setPreAlarmMinutes(mins),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? goldColor
                            : (isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? goldColor
                              : (isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        '$mins دقيقة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white60 : Colors.black54),
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

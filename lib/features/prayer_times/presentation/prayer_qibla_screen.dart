import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/prayer_service.dart';
import 'prayer_provider.dart';

class PrayerQiblaScreen extends StatefulWidget {
  const PrayerQiblaScreen({super.key});

  @override
  State<PrayerQiblaScreen> createState() => _PrayerQiblaScreenState();
}

class _PrayerQiblaScreenState extends State<PrayerQiblaScreen> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
      prayerProvider.addListener(_onProviderChange);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    try {
      final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
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

  // التقويم الهجري التقريبي الميسر
  String _getHijriDate() {
    try {
      final now = DateTime.now();
      final jd = now.difference(DateTime(1970, 1, 1)).inDays + 2440588;
      final l = jd - 1948440 + 10632;
      final n = ((l - 1) / 10631).floor();
      final l2 = l - 10631 * n + 354;
      final j = (((10985 - l2) / 30).floor() * ((l2 - 1) / 30).floor() * (l2 / 30).floor());
      final y = 30 * n + ((10630 - l2) / 354).floor() + j - 1;
      final m = (((l2 - 354 * j) / 30).floor() + 1);
      final d = (l2 - 354 * j - 30 * m + 30).floor() + 1;

      final List<String> hijriMonths = [
        'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
        'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
        'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
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
    final primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);

    // List of prayers config
    final List<Map<String, dynamic>> prayersList = [
      {'name': 'الفجر', 'time': prayerProvider.prayerTimes.fajr, 'icon': Icons.wb_twilight},
      {'name': 'الشروق', 'time': prayerProvider.prayerTimes.sunrise, 'icon': Icons.light_mode},
      {'name': 'الظهر', 'time': prayerProvider.prayerTimes.dhuhr, 'icon': Icons.wb_sunny},
      {'name': 'العصر', 'time': prayerProvider.prayerTimes.asr, 'icon': Icons.cloud},
      {'name': 'المغرب', 'time': prayerProvider.prayerTimes.maghrib, 'icon': Icons.nights_stay},
      {'name': 'العشاء', 'time': prayerProvider.prayerTimes.isha, 'icon': Icons.dark_mode},
    ];

    final nextPrayer = prayerProvider.prayerTimes.nextPrayer();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'مواقيت الصلاة والقبلة',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: prayerProvider.detectLocation,
            tooltip: 'تحديد موقعي بالـ GPS',
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Choose city card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<String>(
                            value: prayerProvider.selectedCityName == 'موقعي الحالي'
                                ? 'موقعي الحالي'
                                : prayerProvider.selectedCityName,
                            underline: const SizedBox(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.amber[200] : primaryColor,
                              fontFamily: 'Outfit',
                            ),
                            items: [
                              const DropdownMenuItem(value: 'موقعي الحالي', child: Text('📍 موقعي الحالي')),
                              ...PrayerService.defaultCities.keys.map((city) {
                                return DropdownMenuItem(value: city, child: Text(city));
                              }),
                            ],
                            onChanged: (val) {
                              if (val != null && val != 'موقعي الحالي') {
                                prayerProvider.selectCity(val);
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
                                  color: isDark ? Colors.grey[200] : Colors.black87,
                                ),
                              ),
                              Text(
                                DateTime.now().toLocal().toString().substring(0, 10),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Prayer times list
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prayersList.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final pr = prayersList[index];
                    final String name = pr['name'];
                    final isNext = (nextPrayer.name == 'fajr' && name == 'الفجر') ||
                        (nextPrayer.name == 'dhuhr' && name == 'الظهر') ||
                        (nextPrayer.name == 'asr' && name == 'العصر') ||
                        (nextPrayer.name == 'maghrib' && name == 'المغرب') ||
                        (nextPrayer.name == 'isha' && name == 'العشاء');

                    return Container(
                      color: isNext
                          ? (isDark ? Colors.teal.shade900.withOpacity(0.4) : Colors.teal.shade50.withOpacity(0.5))
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(pr['time']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                              color: isNext ? accentColor : (isDark ? Colors.white : Colors.black87),
                              fontFamily: 'Outfit',
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                                  color: isNext ? primaryColor : (isDark ? Colors.grey[200] : Colors.black87),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                pr['icon'],
                                color: isNext ? accentColor : Colors.grey,
                                size: 22,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Qibla compass
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'بوصلة اتجاه القبلة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'زاوية القبلة: ${prayerProvider.qiblaAngle.toInt()}° من الشمال الجغرافي',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onPanUpdate: (details) {
                          // Allow manual rotation on swipe
                          prayerProvider.simulateHeading(details.delta.dx / 2);
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circular compass dial
                            Transform.rotate(
                              angle: -prayerProvider.simulatedHeading * pi / 180,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                                  border: Border.all(color: primaryColor, width: 4),
                                ),
                                child: const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(top: 8, child: Text('N', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                    Positioned(bottom: 8, child: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Positioned(left: 8, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Positioned(right: 8, child: Text('E', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                            ),

                            // Golden indicator arrow pointing to Kaaba
                            Transform.rotate(
                              angle: (prayerProvider.qiblaAngle - prayerProvider.simulatedHeading) * pi / 180,
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.navigation,
                                    size: 80,
                                    color: Color(0xFFD4AF37),
                                  ),
                                  SizedBox(height: 60),
                                ],
                              ),
                            ),

                            // Central Kaaba icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mosque,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '💡 ملاحظة: اسحب لتدوير البوصلة يدوياً وتوجيه الحرف N نحو الشمال الجغرافي لضبط الاتجاه.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

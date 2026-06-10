import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/prayer_service.dart';

class PrayerQiblaScreen extends StatefulWidget {
  const PrayerQiblaScreen({super.key});

  @override
  State<PrayerQiblaScreen> createState() => _PrayerQiblaScreenState();
}

class _PrayerQiblaScreenState extends State<PrayerQiblaScreen> {
  String _selectedCityName = 'القاهرة';
  late CityConfig _currentCity;
  late PrayerTimes _prayerTimes;
  double _qiblaAngle = 0.0;
  
  // لتهيئة البوصلة التفاعلية في الكمبيوتر والويب
  double _simulatedHeading = 0.0; 

  @override
  void initState() {
    super.initState();
    _currentCity = PrayerService.defaultCities[_selectedCityName]!;
    _calculateTimes();
  }

  void _calculateTimes() {
    final coords = Coordinates(_currentCity.latitude, _currentCity.longitude);
    _prayerTimes = PrayerService.getPrayerTimes(coords, _currentCity.method);
    _qiblaAngle = PrayerService.calculateQiblaDirection(_currentCity.latitude, _currentCity.longitude);
  }

  // محاولة الحصول على الموقع الحالي عبر الـ GPS
  void _detectLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('جاري تحديد موقعك الجغرافي...'),
            SizedBox(width: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );

    try {
      final coords = await PrayerService.getCurrentLocation();
      // تحديث المدينة للموقع المكتشف
      if (mounted) {
        Navigator.pop(context); // إغلاق الحوار
        setState(() {
          _selectedCityName = 'موقعي الحالي';
          _currentCity = CityConfig(
            nameArabic: 'موقعي الحالي',
            latitude: coords.latitude,
            longitude: coords.longitude,
            method: CalculationMethod.egyptian,
          );
          _calculateTimes();
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديد الموقع: $e')),
      );
    }
  }

  // حساب التاريخ الهجري التقريبي محلياً (صيغة أم القرى التقريبية)
  String _getHijriDate() {
    final now = DateTime.now();
    // تحويل بسيط لغرض العرض في التطبيقات الإسلامية
    // الصيغة التقريبية المعتمدة
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
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    // تحويل إلى توقيت محلي وعرض 12 ساعة
    final localTime = time.toLocal();
    final hour = localTime.hour > 12 
        ? localTime.hour - 12 
        : (localTime.hour == 0 ? 12 : localTime.hour);
    final min = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'م' : 'ص';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);

    // تجهيز أوقات الصلاة للعرض
    final List<Map<String, dynamic>> prayersList = [
      {'name': 'الفجر', 'time': _prayerTimes.fajr, 'icon': Icons.wb_twilight},
      {'name': 'الشروق', 'time': _prayerTimes.sunrise, 'icon': Icons.light_mode},
      {'name': 'الظهر', 'time': _prayerTimes.dhuhr, 'icon': Icons.wb_sunny},
      {'name': 'العصر', 'time': _prayerTimes.asr, 'icon': Icons.cloud},
      {'name': 'المغرب', 'time': _prayerTimes.maghrib, 'icon': Icons.nights_stay},
      {'name': 'العشاء', 'time': _prayerTimes.isha, 'icon': Icons.dark_mode},
    ];

    final nextPrayer = _prayerTimes.nextPrayer();

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
            onPressed: _detectLocation,
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
              // اختيار المدينة والتاريخ
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
                            value: _selectedCityName == 'موقعي الحالي' ? 'موقعي الحالي' : _selectedCityName,
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
                                setState(() {
                                  _selectedCityName = val;
                                  _currentCity = PrayerService.defaultCities[val]!;
                                  _calculateTimes();
                                });
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

              // قائمة مواقيت الصلاة لليوم
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

              // بوصلة اتجاه القبلة التفاعلية
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
                        'زاوية القبلة: ${_qiblaAngle.toInt()}° من الشمال الجغرافي',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // جسم البوصلة
                      GestureDetector(
                        onPanUpdate: (details) {
                          // محاكاة تحريك البوصلة بالسحب على الشاشة (للأجهزة بدون حساسات)
                          setState(() {
                            _simulatedHeading = (_simulatedHeading + details.delta.dx / 2) % 360;
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // إطار البوصلة الدائري الخارجي
                            Transform.rotate(
                              angle: -_simulatedHeading * pi / 180,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                                  border: Border.all(color: primaryColor, width: 4),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // مؤشرات الاتجاهات الأربعة
                                    const Positioned(top: 8, child: Text('N', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                    const Positioned(bottom: 8, child: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const Positioned(left: 8, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const Positioned(right: 8, child: Text('E', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                            ),

                            // سهم القبلة الذهبي المشير إلى الكعبة
                            Transform.rotate(
                              angle: (_qiblaAngle - _simulatedHeading) * pi / 180,
                              child: Column(
                                children: [
                                  // السهم الذهبي
                                  const Icon(
                                    Icons.navigation,
                                    size: 80,
                                    color: Color(0xFFD4AF37),
                                  ),
                                  const SizedBox(height: 60), // لموازنة السهم في المنتصف
                                ],
                              ),
                            ),

                            // أيقونة الكعبة المشرفة في المركز
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

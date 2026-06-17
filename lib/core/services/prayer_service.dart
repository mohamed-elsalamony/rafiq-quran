import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class CityConfig {
  final String nameArabic;
  final double latitude;
  final double longitude;
  final CalculationMethod method;

  CityConfig({
    required this.nameArabic,
    required this.latitude,
    required this.longitude,
    required this.method,
  });
}

class PrayerService {
  // قائمة المدن الافتراضية في حال عدم توفر الـ GPS
  static final Map<String, CityConfig> defaultCities = {
    'القاهرة': CityConfig(
        nameArabic: 'القاهرة',
        latitude: 30.0444,
        longitude: 31.2357,
        method: CalculationMethod.egyptian),
    'مكة المكرمة': CityConfig(
        nameArabic: 'مكة المكرمة',
        latitude: 21.4225,
        longitude: 39.8262,
        method: CalculationMethod.umm_al_qura),
    'الرياض': CityConfig(
        nameArabic: 'الرياض',
        latitude: 24.7136,
        longitude: 46.6753,
        method: CalculationMethod.umm_al_qura),
    'القدس': CityConfig(
        nameArabic: 'القدس',
        latitude: 31.7683,
        longitude: 35.2137,
        method: CalculationMethod.egyptian),
    'المدينة المنورة': CityConfig(
        nameArabic: 'المدينة المنورة',
        latitude: 24.4672,
        longitude: 39.6111,
        method: CalculationMethod.umm_al_qura),
    'دبي': CityConfig(
        nameArabic: 'دبي',
        latitude: 25.2048,
        longitude: 55.2708,
        method: CalculationMethod.dubai),
    'عمان': CityConfig(
        nameArabic: 'عمان',
        latitude: 31.9454,
        longitude: 35.9284,
        method: CalculationMethod.egyptian),
    'بغداد': CityConfig(
        nameArabic: 'بغداد',
        latitude: 33.3152,
        longitude: 44.3661,
        method: CalculationMethod.egyptian),
  };

  // الحصول على الموقع الحالي للمستخدم أو إرجاع موقع افتراضي
  static Future<Coordinates> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // إذا كان معطلاً نرجع موقع مكة الافتراضي
        return Coordinates(21.4225, 39.8262);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Coordinates(21.4225, 39.8262);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Coordinates(21.4225, 39.8262);
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return Coordinates(position.latitude, position.longitude);
    } catch (_) {
      return Coordinates(21.4225, 39.8262); // Fallback to Makkah
    }
  }

  // حساب مواقيت الصلاة لموقع معين وتاريخ معين
  static PrayerTimes getPrayerTimes(
      Coordinates coordinates, CalculationMethod method,
      {DateTime? date}) {
    final targetDate = DateComponents.from(date ?? DateTime.now());
    final params = method.getParameters();
    params.madhab = Madhab.shafi; // المذهب الافتراضي الشافعي

    return PrayerTimes(coordinates, targetDate, params);
  }

  // حساب اتجاه القبلة رياضياً (زاوية القبلة من الشمال الجغرافي بالدرجات)
  static double calculateQiblaDirection(double lat, double lon) {
    // إحداثيات الكعبة المشرفة
    const double kaabaLat = 21.4225 * pi / 180.0;
    const double kaabaLon = 39.8262 * pi / 180.0;

    double userLat = lat * pi / 180.0;
    double userLon = lon * pi / 180.0;

    double deltaLon = kaabaLon - userLon;

    double y = sin(deltaLon);
    double x = cos(userLat) * tan(kaabaLat) - sin(userLat) * cos(deltaLon);

    double qiblaAngleRad = atan2(y, x);
    double qiblaAngleDeg = qiblaAngleRad * 180.0 / pi;

    // تحويل الزاوية لتكون بين 0 و 360
    return (qiblaAngleDeg + 360.0) % 360.0;
  }
}

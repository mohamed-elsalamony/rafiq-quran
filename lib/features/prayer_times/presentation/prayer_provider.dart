import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import '../../../core/services/prayer_service.dart';

class PrayerProvider extends ChangeNotifier {
  String _selectedCityName = 'القاهرة';
  late CityConfig _currentCity;
  late PrayerTimes _prayerTimes;
  double _qiblaAngle = 0.0;
  double _simulatedHeading = 0.0;

  bool _isDetectingLocation = false;
  String? _errorMessage;

  // Getters
  String get selectedCityName => _selectedCityName;
  CityConfig get currentCity => _currentCity;
  PrayerTimes get prayerTimes => _prayerTimes;
  double get qiblaAngle => _qiblaAngle;
  double get simulatedHeading => _simulatedHeading;
  bool get isDetectingLocation => _isDetectingLocation;
  String? get errorMessage => _errorMessage;

  PrayerProvider() {
    _currentCity = PrayerService.defaultCities[_selectedCityName]!;
    _calculateTimes();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _calculateTimes() {
    try {
      final coords = Coordinates(_currentCity.latitude, _currentCity.longitude);
      _prayerTimes = PrayerService.getPrayerTimes(coords, _currentCity.method);
      _qiblaAngle = PrayerService.calculateQiblaDirection(_currentCity.latitude, _currentCity.longitude);
    } catch (e) {
      debugPrint("Error calculating prayer times: $e");
    }
  }

  void selectCity(String cityName) {
    if (cityName == 'موقعي الحالي' || !PrayerService.defaultCities.containsKey(cityName)) return;
    _selectedCityName = cityName;
    _currentCity = PrayerService.defaultCities[cityName]!;
    _calculateTimes();
    notifyListeners();
  }

  void simulateHeading(double delta) {
    _simulatedHeading = (_simulatedHeading + delta) % 360;
    notifyListeners();
  }

  Future<void> detectLocation() async {
    if (_isDetectingLocation) return;
    _isDetectingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final coords = await PrayerService.getCurrentLocation().timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('انتهت مهلة الحصول على إحداثيات الموقع.'),
      );

      // Coordinates default back to Makkah if permission is denied, check if fallback was triggered
      if (coords.latitude == 21.4225 && coords.longitude == 39.8262) {
        _selectedCityName = 'مكة المكرمة';
        _currentCity = PrayerService.defaultCities['مكة المكرمة']!;
        _errorMessage = 'تعذر الوصول لموقعك الجغرافي (قد تكون الصلاحيات مرفوضة أو الـ GPS معطلاً). تم التحويل لمكة المكرمة افتراضياً.';
      } else {
        _selectedCityName = 'موقعي الحالي';
        _currentCity = CityConfig(
          nameArabic: 'موقعي الحالي',
          latitude: coords.latitude,
          longitude: coords.longitude,
          method: CalculationMethod.egyptian,
        );
      }

      _calculateTimes();
      _isDetectingLocation = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error detecting location: $e");
      _isDetectingLocation = false;
      _errorMessage = "فشل تحديد موقعك الجغرافي: ${e.toString().replaceAll('Exception:', '').trim()}";
      notifyListeners();
    }
  }
}

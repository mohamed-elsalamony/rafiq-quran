import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/notification_service.dart';

class PrayerProvider extends ChangeNotifier {
  String _selectedCityName = 'القاهرة';
  late CityConfig _currentCity;
  late PrayerTimes _prayerTimes;
  double _qiblaAngle = 0.0;
  double _simulatedHeading = 0.0;

  bool _isDetectingLocation = false;
  String? _errorMessage;

  // Alarms state: Fajr, Dhuhr, Asr, Maghrib, Isha
  Map<String, bool> _alarmsEnabled = {
    'Fajr': true,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };

  // Getters
  String get selectedCityName => _selectedCityName;
  CityConfig get currentCity => _currentCity;
  PrayerTimes get prayerTimes => _prayerTimes;
  double get qiblaAngle => _qiblaAngle;
  double get simulatedHeading => _simulatedHeading;
  bool get isDetectingLocation => _isDetectingLocation;
  String? get errorMessage => _errorMessage;
  Map<String, bool> get alarmsEnabled => _alarmsEnabled;

  PrayerProvider() {
    _currentCity = PrayerService.defaultCities[_selectedCityName]!;
    _calculateTimes();
    
    // Initialize notification service, then load settings
    NotificationService().init().then((_) {
      _loadSettings();
    });
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

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCity = prefs.getString('prayer_selected_city') ?? 'القاهرة';
      final savedMethodName = prefs.getString('prayer_calculation_method') ?? '';

      // Load alarms
      _alarmsEnabled = {
        'Fajr': prefs.getBool('prayer_alarm_Fajr') ?? true,
        'Dhuhr': prefs.getBool('prayer_alarm_Dhuhr') ?? true,
        'Asr': prefs.getBool('prayer_alarm_Asr') ?? true,
        'Maghrib': prefs.getBool('prayer_alarm_Maghrib') ?? true,
        'Isha': prefs.getBool('prayer_alarm_Isha') ?? true,
      };

      if (savedCity == 'موقعي الحالي') {
        final lat = prefs.getDouble('prayer_loc_lat');
        final lon = prefs.getDouble('prayer_loc_lon');
        if (lat != null && lon != null) {
          _selectedCityName = 'موقعي الحالي';
          CalculationMethod method = CalculationMethod.egyptian;
          if (savedMethodName.isNotEmpty) {
            method = CalculationMethod.values.firstWhere((m) => m.name == savedMethodName, orElse: () => CalculationMethod.egyptian);
          }
          _currentCity = CityConfig(
            nameArabic: 'موقعي الحالي',
            latitude: lat,
            longitude: lon,
            method: method,
          );
        } else {
          _selectedCityName = 'القاهرة';
          _currentCity = PrayerService.defaultCities['القاهرة']!;
        }
      } else if (PrayerService.defaultCities.containsKey(savedCity)) {
        _selectedCityName = savedCity;
        final defaultCity = PrayerService.defaultCities[savedCity]!;
        CalculationMethod method = defaultCity.method;
        if (savedMethodName.isNotEmpty) {
          method = CalculationMethod.values.firstWhere((m) => m.name == savedMethodName, orElse: () => defaultCity.method);
        }
        _currentCity = CityConfig(
          nameArabic: defaultCity.nameArabic,
          latitude: defaultCity.latitude,
          longitude: defaultCity.longitude,
          method: method,
        );
      }

      _calculateTimes();
      _reschedulePrayerAlarms();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading prayer settings: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_selected_city', _selectedCityName);
      await prefs.setString('prayer_calculation_method', _currentCity.method.name);
      if (_selectedCityName == 'موقعي الحالي') {
        await prefs.setDouble('prayer_loc_lat', _currentCity.latitude);
        await prefs.setDouble('prayer_loc_lon', _currentCity.longitude);
      }
    } catch (e) {
      debugPrint("Error saving prayer settings: $e");
    }
  }

  // --- Reschedule alarms whenever times or configurations change ---
  void _reschedulePrayerAlarms() {
    NotificationService().schedulePrayerAlarms(
      latitude: _currentCity.latitude,
      longitude: _currentCity.longitude,
      enabledAlarms: _alarmsEnabled,
      method: _currentCity.method,
    );
  }

  void selectCity(String cityName) {
    if (cityName == 'موقعي الحالي' || !PrayerService.defaultCities.containsKey(cityName)) return;
    _selectedCityName = cityName;
    _currentCity = PrayerService.defaultCities[cityName]!;
    _calculateTimes();
    _reschedulePrayerAlarms();
    notifyListeners();
    _saveSettings();
  }

  void setCalculationMethod(CalculationMethod method) {
    _currentCity = CityConfig(
      nameArabic: _currentCity.nameArabic,
      latitude: _currentCity.latitude,
      longitude: _currentCity.longitude,
      method: method,
    );
    _calculateTimes();
    _reschedulePrayerAlarms();
    notifyListeners();
    _saveSettings();
  }

  void toggleAlarm(String prayerName) async {
    if (_alarmsEnabled.containsKey(prayerName)) {
      _alarmsEnabled[prayerName] = !_alarmsEnabled[prayerName]!;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_alarm_$prayerName', _alarmsEnabled[prayerName]!);
      
      _reschedulePrayerAlarms();
    }
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
      _reschedulePrayerAlarms();
      _isDetectingLocation = false;
      notifyListeners();
      _saveSettings();
    } catch (e) {
      debugPrint("Error detecting location: $e");
      _isDetectingLocation = false;
      _errorMessage = "فشل تحديد موقعك الجغرافي: ${e.toString().replaceAll('Exception:', '').trim()}";
      notifyListeners();
    }
  }
}

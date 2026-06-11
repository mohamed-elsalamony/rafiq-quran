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

  bool _isAutoGps = false;
  bool _preAlarmsEnabled = false;
  int _preAlarmMinutes = 15;

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
  bool get isAutoGps => _isAutoGps;
  bool get preAlarmsEnabled => _preAlarmsEnabled;
  int get preAlarmMinutes => _preAlarmMinutes;

  PrayerProvider() {
    _currentCity = PrayerService.defaultCities[_selectedCityName]!;
    _calculateTimes();
    
    // Load settings and initialize notification service sequentially
    _initProvider();
  }

  Future<void> _initProvider() async {
    await _loadSettings();
    try {
      await NotificationService().init();
      _reschedulePrayerAlarms();
    } catch (e) {
      debugPrint("Error initializing notifications: $e");
    }
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

      _isAutoGps = prefs.getBool('prayer_is_auto_gps') ?? false;
      _preAlarmsEnabled = prefs.getBool('prayer_pre_alarms_enabled') ?? false;
      _preAlarmMinutes = prefs.getInt('prayer_pre_alarm_minutes') ?? 15;

      // Load alarms
      _alarmsEnabled = {
        'Fajr': prefs.getBool('prayer_alarm_Fajr') ?? true,
        'Dhuhr': prefs.getBool('prayer_alarm_Dhuhr') ?? true,
        'Asr': prefs.getBool('prayer_alarm_Asr') ?? true,
        'Maghrib': prefs.getBool('prayer_alarm_Maghrib') ?? true,
        'Isha': prefs.getBool('prayer_alarm_Isha') ?? true,
      };

      if (savedCity == 'موقعي الحالي' || _isAutoGps) {
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

        if (_isAutoGps) {
          // Refresh coordinates in the background silently
          detectLocation();
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
      await prefs.setBool('prayer_is_auto_gps', _isAutoGps);
      await prefs.setBool('prayer_pre_alarms_enabled', _preAlarmsEnabled);
      await prefs.setInt('prayer_pre_alarm_minutes', _preAlarmMinutes);
      
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
      preAlarmsEnabled: _preAlarmsEnabled,
      preAlarmMinutes: _preAlarmMinutes,
    );
  }

  void setAutoGps(bool val) {
    _isAutoGps = val;
    if (val) {
      _selectedCityName = 'موقعي الحالي';
      detectLocation();
    } else {
      _selectedCityName = 'القاهرة';
      _currentCity = PrayerService.defaultCities['القاهرة']!;
      _calculateTimes();
      _reschedulePrayerAlarms();
      notifyListeners();
      _saveSettings();
    }
  }

  void setPreAlarmsEnabled(bool val) {
    _preAlarmsEnabled = val;
    _reschedulePrayerAlarms();
    notifyListeners();
    _saveSettings();
  }

  void setPreAlarmMinutes(int mins) {
    _preAlarmMinutes = mins;
    _reschedulePrayerAlarms();
    notifyListeners();
    _saveSettings();
  }

  void selectCity(String cityName) {
    if (cityName == 'موقعي الحالي' || !PrayerService.defaultCities.containsKey(cityName)) return;
    _isAutoGps = false; // Turn off auto GPS when manually selecting a city
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

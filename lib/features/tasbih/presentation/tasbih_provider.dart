import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/db_helper.dart';

class TasbihProvider extends ChangeNotifier {
  int _counter = 0;
  int _target = 33;
  String _selectedDhikr = 'سبحان الله';
  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = true;

  List<String> _predefinedDhikrs = [
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
    'أستغفر الله العظيم',
    'اللهم صلِّ وسلم على محمد'
  ];

  List<Map<String, dynamic>> _customDhikrs = [];
  List<Map<String, dynamic>> _tasbihStats = [];
  double _btnScale = 1.0;
  String? _alertMessage;

  // Getters
  int get counter => _counter;
  int get target => _target;
  String get selectedDhikr => _selectedDhikr;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  List<String> get predefinedDhikrs => _predefinedDhikrs;
  List<Map<String, dynamic>> get customDhikrs => _customDhikrs;
  List<Map<String, dynamic>> get tasbihStats => _tasbihStats;
  double get btnScale => _btnScale;
  String? get alertMessage => _alertMessage;

  TasbihProvider() {
    loadData();
  }

  void clearAlert() {
    _alertMessage = null;
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      _customDhikrs = await DbHelper.getCustomAdhkar();
      _tasbihStats = await DbHelper.getTasbihLogs();
      
      final prefs = await SharedPreferences.getInstance();
      _counter = prefs.getInt('tasbih_current_counter') ?? 0;
      _target = prefs.getInt('tasbih_current_target') ?? 33;
      _selectedDhikr = prefs.getString('tasbih_selected_dhikr') ?? 'سبحان الله';
      _isVibrationEnabled = prefs.getBool('tasbih_is_vibration_enabled') ?? true;
      _isSoundEnabled = prefs.getBool('tasbih_is_sound_enabled') ?? true;
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading tasbih data: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tasbih_current_counter', _counter);
      await prefs.setInt('tasbih_current_target', _target);
      await prefs.setString('tasbih_selected_dhikr', _selectedDhikr);
      await prefs.setBool('tasbih_is_vibration_enabled', _isVibrationEnabled);
      await prefs.setBool('tasbih_is_sound_enabled', _isSoundEnabled);
    } catch (e) {
      debugPrint("Error saving tasbih settings: $e");
    }
  }

  void setDhikr(String dhikr) {
    _selectedDhikr = dhikr;
    // Check if there is a custom target for this Zekr
    int targetVal = 33;
    final cdIdx = _customDhikrs.indexWhere((element) => element['text'] == dhikr);
    if (cdIdx != -1) {
      targetVal = _customDhikrs[cdIdx]['target'] ?? 100;
    }
    _target = targetVal;
    _counter = 0;
    notifyListeners();
    _saveSettings();
  }

  void setTarget(int newTarget) {
    _target = newTarget;
    _counter = 0;
    notifyListeners();
    _saveSettings();
  }

  void toggleVibration() {
    _isVibrationEnabled = !_isVibrationEnabled;
    notifyListeners();
    _saveSettings();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    notifyListeners();
    _saveSettings();
  }

  void increment() {
    _counter++;
    _btnScale = 0.93;
    _alertMessage = null;
    notifyListeners();
    _saveSettings();

    // Snapback scale animation
    Future.delayed(const Duration(milliseconds: 80), () {
      _btnScale = 1.0;
      notifyListeners();
    });

    // Sound and vibration feedback
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    if (_isSoundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    // Check target reached
    if (_counter == _target) {
      if (_isVibrationEnabled) {
        HapticFeedback.vibrate();
      }
      _alertMessage = 'أحسنت! أتممت الورد لذكر "$_selectedDhikr" ($_target مرة).';
      
      // Save log offline
      DbHelper.addTasbihLog(_selectedDhikr, _target).then((_) {
        loadData();
      });
    }
  }

  void reset() {
    if (_counter > 0) {
      // Save logs before reset
      DbHelper.addTasbihLog(_selectedDhikr, _counter).then((_) {
        loadData();
      });
    }
    _counter = 0;
    HapticFeedback.mediumImpact();
    notifyListeners();
    _saveSettings();
  }

  Future<void> addNewCustomDhikr(String text, int targetCount) async {
    try {
      await DbHelper.addCustomAdhkar(text, targetCount);
      await loadData();
    } catch (e) {
      debugPrint("Error adding custom dhikr: $e");
    }
  }

  Future<void> deleteCustomDhikr(int index) async {
    try {
      await DbHelper.deleteCustomAdhkar(index);
      await loadData();
      // If deleted dhikr was selected, revert to default
      if (index < _customDhikrs.length) {
        final deletedText = _customDhikrs[index]['text'];
        if (_selectedDhikr == deletedText) {
          setDhikr('سبحان الله');
        }
      }
    } catch (e) {
      debugPrint("Error deleting custom dhikr: $e");
    }
  }

  List<Map<String, dynamic>> getWeeklyStats() {
    final Map<String, int> dailySums = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      dailySums[dateStr] = 0;
    }

    try {
      for (final log in _tasbihStats) {
        final dateStr = log['date'] as String?;
        final count = log['count'] as int? ?? 0;
        if (dateStr != null && dailySums.containsKey(dateStr)) {
          dailySums[dateStr] = dailySums[dateStr]! + count;
        }
      }
    } catch (e) {
      debugPrint("Error calculating stats: $e");
    }

    List<Map<String, dynamic>> stats = [];
    final List<String> weekdaysArabic = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
    
    dailySums.forEach((dateStr, count) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        final weekdayIdx = parsedDate.weekday == 7 ? 0 : parsedDate.weekday;
        stats.add({
          'day': weekdaysArabic[weekdayIdx],
          'count': count,
        });
      } catch (_) {}
    });

    return stats;
  }
}

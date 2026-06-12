import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/services/db_helper.dart';

class TasbihProvider extends ChangeNotifier {
  final AudioPlayer _clickPlayer = AudioPlayer();
  String? _clickFilePath;

  int _counter = 0;
  int _target = 33;
  String _selectedDhikr = 'سبحان الله';
  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = true;

  @override
  void dispose() {
    _clickPlayer.dispose();
    super.dispose();
  }

  final List<String> _predefinedDhikrs = [
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

      // Generate click sound wave file dynamically
      if (_clickFilePath == null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/click_sound.wav');
          if (!await file.exists()) {
            final int sampleRate = 8000;
            final double duration = 0.05; // 50 ms
            final int numSamples = (sampleRate * duration).toInt();
            final int dataSize = numSamples;
            final int fileSize = 44 + dataSize;

            final bytes = Uint8List(fileSize);
            final data = ByteData.sublistView(bytes);

            // RIFF header
            data.setUint8(0, 0x52); // R
            data.setUint8(1, 0x49); // I
            data.setUint8(2, 0x46); // F
            data.setUint8(3, 0x46); // F
            data.setUint32(4, fileSize - 8, Endian.little);
            data.setUint8(8, 0x57); // W
            data.setUint8(9, 0x41); // A
            data.setUint8(10, 0x56); // V
            data.setUint8(11, 0x45); // E

            // fmt subchunk
            data.setUint8(12, 0x66); // f
            data.setUint8(13, 0x6D); // m
            data.setUint8(14, 0x74); // t
            data.setUint8(15, 0x20); // 
            data.setUint32(16, 16, Endian.little);
            data.setUint16(20, 1, Endian.little); // PCM
            data.setUint16(22, 1, Endian.little); // Mono
            data.setUint32(24, sampleRate, Endian.little);
            data.setUint32(28, sampleRate, Endian.little); // ByteRate
            data.setUint16(32, 1, Endian.little); // BlockAlign
            data.setUint16(34, 8, Endian.little); // 8-bit

            // data subchunk
            data.setUint8(36, 0x64); // d
            data.setUint8(37, 0x61); // a
            data.setUint8(38, 0x74); // t
            data.setUint8(39, 0x61); // a
            data.setUint32(40, dataSize, Endian.little);

            // Decaying sine wave
            final double frequency = 1000.0;
            for (int i = 0; i < numSamples; i++) {
              final double t = i / sampleRate;
              final double sine = sin(2 * pi * frequency * t);
              final double envelope = exp(-t * 90.0);
              final int sampleValue = (128 + 127 * sine * envelope).round().clamp(0, 255);
              bytes[44 + i] = sampleValue;
            }
            await file.writeAsBytes(bytes);
          }
          _clickFilePath = file.path;
        } catch (e) {
          debugPrint("Error generating click sound WAV file: $e");
        }
      }

      final prefs = await SharedPreferences.getInstance();
      _counter = prefs.getInt('tasbih_current_counter') ?? 0;
      _target = prefs.getInt('tasbih_current_target') ?? 33;
      _selectedDhikr = prefs.getString('tasbih_selected_dhikr') ?? 'سبحان الله';
      _isVibrationEnabled =
          prefs.getBool('tasbih_is_vibration_enabled') ?? true;
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
    final cdIdx =
        _customDhikrs.indexWhere((element) => element['text'] == dhikr);
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
    HapticFeedback.selectionClick();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    notifyListeners();
    _saveSettings();
    HapticFeedback.selectionClick();
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
      HapticFeedback.vibrate();
    }
    if (_isSoundEnabled) {
      if (_clickFilePath != null) {
        try {
          _clickPlayer.play(DeviceFileSource(_clickFilePath!));
        } catch (_) {
          SystemSound.play(SystemSoundType.click);
        }
      } else {
        SystemSound.play(SystemSoundType.click);
      }
    }

    // Check target reached
    if (_counter == _target) {
      if (_isVibrationEnabled) {
        HapticFeedback.vibrate();
      }
      _alertMessage =
          'أحسنت! أتممت الورد لذكر "$_selectedDhikr" ($_target مرة).';

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
    final List<String> weekdaysArabic = [
      'أحد',
      'اثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
      'جمعة',
      'سبت'
    ];

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

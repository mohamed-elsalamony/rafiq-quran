import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class AppState extends ChangeNotifier {
  static const String _keyLastPage = 'last_page';
  static const String _keyLastSurah = 'last_surah';
  static const String _keyLastAyah = 'last_ayah';
  static const String _keyLastScreen = 'last_screen';
  static const String _keyLastReciter = 'last_reciter';
  static const String _keyLastAudioPos = 'last_audio_pos';
  static const String _keyLastAudioSurah = 'last_audio_surah';
  static const String _keyLastAudioAyah = 'last_audio_ayah';
  static const String _keyFontSize = 'font_size';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyOnboarding = 'onboarding_completed';
  static const String _keyNotifications = 'notifications_enabled';
  
  static const String _keyAutoScrollSpeed = 'auto_scroll_speed';
  static const String _keyQuranThemeMode = 'quran_theme_mode'; // 'light', 'dark', 'sepia'
  static const String _keyQuranFontFamily = 'quran_font_family'; // 'Amiri', 'Scheherazade'
  static const String _keyQuranViewMode = 'quran_view_mode'; // 'page', 'verse'
  static const String _keyShowTranslation = 'show_translation';

  static const String _keyPeriodicDhikrEnabled = 'periodic_dhikr_enabled';
  static const String _keyPeriodicDhikrInterval = 'periodic_dhikr_interval';
  static const String _keyPeriodicDhikrType = 'periodic_dhikr_type';
  static const String _keyPeriodicDhikrSilenceStart = 'periodic_dhikr_silence_start';
  static const String _keyPeriodicDhikrSilenceEnd = 'periodic_dhikr_silence_end';

  int _lastPageRead = 1;
  int _lastSurahRead = 1;
  int _lastAyahRead = 1;
  String _lastScreen = 'home';
  String _lastAudioReciter = 'عبد الباسط عبد الصمد';
  int _lastAudioPositionMs = 0;
  int _lastAudioSurah = 1;
  int _lastAudioAyah = 1;
  double _fontSize = 22.0;
  bool _isDarkMode = false;
  bool _isOnboardingCompleted = false;
  bool _notificationsEnabled = true;

  double _autoScrollSpeed = 30.0;
  String _quranThemeMode = 'light';
  String _quranFontFamily = 'Amiri';
  String _quranViewMode = 'page';
  bool _showTranslation = true;

  bool _periodicDhikrEnabled = false;
  int _periodicDhikrInterval = 60; // 60, 90, 120 minutes
  String _periodicDhikrType = 'all'; // 'verse', 'dhikr', 'hadith', 'all'
  int _periodicDhikrSilenceStart = 22; // 10 PM
  int _periodicDhikrSilenceEnd = 5; // 5 AM

  // Getters
  int get lastPageRead => _lastPageRead;
  int get lastSurahRead => _lastSurahRead;
  int get lastAyahRead => _lastAyahRead;
  String get lastScreen => _lastScreen;
  String get lastAudioReciter => _lastAudioReciter;
  int get lastAudioPositionMs => _lastAudioPositionMs;
  int get lastAudioSurah => _lastAudioSurah;
  int get lastAudioAyah => _lastAudioAyah;
  double get fontSize => _fontSize;
  bool get isDarkMode => _isDarkMode;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get notificationsEnabled => _notificationsEnabled;

  double get autoScrollSpeed => _autoScrollSpeed;
  String get quranThemeMode => _quranThemeMode;
  String get quranFontFamily => _quranFontFamily;
  String get quranViewMode => _quranViewMode;
  bool get showTranslation => _showTranslation;

  bool get periodicDhikrEnabled => _periodicDhikrEnabled;
  int get periodicDhikrInterval => _periodicDhikrInterval;
  String get periodicDhikrType => _periodicDhikrType;
  int get periodicDhikrSilenceStart => _periodicDhikrSilenceStart;
  int get periodicDhikrSilenceEnd => _periodicDhikrSilenceEnd;

  AppState() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _lastPageRead = prefs.getInt(_keyLastPage) ?? 1;
    _lastSurahRead = prefs.getInt(_keyLastSurah) ?? 1;
    _lastAyahRead = prefs.getInt(_keyLastAyah) ?? 1;
    _lastScreen = prefs.getString(_keyLastScreen) ?? 'home';
    _lastAudioReciter = prefs.getString(_keyLastReciter) ?? 'عبد الباسط عبد الصمد';
    _lastAudioPositionMs = prefs.getInt(_keyLastAudioPos) ?? 0;
    _lastAudioSurah = prefs.getInt(_keyLastAudioSurah) ?? 1;
    _lastAudioAyah = prefs.getInt(_keyLastAudioAyah) ?? 1;
    _fontSize = prefs.getDouble(_keyFontSize) ?? 22.0;
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _isOnboardingCompleted = prefs.getBool(_keyOnboarding) ?? false;
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;

    _autoScrollSpeed = prefs.getDouble(_keyAutoScrollSpeed) ?? 30.0;
    _quranThemeMode = prefs.getString(_keyQuranThemeMode) ?? (_isDarkMode ? 'dark' : 'light');
    _quranFontFamily = prefs.getString(_keyQuranFontFamily) ?? 'Amiri';
    _quranViewMode = prefs.getString(_keyQuranViewMode) ?? 'page';
    _showTranslation = prefs.getBool(_keyShowTranslation) ?? true;

    _periodicDhikrEnabled = prefs.getBool(_keyPeriodicDhikrEnabled) ?? false;
    _periodicDhikrInterval = prefs.getInt(_keyPeriodicDhikrInterval) ?? 60;
    _periodicDhikrType = prefs.getString(_keyPeriodicDhikrType) ?? 'all';
    _periodicDhikrSilenceStart = prefs.getInt(_keyPeriodicDhikrSilenceStart) ?? 22;
    _periodicDhikrSilenceEnd = prefs.getInt(_keyPeriodicDhikrSilenceEnd) ?? 5;
    notifyListeners();
  }

  Future<void> saveReadingPosition({required int page, required int surah, required int ayah}) async {
    _lastPageRead = page;
    _lastSurahRead = surah;
    _lastAyahRead = ayah;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPage, page);
    await prefs.setInt(_keyLastSurah, surah);
    await prefs.setInt(_keyLastAyah, ayah);
  }

  Future<void> saveLastScreen(String screen) async {
    _lastScreen = screen;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastScreen, screen);
  }

  Future<void> saveAudioState({
    required String reciter,
    required int positionMs,
    required int surah,
    required int ayah,
  }) async {
    _lastAudioReciter = reciter;
    _lastAudioPositionMs = positionMs;
    _lastAudioSurah = surah;
    _lastAudioAyah = ayah;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastReciter, reciter);
    await prefs.setInt(_keyLastAudioPos, positionMs);
    await prefs.setInt(_keyLastAudioSurah, surah);
    await prefs.setInt(_keyLastAudioAyah, ayah);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    _quranThemeMode = isDark ? 'dark' : 'light';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
    await prefs.setString(_keyQuranThemeMode, _quranThemeMode);
  }

  Future<void> setQuranThemeMode(String mode) async {
    _quranThemeMode = mode;
    if (mode == 'dark') {
      _isDarkMode = true;
    } else {
      _isDarkMode = false;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuranThemeMode, mode);
    await prefs.setBool(_keyDarkMode, _isDarkMode);
  }

  Future<void> setAutoScrollSpeed(double speed) async {
    _autoScrollSpeed = speed;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAutoScrollSpeed, speed);
  }

  Future<void> setQuranFontFamily(String family) async {
    _quranFontFamily = family;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuranFontFamily, family);
  }

  Future<void> setQuranViewMode(String mode) async {
    _quranViewMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuranViewMode, mode);
  }

  Future<void> setShowTranslation(bool show) async {
    _showTranslation = show;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTranslation, show);
  }

  Future<void> completeOnboarding() async {
    _isOnboardingCompleted = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, true);
  }

  Future<void> toggleNotifications(bool val) async {
    _notificationsEnabled = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, val);
  }

  Future<void> setPeriodicDhikrEnabled(bool val) async {
    _periodicDhikrEnabled = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPeriodicDhikrEnabled, val);

    if (val) {
      await _registerPeriodicTask();
    } else {
      await _cancelPeriodicTask();
    }
  }

  Future<void> setPeriodicDhikrInterval(int val) async {
    _periodicDhikrInterval = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPeriodicDhikrInterval, val);

    if (_periodicDhikrEnabled) {
      await _registerPeriodicTask();
    }
  }

  Future<void> setPeriodicDhikrType(String type) async {
    _periodicDhikrType = type;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPeriodicDhikrType, type);
  }

  Future<void> setPeriodicDhikrSilenceStart(int hour) async {
    _periodicDhikrSilenceStart = hour;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPeriodicDhikrSilenceStart, hour);
  }

  Future<void> setPeriodicDhikrSilenceEnd(int hour) async {
    _periodicDhikrSilenceEnd = hour;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPeriodicDhikrSilenceEnd, hour);
  }

  Future<void> _registerPeriodicTask() async {
    // Disabled to prevent startup crashes on newer Android devices
    debugPrint("Workmanager: _registerPeriodicTask bypassed.");
  }

  Future<void> _cancelPeriodicTask() async {
    // Disabled to prevent startup crashes on newer Android devices
    debugPrint("Workmanager: _cancelPeriodicTask bypassed.");
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await _cancelPeriodicTask();

    _lastPageRead = 1;
    _lastSurahRead = 1;
    _lastAyahRead = 1;
    _lastScreen = 'home';
    _lastAudioReciter = 'عبد الباسط عبد الصمد';
    _lastAudioPositionMs = 0;
    _lastAudioSurah = 1;
    _lastAudioAyah = 1;
    _fontSize = 22.0;
    _isDarkMode = false;
    _isOnboardingCompleted = true; // Keep onboarding completed
    _notificationsEnabled = true;

    _autoScrollSpeed = 30.0;
    _quranThemeMode = 'light';
    _quranFontFamily = 'Amiri';
    _quranViewMode = 'page';
    _showTranslation = true;

    _periodicDhikrEnabled = false;
    _periodicDhikrInterval = 60;
    _periodicDhikrType = 'all';
    _periodicDhikrSilenceStart = 22;
    _periodicDhikrSilenceEnd = 5;

    // Save onboarding completion back to SharedPreferences so onboarding doesn't restart
    await prefs.setBool(_keyOnboarding, true);

    notifyListeners();
  }
}

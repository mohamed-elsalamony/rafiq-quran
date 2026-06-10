import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
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

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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

    // Save onboarding completion back to SharedPreferences so onboarding doesn't restart
    await prefs.setBool(_keyOnboarding, true);

    notifyListeners();
  }
}

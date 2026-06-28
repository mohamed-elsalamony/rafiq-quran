import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

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
  static const String _keyQuranThemeMode =
      'quran_theme_mode'; // 'light', 'dark', 'sepia'
  static const String _keyQuranFontFamily =
      'quran_font_family'; // 'Amiri', 'Scheherazade'
  static const String _keyQuranViewMode = 'quran_view_mode'; // 'page', 'verse'
  static const String _keyQuranScrollDirection = 'quran_scroll_direction'; // 'vertical' or 'horizontal'
  static const String _keyShowTranslation = 'show_translation';

  static const String _keyPeriodicDhikrEnabled = 'periodic_dhikr_enabled';
  static const String _keyPeriodicDhikrInterval = 'periodic_dhikr_interval';
  static const String _keyPeriodicDhikrType = 'periodic_dhikr_type';
  static const String _keyPeriodicDhikrSilenceStart =
      'periodic_dhikr_silence_start';
  static const String _keyPeriodicDhikrSilenceEnd =
      'periodic_dhikr_silence_end';

  static const String _keySmartWakeUpHour = 'smart_wakeup_hour';
  static const String _keySmartWakeUpMinute = 'smart_wakeup_minute';
  static const String _keySmartReturnHour = 'smart_return_hour';
  static const String _keySmartReturnMinute = 'smart_return_minute';
  static const String _keySmartSleepHour = 'smart_sleep_hour';
  static const String _keySmartSleepMinute = 'smart_sleep_minute';
  static const String _keySmartWakeUpDelay = 'smart_wakeup_delay';
  static const String _keySmartWakeUpRem1Enabled = 'smart_wakeup_rem1_enabled';
  static const String _keySmartWakeUpRem2Enabled = 'smart_wakeup_rem2_enabled';
  static const String _keySmartReturnRemEnabled = 'smart_return_rem_enabled';
  static const String _keySmartSleepRemEnabled = 'smart_sleep_rem_enabled';
  static const String _keySmartContentType = 'smart_content_type';

  static const String _keyLastProphetStoryId = 'last_prophet_story_id';
  static const String _keyLastProphetChapterId = 'last_prophet_chapter_id';
  static const String _keyLastSeerahEventId = 'last_seerah_event_id';

  static const String _keyLastAldaaWadawaaChapterId =
      'last_aldaa_wadawaa_chapter_id';
  static const String _keyLastCompanionId = 'last_companion_id';
  static const String _keyLastReligiousStoryId = 'last_religious_story_id';

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
  String _quranScrollDirection = 'vertical';
  bool _showTranslation = true;

  bool _periodicDhikrEnabled = false;
  int _periodicDhikrInterval = 60; // 60, 90, 120 minutes
  String _periodicDhikrType = 'all'; // 'verse', 'dhikr', 'hadith', 'all'
  int _periodicDhikrSilenceStart = 22; // 10 PM
  int _periodicDhikrSilenceEnd = 5; // 5 AM

  int _smartWakeUpHour = 8;
  int _smartWakeUpMinute = 15;
  int _smartReturnHour = 17;
  int _smartReturnMinute = 0;
  int _smartSleepHour = 23;
  int _smartSleepMinute = 30;
  int _smartWakeUpDelay = 15;
  bool _smartWakeUpRem1Enabled = true;
  bool _smartWakeUpRem2Enabled = true;
  bool _smartReturnRemEnabled = true;
  bool _smartSleepRemEnabled = true;
  String _smartContentType = 'all'; // 'all', 'verse', 'dhikr', 'hadith'

  int _lastProphetStoryId = 0;
  int _lastProphetChapterId = 0;
  int _lastSeerahEventId = 0;

  int _lastReadAldaaWadawaaChapterId = 0;
  int _lastCompanionId = 0;
  int _lastReadReligiousStoryId = 0;

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
  String get quranScrollDirection => _quranScrollDirection;
  bool get showTranslation => _showTranslation;

  bool get periodicDhikrEnabled => _periodicDhikrEnabled;
  int get periodicDhikrInterval => _periodicDhikrInterval;
  String get periodicDhikrType => _periodicDhikrType;
  int get periodicDhikrSilenceStart => _periodicDhikrSilenceStart;
  int get periodicDhikrSilenceEnd => _periodicDhikrSilenceEnd;

  int get smartWakeUpHour => _smartWakeUpHour;
  int get smartWakeUpMinute => _smartWakeUpMinute;
  int get smartReturnHour => _smartReturnHour;
  int get smartReturnMinute => _smartReturnMinute;
  int get smartSleepHour => _smartSleepHour;
  int get smartSleepMinute => _smartSleepMinute;
  int get smartWakeUpDelay => _smartWakeUpDelay;
  bool get smartWakeUpRem1Enabled => _smartWakeUpRem1Enabled;
  bool get smartWakeUpRem2Enabled => _smartWakeUpRem2Enabled;
  bool get smartReturnRemEnabled => _smartReturnRemEnabled;
  bool get smartSleepRemEnabled => _smartSleepRemEnabled;
  String get smartContentType => _smartContentType;

  int get lastProphetStoryId => _lastProphetStoryId;
  int get lastProphetChapterId => _lastProphetChapterId;
  int get lastSeerahEventId => _lastSeerahEventId;

  int get lastReadAldaaWadawaaChapterId => _lastReadAldaaWadawaaChapterId;
  int get lastCompanionId => _lastCompanionId;
  int get lastReadReligiousStoryId => _lastReadReligiousStoryId;

  AppState() {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastPageRead = prefs.getInt(_keyLastPage) ?? 1;
      _lastSurahRead = prefs.getInt(_keyLastSurah) ?? 1;
      _lastAyahRead = prefs.getInt(_keyLastAyah) ?? 1;
      _lastScreen = prefs.getString(_keyLastScreen) ?? 'home';
      _lastAudioReciter =
          prefs.getString(_keyLastReciter) ?? 'عبد الباسط عبد الصمد';
      _lastAudioPositionMs = prefs.getInt(_keyLastAudioPos) ?? 0;
      _lastAudioSurah = prefs.getInt(_keyLastAudioSurah) ?? 1;
      _lastAudioAyah = prefs.getInt(_keyLastAudioAyah) ?? 1;
      _fontSize = prefs.getDouble(_keyFontSize) ?? 22.0;
      _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
      _isOnboardingCompleted = prefs.getBool(_keyOnboarding) ?? false;
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;

      _autoScrollSpeed = prefs.getDouble(_keyAutoScrollSpeed) ?? 30.0;
      _quranThemeMode = prefs.getString(_keyQuranThemeMode) ??
          (_isDarkMode ? 'dark' : 'light');
      _quranFontFamily = prefs.getString(_keyQuranFontFamily) ?? 'Amiri';
      _quranViewMode = prefs.getString(_keyQuranViewMode) ?? 'page';
      _quranScrollDirection = prefs.getString(_keyQuranScrollDirection) ?? 'vertical';
      _showTranslation = prefs.getBool(_keyShowTranslation) ?? true;

      _periodicDhikrEnabled = prefs.getBool(_keyPeriodicDhikrEnabled) ?? false;
      _periodicDhikrInterval = prefs.getInt(_keyPeriodicDhikrInterval) ?? 60;
      _periodicDhikrType = prefs.getString(_keyPeriodicDhikrType) ?? 'all';
      _periodicDhikrSilenceStart =
          prefs.getInt(_keyPeriodicDhikrSilenceStart) ?? 22;
      _periodicDhikrSilenceEnd = prefs.getInt(_keyPeriodicDhikrSilenceEnd) ?? 5;

      _smartWakeUpHour = prefs.getInt(_keySmartWakeUpHour) ?? 8;
      _smartWakeUpMinute = prefs.getInt(_keySmartWakeUpMinute) ?? 15;
      _smartReturnHour = prefs.getInt(_keySmartReturnHour) ?? 17;
      _smartReturnMinute = prefs.getInt(_keySmartReturnMinute) ?? 0;
      _smartSleepHour = prefs.getInt(_keySmartSleepHour) ?? 23;
      _smartSleepMinute = prefs.getInt(_keySmartSleepMinute) ?? 30;
      _smartWakeUpDelay = prefs.getInt(_keySmartWakeUpDelay) ?? 15;
      _smartWakeUpRem1Enabled =
          prefs.getBool(_keySmartWakeUpRem1Enabled) ?? true;
      _smartWakeUpRem2Enabled =
          prefs.getBool(_keySmartWakeUpRem2Enabled) ?? true;
      _smartReturnRemEnabled = prefs.getBool(_keySmartReturnRemEnabled) ?? true;
      _smartSleepRemEnabled = prefs.getBool(_keySmartSleepRemEnabled) ?? true;
      _smartContentType = prefs.getString(_keySmartContentType) ?? 'all';

      _lastProphetStoryId = prefs.getInt(_keyLastProphetStoryId) ?? 0;
      _lastProphetChapterId = prefs.getInt(_keyLastProphetChapterId) ?? 0;
      _lastSeerahEventId = prefs.getInt(_keyLastSeerahEventId) ?? 0;

      _lastReadAldaaWadawaaChapterId =
          prefs.getInt(_keyLastAldaaWadawaaChapterId) ?? 0;
      _lastCompanionId = prefs.getInt(_keyLastCompanionId) ?? 0;
      _lastReadReligiousStoryId = prefs.getInt(_keyLastReligiousStoryId) ?? 0;

      notifyListeners();

      _rescheduleDailyReminder();
      _rescheduleSmartReminders();
    } catch (e) {
      debugPrint("Error loading AppState: $e");
    }
  }

  Future<void> saveReadingPosition(
      {required int page, required int surah, required int ayah}) async {
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

  Future<void> saveProphetReadingPosition(
      {required int storyId, required int chapterId}) async {
    _lastProphetStoryId = storyId;
    _lastProphetChapterId = chapterId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastProphetStoryId, storyId);
    await prefs.setInt(_keyLastProphetChapterId, chapterId);
  }

  Future<void> saveSeerahReadingPosition({required int eventId}) async {
    _lastSeerahEventId = eventId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSeerahEventId, eventId);
  }



  Future<void> saveAldaaWadawaaReadingPosition({required int chapterId}) async {
    _lastReadAldaaWadawaaChapterId = chapterId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastAldaaWadawaaChapterId, chapterId);
  }

  Future<void> saveCompanionReadingPosition({required int companionId}) async {
    _lastCompanionId = companionId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastCompanionId, companionId);
  }

  Future<void> saveReligiousStoryReadingPosition({required int storyId}) async {
    _lastReadReligiousStoryId = storyId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastReligiousStoryId, storyId);
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
    // Sepia mode is only for Quran reader, doesn't affect the whole app dark mode
    if (mode == 'dark') {
      _isDarkMode = true;
    } else if (mode == 'light') {
      _isDarkMode = false;
    }
    // 'sepia' keeps isDarkMode unchanged
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

  Future<void> setQuranScrollDirection(String direction) async {
    _quranScrollDirection = direction;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuranScrollDirection, direction);
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
    if (val) {
      await NotificationService().requestPermission();
    }
    _notificationsEnabled = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, val);

    _rescheduleDailyReminder();
  }

  Future<void> setPeriodicDhikrEnabled(bool val) async {
    if (val) {
      await NotificationService().requestPermission();
    }
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
    try {
      await Workmanager().registerPeriodicTask(
        "periodic_dhikr_task",
        "periodic_dhikr",
        frequency: Duration(minutes: _periodicDhikrInterval),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      debugPrint(
          "Workmanager: Registered periodic task with interval $_periodicDhikrInterval mins.");
    } catch (e) {
      debugPrint("Workmanager registration failed: $e");
    }
  }

  Future<void> _cancelPeriodicTask() async {
    try {
      await Workmanager().cancelByUniqueName("periodic_dhikr_task");
      debugPrint("Workmanager: Cancelled periodic task.");
    } catch (e) {
      debugPrint("Workmanager cancellation failed: $e");
    }
  }

  Future<void> setSmartWakeUpTime(int hour, int minute) async {
    _smartWakeUpHour = hour;
    _smartWakeUpMinute = minute;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySmartWakeUpHour, hour);
    await prefs.setInt(_keySmartWakeUpMinute, minute);

    await _rescheduleSmartReminders();
  }

  Future<void> setSmartReturnTime(int hour, int minute) async {
    _smartReturnHour = hour;
    _smartReturnMinute = minute;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySmartReturnHour, hour);
    await prefs.setInt(_keySmartReturnMinute, minute);

    await _rescheduleSmartReminders();
  }

  Future<void> setSmartSleepTime(int hour, int minute) async {
    _smartSleepHour = hour;
    _smartSleepMinute = minute;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySmartSleepHour, hour);
    await prefs.setInt(_keySmartSleepMinute, minute);

    await _rescheduleSmartReminders();
  }

  Future<void> setSmartWakeUpDelay(int delay) async {
    _smartWakeUpDelay = delay;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySmartWakeUpDelay, delay);

    await _rescheduleSmartReminders();
  }

  Future<void> toggleSmartWakeUpRem1(bool val) async {
    _smartWakeUpRem1Enabled = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartWakeUpRem1Enabled, val);

    await _rescheduleSmartReminders();
  }

  Future<void> toggleSmartWakeUpRem2(bool val) async {
    _smartWakeUpRem2Enabled = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartWakeUpRem2Enabled, val);

    await _rescheduleSmartReminders();
  }

  Future<void> toggleSmartReturnRem(bool val) async {
    _smartReturnRemEnabled = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartReturnRemEnabled, val);

    await _rescheduleSmartReminders();
  }

  Future<void> toggleSmartSleepRem(bool val) async {
    _smartSleepRemEnabled = val;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartSleepRemEnabled, val);

    await _rescheduleSmartReminders();
  }

  Future<void> setSmartContentType(String type) async {
    _smartContentType = type;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySmartContentType, type);

    await _rescheduleSmartReminders();
  }

  Future<void> _rescheduleSmartReminders() async {
    try {
      await NotificationService().scheduleSmartReminders(
        wakeUpHour: _smartWakeUpHour,
        wakeUpMinute: _smartWakeUpMinute,
        returnHour: _smartReturnHour,
        returnMinute: _smartReturnMinute,
        sleepHour: _smartSleepHour,
        sleepMinute: _smartSleepMinute,
        wakeUpDelayMins: _smartWakeUpDelay,
        wakeUpRem1Enabled: _smartWakeUpRem1Enabled,
        wakeUpRem2Enabled: _smartWakeUpRem2Enabled,
        returnRemEnabled: _smartReturnRemEnabled,
        sleepRemEnabled: _smartSleepRemEnabled,
        contentType: _smartContentType,
      );
    } catch (e) {
      debugPrint("Error scheduling smart reminders: $e");
    }
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
    _quranScrollDirection = 'vertical';
    _showTranslation = true;

    _periodicDhikrEnabled = false;
    _periodicDhikrInterval = 60;
    _periodicDhikrType = 'all';
    _periodicDhikrSilenceStart = 22;
    _periodicDhikrSilenceEnd = 5;

    _smartWakeUpHour = 8;
    _smartWakeUpMinute = 15;
    _smartReturnHour = 17;
    _smartReturnMinute = 0;
    _smartSleepHour = 23;
    _smartSleepMinute = 30;
    _smartWakeUpDelay = 15;
    _smartWakeUpRem1Enabled = true;
    _smartWakeUpRem2Enabled = true;
    _smartReturnRemEnabled = true;
    _smartSleepRemEnabled = true;
    _smartContentType = 'all';

    _lastProphetStoryId = 0;
    _lastProphetChapterId = 0;
    _lastSeerahEventId = 0;

    _lastReadAldaaWadawaaChapterId = 0;
    _lastCompanionId = 0;
    _lastReadReligiousStoryId = 0;

    // Save onboarding completion back to SharedPreferences so onboarding doesn't restart
    await prefs.setBool(_keyOnboarding, true);

    notifyListeners();

    _rescheduleDailyReminder();
    _rescheduleSmartReminders();
  }

  Future<void> _rescheduleDailyReminder() async {
    try {
      await NotificationService()
          .scheduleDailyReminder(enabled: _notificationsEnabled);
    } catch (e) {
      debugPrint("Error scheduling daily reminder: $e");
    }
  }
}

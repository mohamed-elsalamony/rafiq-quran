import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DbHelper {
  static const String _keyBookmarks = 'bookmarks';
  static const String _keyTasbihLogs = 'tasbih_logs';
  static const String _keyFavAdhkar = 'fav_adhkar';
  static const String _keyCustomAdhkar = 'custom_adhkar';
  static const String _keyHifzPlans = 'hifz_plans';
  static const String _keyKhatmaPlans = 'khatma_plans';

  // --- العلامات المرجعية (Bookmarks) ---
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyBookmarks);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBookmarks(List<Map<String, dynamic>> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBookmarks, json.encode(bookmarks));
  }

  static Future<void> addBookmark({
    required int page,
    required int surah,
    required int ayah,
    required String label,
    required String surahName,
    String folder = 'العلامات العامة',
  }) async {
    final list = await getBookmarks();
    // تجنب التكرار لنفس الآية
    list.removeWhere((item) => item['surah'] == surah && item['ayah'] == ayah);
    list.add({
      'page': page,
      'surah': surah,
      'ayah': ayah,
      'label': label,
      'surahName': surahName,
      'folder': folder,
      'date': DateTime.now().toIso8601String(),
    });
    await saveBookmarks(list);
  }

  static Future<void> deleteBookmark(int surah, int ayah) async {
    final list = await getBookmarks();
    list.removeWhere((item) => item['surah'] == surah && item['ayah'] == ayah);
    await saveBookmarks(list);
  }

  // --- سجل التسبيح (Tasbih Logs) ---
  static Future<List<Map<String, dynamic>>> getTasbihLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyTasbihLogs);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTasbihLogs(List<Map<String, dynamic>> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTasbihLogs, json.encode(logs));
  }

  static Future<void> addTasbihLog(String dhikrName, int count) async {
    final logs = await getTasbihLogs();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    // البحث عن سجل اليوم لهذا الذكر
    int idx = logs.indexWhere((log) => log['date'] == todayStr && log['dhikr'] == dhikrName);
    if (idx != -1) {
      logs[idx]['count'] = (logs[idx]['count'] ?? 0) + count;
    } else {
      logs.add({
        'date': todayStr,
        'dhikr': dhikrName,
        'count': count,
      });
    }
    await saveTasbihLogs(logs);
  }

  // --- مفضلة الأذكار (Favorite Adhkar) ---
  static Future<List<String>> getFavoriteAdhkar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavAdhkar) ?? [];
  }

  static Future<void> toggleFavoriteAdhkar(String zekrText) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavAdhkar) ?? [];
    if (list.contains(zekrText)) {
      list.remove(zekrText);
    } else {
      list.add(zekrText);
    }
    await prefs.setStringList(_keyFavAdhkar, list);
  }

  // --- الأذكار المخصصة (Custom Adhkar) ---
  static Future<List<Map<String, dynamic>>> getCustomAdhkar() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyCustomAdhkar);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomAdhkar(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomAdhkar, json.encode(list));
  }

  static Future<void> addCustomAdhkar(String text, int targetCount) async {
    final list = await getCustomAdhkar();
    list.add({
      'text': text,
      'target': targetCount,
      'date': DateTime.now().toIso8601String(),
    });
    await saveCustomAdhkar(list);
  }

  static Future<void> deleteCustomAdhkar(int index) async {
    final list = await getCustomAdhkar();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await saveCustomAdhkar(list);
    }
  }

  // --- خطط الحفظ (Hifz Plans) ---
  static Future<List<Map<String, dynamic>>> getHifzPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyHifzPlans);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHifzPlans(List<Map<String, dynamic>> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHifzPlans, json.encode(plans));
  }

  static Future<void> addHifzPlan({
    required String title,
    required int startSurah,
    required int endSurah,
    required int totalAyahs,
    required int dailyTarget,
  }) async {
    final plans = await getHifzPlans();
    plans.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'startSurah': startSurah,
      'endSurah': endSurah,
      'totalAyahs': totalAyahs,
      'dailyTarget': dailyTarget,
      'currentProgress': 0, // عدد الآيات المحفوظة
      'startDate': DateTime.now().toIso8601String(),
      'lastUpdate': DateTime.now().toIso8601String(),
    });
    await saveHifzPlans(plans);
  }

  static Future<void> updateHifzProgress(String planId, int progress) async {
    final plans = await getHifzPlans();
    int idx = plans.indexWhere((plan) => plan['id'] == planId);
    if (idx != -1) {
      plans[idx]['currentProgress'] = progress;
      plans[idx]['lastUpdate'] = DateTime.now().toIso8601String();
      await saveHifzPlans(plans);
    }
  }

  static Future<void> deleteHifzPlan(String planId) async {
    final plans = await getHifzPlans();
    plans.removeWhere((plan) => plan['id'] == planId);
    await saveHifzPlans(plans);
  }

  // --- خطط الختمة (Khatma Plans) ---
  static Future<List<Map<String, dynamic>>> getKhatmaPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyKhatmaPlans);
    if (data == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveKhatmaPlans(List<Map<String, dynamic>> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyKhatmaPlans, json.encode(plans));
  }

  static Future<void> addKhatmaPlan({
    required String title,
    required int daysDuration,
    required int startPage,
    required int endPage,
  }) async {
    final plans = await getKhatmaPlans();
    plans.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'daysDuration': daysDuration,
      'startPage': startPage,
      'endPage': endPage,
      'currentPage': startPage,
      'startDate': DateTime.now().toIso8601String(),
      'lastUpdate': DateTime.now().toIso8601String(),
    });
    await saveKhatmaPlans(plans);
  }

  static Future<void> updateKhatmaProgress(String planId, int currentPage) async {
    final plans = await getKhatmaPlans();
    int idx = plans.indexWhere((plan) => plan['id'] == planId);
    if (idx != -1) {
      plans[idx]['currentPage'] = currentPage;
      plans[idx]['lastUpdate'] = DateTime.now().toIso8601String();
      await saveKhatmaPlans(plans);
    }
  }

  static Future<void> deleteKhatmaPlan(String planId) async {
    final plans = await getKhatmaPlans();
    plans.removeWhere((plan) => plan['id'] == planId);
    await saveKhatmaPlans(plans);
  }
}

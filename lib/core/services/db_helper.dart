import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DbHelper {
  static const String _keyBookmarks = 'bookmarks';
  static const String _keyTasbihLogs = 'tasbih_logs';
  static const String _keyFavAdhkar = 'fav_adhkar';
  static const String _keyCustomAdhkar = 'custom_adhkar';
  static const String _keyHifzPlans = 'hifz_plans';
  static const String _keyKhatmaPlans = 'khatma_plans';

  // Helper safety wrapper to get preferences with error handling
  static Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint("SharedPreferences error: $e");
      return null;
    }
  }

  // --- العلامات المرجعية (Bookmarks) ---
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      final data = prefs.getString(_keyBookmarks);
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      debugPrint("DbHelper getBookmarks error: $e");
      return [];
    }
  }

  static Future<void> saveBookmarks(
      List<Map<String, dynamic>> bookmarks) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setString(_keyBookmarks, json.encode(bookmarks));
    } catch (e) {
      debugPrint("DbHelper saveBookmarks error: $e");
    }
  }

  static Future<void> addBookmark({
    required int page,
    required int surah,
    required int ayah,
    required String label,
    required String surahName,
    String folder = 'العلامات العامة',
  }) async {
    try {
      final list = await getBookmarks();
      // تجنب التكرار لنفس الآية
      list.removeWhere(
          (item) => item['surah'] == surah && item['ayah'] == ayah);
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
    } catch (e) {
      debugPrint("DbHelper addBookmark error: $e");
    }
  }

  static Future<void> deleteBookmark(int surah, int ayah) async {
    try {
      final list = await getBookmarks();
      list.removeWhere(
          (item) => item['surah'] == surah && item['ayah'] == ayah);
      await saveBookmarks(list);
    } catch (e) {
      debugPrint("DbHelper deleteBookmark error: $e");
    }
  }

  // --- سجل التسبيح (Tasbih Logs) ---
  static Future<List<Map<String, dynamic>>> getTasbihLogs() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      final data = prefs.getString(_keyTasbihLogs);
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      debugPrint("DbHelper getTasbihLogs error: $e");
      return [];
    }
  }

  static Future<void> saveTasbihLogs(List<Map<String, dynamic>> logs) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setString(_keyTasbihLogs, json.encode(logs));
    } catch (e) {
      debugPrint("DbHelper saveTasbihLogs error: $e");
    }
  }

  static Future<void> addTasbihLog(String dhikrName, int count) async {
    try {
      final logs = await getTasbihLogs();
      final todayStr =
          DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

      // البحث عن سجل اليوم لهذا الذكر
      int idx = logs.indexWhere(
          (log) => log['date'] == todayStr && log['dhikr'] == dhikrName);
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
    } catch (e) {
      debugPrint("DbHelper addTasbihLog error: $e");
    }
  }

  // --- مفضلة الأذكار (Favorite Adhkar) ---
  static Future<List<String>> getFavoriteAdhkar() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      return prefs.getStringList(_keyFavAdhkar) ?? [];
    } catch (e) {
      debugPrint("DbHelper getFavoriteAdhkar error: $e");
      return [];
    }
  }

  static Future<void> toggleFavoriteAdhkar(String zekrText) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      final list = prefs.getStringList(_keyFavAdhkar) ?? [];
      if (list.contains(zekrText)) {
        list.remove(zekrText);
      } else {
        list.add(zekrText);
      }
      await prefs.setStringList(_keyFavAdhkar, list);
    } catch (e) {
      debugPrint("DbHelper toggleFavoriteAdhkar error: $e");
    }
  }

  // --- الأذكار المخصصة (Custom Adhkar) ---
  static Future<List<Map<String, dynamic>>> getCustomAdhkar() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      final data = prefs.getString(_keyCustomAdhkar);
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      debugPrint("DbHelper getCustomAdhkar error: $e");
      return [];
    }
  }

  static Future<void> saveCustomAdhkar(List<Map<String, dynamic>> list) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setString(_keyCustomAdhkar, json.encode(list));
    } catch (e) {
      debugPrint("DbHelper saveCustomAdhkar error: $e");
    }
  }

  static Future<void> addCustomAdhkar(String text, int targetCount) async {
    try {
      final list = await getCustomAdhkar();
      list.add({
        'text': text,
        'target': targetCount,
        'date': DateTime.now().toIso8601String(),
      });
      await saveCustomAdhkar(list);
    } catch (e) {
      debugPrint("DbHelper addCustomAdhkar error: $e");
    }
  }

  static Future<void> deleteCustomAdhkar(int index) async {
    try {
      final list = await getCustomAdhkar();
      if (index >= 0 && index < list.length) {
        list.removeAt(index);
        await saveCustomAdhkar(list);
      }
    } catch (e) {
      debugPrint("DbHelper deleteCustomAdhkar error: $e");
    }
  }

  // --- خطط الحفظ (Hifz Plans) ---
  static Future<List<Map<String, dynamic>>> getHifzPlans() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      final data = prefs.getString(_keyHifzPlans);
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      debugPrint("DbHelper getHifzPlans error: $e");
      return [];
    }
  }

  static Future<void> saveHifzPlans(List<Map<String, dynamic>> plans) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setString(_keyHifzPlans, json.encode(plans));
    } catch (e) {
      debugPrint("DbHelper saveHifzPlans error: $e");
    }
  }

  static Future<void> addHifzPlan({
    required String title,
    required int startSurah,
    required int endSurah,
    required int totalAyahs,
    required int dailyTarget,
  }) async {
    try {
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
    } catch (e) {
      debugPrint("DbHelper addHifzPlan error: $e");
    }
  }

  static Future<void> updateHifzProgress(String planId, int progress) async {
    try {
      final plans = await getHifzPlans();
      int idx = plans.indexWhere((plan) => plan['id'] == planId);
      if (idx != -1) {
        plans[idx]['currentProgress'] = progress;
        plans[idx]['lastUpdate'] = DateTime.now().toIso8601String();
        await saveHifzPlans(plans);
      }
    } catch (e) {
      debugPrint("DbHelper updateHifzProgress error: $e");
    }
  }

  static Future<void> deleteHifzPlan(String planId) async {
    try {
      final plans = await getHifzPlans();
      plans.removeWhere((plan) => plan['id'] == planId);
      await saveHifzPlans(plans);
    } catch (e) {
      debugPrint("DbHelper deleteHifzPlan error: $e");
    }
  }

  // --- خطط الختمة (Khatma Plans) ---
  static Future<List<Map<String, dynamic>>> getKhatmaPlans() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      final data = prefs.getString(_keyKhatmaPlans);
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      debugPrint("DbHelper getKhatmaPlans error: $e");
      return [];
    }
  }

  static Future<void> saveKhatmaPlans(List<Map<String, dynamic>> plans) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setString(_keyKhatmaPlans, json.encode(plans));
    } catch (e) {
      debugPrint("DbHelper saveKhatmaPlans error: $e");
    }
  }

  static Future<void> addKhatmaPlan({
    required String title,
    required int daysDuration,
    required int startPage,
    required int endPage,
  }) async {
    try {
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
    } catch (e) {
      debugPrint("DbHelper addKhatmaPlan error: $e");
    }
  }

  static Future<void> updateKhatmaProgress(
      String planId, int currentPage) async {
    try {
      final plans = await getKhatmaPlans();
      int idx = plans.indexWhere((plan) => plan['id'] == planId);
      if (idx != -1) {
        plans[idx]['currentPage'] = currentPage;
        plans[idx]['lastUpdate'] = DateTime.now().toIso8601String();
        await saveKhatmaPlans(plans);
      }
    } catch (e) {
      debugPrint("DbHelper updateKhatmaProgress error: $e");
    }
  }

  static Future<void> deleteKhatmaPlan(String planId) async {
    try {
      final plans = await getKhatmaPlans();
      plans.removeWhere((plan) => plan['id'] == planId);
      await saveKhatmaPlans(plans);
    } catch (e) {
      debugPrint("DbHelper deleteKhatmaPlan error: $e");
    }
  }

  static const String _keyKhatmHistory = 'khatm_history';

  // --- سجلات ختم القرآن (Khatm History Logs) ---
  static Future<List<Map<String, dynamic>>> getKhatmHistory() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      final data = prefs.getString(_keyKhatmHistory);
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      debugPrint("DbHelper getKhatmHistory error: $e");
      return [];
    }
  }

  static Future<void> saveKhatmHistory(
      List<Map<String, dynamic>> history) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setString(_keyKhatmHistory, json.encode(history));
    } catch (e) {
      debugPrint("DbHelper saveKhatmHistory error: $e");
    }
  }

  static Future<void> addKhatmLog() async {
    try {
      final history = await getKhatmHistory();
      history.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'date': DateTime.now().toIso8601String(),
      });
      await saveKhatmHistory(history);
    } catch (e) {
      debugPrint("DbHelper addKhatmLog error: $e");
    }
  }

  static Future<void> clearKhatmHistory() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.remove(_keyKhatmHistory);
    } catch (e) {
      debugPrint("DbHelper clearKhatmHistory error: $e");
    }
  }
}

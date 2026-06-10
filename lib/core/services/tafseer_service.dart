import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class TafseerService {
  static List<dynamic>? _cachedTafseer;
  static bool _hasError = false;

  /// Loads and caches the Tafseer data from the JSON asset.
  static Future<void> preloadTafseer() async {
    if (_cachedTafseer != null) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/tafseer.json');
      _cachedTafseer = json.decode(jsonString) as List<dynamic>;
      _hasError = false;
    } catch (e) {
      debugPrint("TafseerService preload error: $e");
      _hasError = true;
    }
  }

  /// Gets the Tafseer text for a specific surah and ayah.
  static Future<String> getTafseer(int surah, int ayah) async {
    try {
      if (_cachedTafseer == null) {
        await preloadTafseer();
      }

      if (_hasError || _cachedTafseer == null) {
        return 'عذراً، حدث خطأ أثناء تحميل ملف التفسير من الأصول المحلية.';
      }

      final item = _cachedTafseer!.firstWhere(
        (element) =>
            element['number'].toString() == surah.toString() &&
            element['aya'].toString() == ayah.toString(),
        orElse: () => null,
      );

      if (item != null && item['text'] != null) {
        return item['text'].toString();
      }

      return 'عذراً، تفسير هذه الآية غير متوفر حالياً.';
    } catch (e) {
      debugPrint("TafseerService getTafseer error: $e");
      return 'حدث خطأ غير متوقع أثناء استرجاع التفسير: $e';
    }
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Hadith {
  final int id;
  final String text;
  final String source;
  final String explanation;
  final String category;

  Hadith({
    required this.id,
    required this.text,
    required this.source,
    required this.explanation,
    required this.category,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as int,
      text: json['text'] as String,
      source: json['source'] as String,
      explanation: json['explanation'] as String,
      category: json['category'] as String,
    );
  }
}

class HadithService {
  static final HadithService _instance = HadithService._internal();
  factory HadithService() => _instance;
  HadithService._internal();

  List<Hadith> _hadiths = [];
  bool _isLoaded = false;

  Future<void> loadHadiths() async {
    if (_isLoaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/hadith.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _hadiths = jsonList.map((json) => Hadith.fromJson(json)).toList();
      _isLoaded = true;
    } catch (e) {
      print("Error loading hadiths: $e");
      // Fallback in case of asset issues during test runs
      _hadiths = [
        Hadith(
            id: 1,
            text:
                "إنَّما الأعْمالُ بالنِّيّاتِ، وإنَّما لِكُلِّ امْرِئٍ ما نَوى.",
            source: "البخاري ومسلم",
            explanation: "النية أساس العمل وقبوله عند الله.",
            category: "Nawawi")
      ];
      _isLoaded = true;
    }
  }

  List<Hadith> getAllHadiths() {
    return _hadiths;
  }

  List<Hadith> getHadithsByCategory(String category) {
    return _hadiths.where((h) => h.category == category).toList();
  }

  List<Hadith> searchHadiths(String query) {
    if (query.isEmpty) return _hadiths;
    final lowerQuery = query.toLowerCase();
    return _hadiths
        .where((h) =>
            h.text.contains(query) ||
            h.explanation.contains(query) ||
            h.source.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<Hadith> getHadithOfDay() async {
    await loadHadiths();
    if (_hadiths.isEmpty) {
      return Hadith(
          id: 1,
          text:
              "لا يُؤْمِنُ أحَدُكُمْ حتَّى يُحِبَّ لأخِيهِ ما يُحِبُّ لِنَفْسِهِ.",
          source: "البخاري ومسلم",
          explanation: "كمال الإيمان في حب الخير للناس.",
          category: "Bukhari");
    }
    // Pick based on day of year
    final int dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _hadiths.length;
    return _hadiths[index];
  }

  // --- Favorite Hadiths State (IDs saved in SharedPreferences) ---
  Future<List<int>> getFavoriteHadithIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('favorite_hadiths') ?? [];
    return list
        .map((idStr) => int.tryParse(idStr) ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  Future<bool> isFavorite(int hadithId) async {
    final favorites = await getFavoriteHadithIds();
    return favorites.contains(hadithId);
  }

  Future<void> toggleFavorite(int hadithId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('favorite_hadiths') ?? [];
    final String idStr = hadithId.toString();

    if (list.contains(idStr)) {
      list.remove(idStr);
    } else {
      list.add(idStr);
    }

    await prefs.setStringList('favorite_hadiths', list);
  }

  Future<List<Hadith>> getFavoriteHadiths() async {
    await loadHadiths();
    final favIds = await getFavoriteHadithIds();
    return _hadiths.where((h) => favIds.contains(h.id)).toList();
  }
}

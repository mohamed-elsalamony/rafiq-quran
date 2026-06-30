import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AldaaWadawaaChapter {
  final int id;
  final String title;
  final String content;
  final int page;

  AldaaWadawaaChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.page,
  });

  factory AldaaWadawaaChapter.fromJson(Map<String, dynamic> json) {
    return AldaaWadawaaChapter(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      page: json['page'] as int,
    );
  }
}

class AldaaWadawaaService {
  static final AldaaWadawaaService _instance = AldaaWadawaaService._internal();
  factory AldaaWadawaaService() => _instance;
  AldaaWadawaaService._internal();

  List<AldaaWadawaaChapter> _chapters = [];
  bool _isLoaded = false;

  Future<void> loadChapters() async {
    if (_isLoaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/aldaa_wadawaa.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _chapters = jsonList
          .map((j) => AldaaWadawaaChapter.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      print("Error loading Aldaa Wadawaa: $e");
      _chapters = [];
      _isLoaded = true;
    }
  }

  List<AldaaWadawaaChapter> getAllChapters() {
    return _chapters;
  }

  AldaaWadawaaChapter? getChapterById(int id) {
    try {
      return _chapters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[َُِّْٰ]'), '') // remove diacritics (harakat)
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  List<AldaaWadawaaChapter> searchChapters(String query) {
    if (query.isEmpty) return _chapters;
    final normalizedQuery = _normalizeArabic(query.trim().toLowerCase());
    return _chapters
        .where((c) =>
            _normalizeArabic(c.title.toLowerCase()).contains(normalizedQuery) ||
            _normalizeArabic(c.content.toLowerCase()).contains(normalizedQuery) ||
            c.page.toString().contains(normalizedQuery))
        .toList();
  }

  // --- Favorite Chapters Persistence ---
  Future<List<int>> getFavoriteChapterIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('favorite_aldaa_chapters') ?? [];
      return list
          .map((idStr) => int.tryParse(idStr) ?? 0)
          .where((id) => id > 0)
          .toList();
    } catch (e) {
      print("Error fetching favorite chapters: $e");
      return [];
    }
  }

  Future<bool> isFavorite(int chapterId) async {
    final favorites = await getFavoriteChapterIds();
    return favorites.contains(chapterId);
  }

  Future<void> toggleFavorite(int chapterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('favorite_aldaa_chapters') ?? [];
      final String idStr = chapterId.toString();

      if (list.contains(idStr)) {
        list.remove(idStr);
      } else {
        list.add(idStr);
      }

      await prefs.setStringList('favorite_aldaa_chapters', list);
    } catch (e) {
      print("Error toggling favorite chapter: $e");
    }
  }

  Future<List<AldaaWadawaaChapter>> getFavoriteChapters() async {
    await loadChapters();
    final favIds = await getFavoriteChapterIds();
    return _chapters.where((c) => favIds.contains(c.id)).toList();
  }
}

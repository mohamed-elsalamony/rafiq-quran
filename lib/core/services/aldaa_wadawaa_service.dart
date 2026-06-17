import 'dart:convert';
import 'package:flutter/services.dart';

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

  List<AldaaWadawaaChapter> searchChapters(String query) {
    if (query.isEmpty) return _chapters;
    return _chapters
        .where((c) =>
            c.title.contains(query) ||
            c.content.contains(query) ||
            c.page.toString().contains(query))
        .toList();
  }
}

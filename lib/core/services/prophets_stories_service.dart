import 'dart:convert';
import 'package:flutter/services.dart';

class ProphetVerse {
  final String text;
  final String surah;
  final String number;

  ProphetVerse({
    required this.text,
    required this.surah,
    required this.number,
  });

  factory ProphetVerse.fromJson(Map<String, dynamic> json) {
    return ProphetVerse(
      text: json['text'] as String,
      surah: json['surah'] as String,
      number: json['number'].toString(),
    );
  }
}

class ProphetChapter {
  final int id;
  final String title;
  final String content;
  final List<ProphetVerse> verses;
  final String source;

  ProphetChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.verses,
    required this.source,
  });

  factory ProphetChapter.fromJson(Map<String, dynamic> json) {
    final versesList = (json['verses'] as List<dynamic>?)
            ?.map((v) => ProphetVerse.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];
    return ProphetChapter(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      verses: versesList,
      source: json['source'] as String,
    );
  }
}

class ProphetStory {
  final int id;
  final String name;
  final String summary;
  final List<ProphetChapter> chapters;

  ProphetStory({
    required this.id,
    required this.name,
    required this.summary,
    required this.chapters,
  });

  factory ProphetStory.fromJson(Map<String, dynamic> json) {
    final chaptersList = (json['chapters'] as List<dynamic>?)
            ?.map((c) => ProphetChapter.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    return ProphetStory(
      id: json['id'] as int,
      name: json['name'] as String,
      summary: json['summary'] as String,
      chapters: chaptersList,
    );
  }
}

class ProphetsStoriesService {
  static final ProphetsStoriesService _instance =
      ProphetsStoriesService._internal();
  factory ProphetsStoriesService() => _instance;
  ProphetsStoriesService._internal();

  List<ProphetStory> _stories = [];
  bool _isLoaded = false;

  Future<void> loadStories() async {
    if (_isLoaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/prophets_stories.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _stories = jsonList
          .map((j) => ProphetStory.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      print("Error loading prophets stories: $e");
      _stories = [];
      _isLoaded = true;
    }
  }

  List<ProphetStory> getAllStories() {
    return _stories;
  }

  ProphetStory? getStoryById(int id) {
    try {
      return _stories.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ProphetStory> searchStories(String query) {
    if (query.isEmpty) return _stories;

    List<ProphetStory> results = [];
    for (var story in _stories) {
      bool matchStory =
          story.name.contains(query) || story.summary.contains(query);
      bool matchChapter = false;

      for (var chapter in story.chapters) {
        if (chapter.title.contains(query) ||
            chapter.content.contains(query) ||
            chapter.source.contains(query)) {
          matchChapter = true;
          break;
        }
      }

      if (matchStory || matchChapter) {
        results.add(story);
      }
    }
    return results;
  }
}

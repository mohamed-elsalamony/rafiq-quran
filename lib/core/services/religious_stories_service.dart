import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReligiousStory {
  final int id;
  final String title;
  final String category;
  final String referenceText;
  final String storyText;
  final String lesson;
  final String source;

  ReligiousStory({
    required this.id,
    required this.title,
    required this.category,
    required this.referenceText,
    required this.storyText,
    required this.lesson,
    required this.source,
  });

  factory ReligiousStory.fromJson(Map<String, dynamic> json) {
    return ReligiousStory(
      id: json['id'] as int,
      title: json['title'] as String,
      category: json['category'] as String,
      referenceText: json['reference_text'] as String,
      storyText: json['story_text'] as String,
      lesson: json['lesson'] as String,
      source: json['source'] as String,
    );
  }
}

class ReligiousStoriesService {
  static final ReligiousStoriesService _instance =
      ReligiousStoriesService._internal();
  factory ReligiousStoriesService() => _instance;
  ReligiousStoriesService._internal();

  List<ReligiousStory> _stories = [];
  bool _isLoaded = false;

  Future<void> loadStories() async {
    if (_isLoaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/religious_stories.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _stories = jsonList
          .map((j) => ReligiousStory.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      debugPrint("Error loading religious stories: $e");
      _stories = [];
      _isLoaded = true;
    }
  }

  List<ReligiousStory> getAllStories() {
    return _stories;
  }

  ReligiousStory? getStoryById(int id) {
    try {
      return _stories.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ReligiousStory> getStoriesByCategory(String category) {
    return _stories.where((s) => s.category == category).toList();
  }

  List<ReligiousStory> searchStories(String query, {String? category}) {
    List<ReligiousStory> sourceList =
        category != null ? getStoriesByCategory(category) : _stories;
    if (query.isEmpty) return sourceList;

    final String queryLower = query.toLowerCase();
    return sourceList
        .where((s) =>
            s.title.toLowerCase().contains(queryLower) ||
            s.storyText.toLowerCase().contains(queryLower) ||
            s.lesson.toLowerCase().contains(queryLower) ||
            s.referenceText.toLowerCase().contains(queryLower))
        .toList();
  }

  ReligiousStory? getStoryOfDay() {
    if (_stories.isEmpty) return null;
    // Calculate story index based on days since epoch to be consistent per day
    final now = DateTime.now();
    final dayIndex = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2026, 1, 1))
        .inDays
        .abs();
    final index = dayIndex % _stories.length;
    return _stories[index];
  }
}

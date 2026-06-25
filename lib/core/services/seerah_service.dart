import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeerahEvent {
  final int id;
  final String stage;
  final String title;
  final String content;
  final String source;
  final List<String> characters;
  final String location;
  final String? hijriDate;
  final List<Map<String, String>>? verses;
  final List<Map<String, String>>? hadiths;
  final List<String>? lessons;

  SeerahEvent({
    required this.id,
    required this.stage,
    required this.title,
    required this.content,
    required this.source,
    required this.characters,
    required this.location,
    this.hijriDate,
    this.verses,
    this.hadiths,
    this.lessons,
  });

  factory SeerahEvent.fromJson(Map<String, dynamic> json) {
    return SeerahEvent(
      id: json['id'] as int,
      stage: json['stage'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      source: json['source'] as String,
      characters: List<String>.from(json['characters'] ?? []),
      location: json['location'] as String? ?? '',
      hijriDate: json['hijriDate'] as String?,
      verses: (json['verses'] as List<dynamic>?)
          ?.map((v) => Map<String, String>.from(v as Map))
          .toList(),
      hadiths: (json['hadiths'] as List<dynamic>?)
          ?.map((h) => Map<String, String>.from(h as Map))
          .toList(),
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((l) => l as String)
          .toList(),
    );
  }
}

class SeerahService {
  static final SeerahService _instance = SeerahService._internal();
  factory SeerahService() => _instance;
  SeerahService._internal();

  List<SeerahEvent> _events = [];
  bool _isLoaded = false;

  Future<void> loadEvents() async {
    if (_isLoaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/prophet_seerah.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _events = jsonList
          .map((j) => SeerahEvent.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      print("Error loading seerah: $e");
      _events = [];
      _isLoaded = true;
    }
  }

  List<SeerahEvent> getAllEvents() {
    return _events;
  }

  List<SeerahEvent> getEventsByStage(String stage) {
    return _events.where((e) => e.stage == stage).toList();
  }

  SeerahEvent? getEventById(int id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<SeerahEvent> searchEvents(String query) {
    if (query.isEmpty) return _events;
    final String lowerQuery = query.toLowerCase();
    return _events
        .where((e) =>
            e.title.contains(query) ||
            e.content.contains(query) ||
            e.source.contains(query) ||
            e.location.contains(query) ||
            e.stage.contains(query) ||
            e.characters.any((c) => c.contains(query)))
        .toList();
  }

  Future<SeerahEvent?> getEventOfDay() async {
    await loadEvents();
    if (_events.isEmpty) return null;
    final int dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _events.length;
    return _events[index];
  }

  // --- Favorite Seerah Events State (IDs saved in SharedPreferences) ---
  Future<List<int>> getFavoriteEventIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('favorite_seerah_events') ?? [];
    return list
        .map((idStr) => int.tryParse(idStr) ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  Future<bool> isFavorite(int eventId) async {
    final favorites = await getFavoriteEventIds();
    return favorites.contains(eventId);
  }

  Future<void> toggleFavorite(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('favorite_seerah_events') ?? [];
    final String idStr = eventId.toString();

    if (list.contains(idStr)) {
      list.remove(idStr);
    } else {
      list.add(idStr);
    }

    await prefs.setStringList('favorite_seerah_events', list);
  }

  Future<List<SeerahEvent>> getFavoriteEvents() async {
    await loadEvents();
    final favIds = await getFavoriteEventIds();
    return _events.where((e) => favIds.contains(e.id)).toList();
  }
}

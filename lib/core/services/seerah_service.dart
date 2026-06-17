import 'dart:convert';
import 'package:flutter/services.dart';

class SeerahEvent {
  final int id;
  final String stage;
  final String title;
  final String content;
  final String source;

  SeerahEvent({
    required this.id,
    required this.stage,
    required this.title,
    required this.content,
    required this.source,
  });

  factory SeerahEvent.fromJson(Map<String, dynamic> json) {
    return SeerahEvent(
      id: json['id'] as int,
      stage: json['stage'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      source: json['source'] as String,
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
    return _events
        .where((e) =>
            e.title.contains(query) ||
            e.content.contains(query) ||
            e.source.contains(query) ||
            e.stage.contains(query))
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
}

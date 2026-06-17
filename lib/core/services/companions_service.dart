import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Companion {
  final int id;
  final String name;
  final List<String> categories;
  final String lineage;
  final String islam;
  final String moments;
  final String virtues;
  final List<String> hadiths;
  final String sources;

  Companion({
    required this.id,
    required this.name,
    required this.categories,
    required this.lineage,
    required this.islam,
    required this.moments,
    required this.virtues,
    required this.hadiths,
    required this.sources,
  });

  factory Companion.fromJson(Map<String, dynamic> json) {
    return Companion(
      id: json['id'] as int,
      name: json['name'] as String,
      categories: List<String>.from(json['categories'] ?? []),
      lineage: json['lineage'] as String,
      islam: json['islam'] as String,
      moments: json['moments'] as String,
      virtues: json['virtues'] as String,
      hadiths: List<String>.from(json['hadiths'] ?? []),
      sources: json['sources'] as String,
    );
  }
}

class CompanionsService {
  static final CompanionsService _instance = CompanionsService._internal();
  factory CompanionsService() => _instance;
  CompanionsService._internal();

  List<Companion> _companions = [];
  bool _isLoaded = false;

  Future<void> loadCompanions() async {
    if (_isLoaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/companions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _companions = jsonList
          .map((j) => Companion.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      debugPrint("Error loading companions: $e");
      _companions = [];
      _isLoaded = true;
    }
  }

  List<Companion> getAllCompanions() {
    return _companions;
  }

  Companion? getCompanionById(int id) {
    try {
      return _companions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Companion> getCompanionsByCategory(String category) {
    return _companions.where((c) => c.categories.contains(category)).toList();
  }

  List<Companion> searchCompanions(String query, {String? category}) {
    List<Companion> sourceList =
        category != null ? getCompanionsByCategory(category) : _companions;
    if (query.isEmpty) return sourceList;

    return sourceList
        .where((c) =>
            c.name.contains(query) ||
            c.lineage.contains(query) ||
            c.islam.contains(query) ||
            c.moments.contains(query) ||
            c.virtues.contains(query))
        .toList();
  }

  Companion? getCompanionOfDay() {
    if (_companions.isEmpty) return null;
    // Calculate companion based on days since epoch to be consistent per day
    final now = DateTime.now();
    final dayIndex = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2026, 1, 1))
        .inDays
        .abs();
    final index = dayIndex % _companions.length;
    return _companions[index];
  }
}

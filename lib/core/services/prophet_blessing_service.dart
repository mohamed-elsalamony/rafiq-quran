import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProphetBlessingService extends ChangeNotifier {
  static const String _keyPersonalCount = 'prophet_blessing_personal_count';
  static const String _keySimulatedGlobalCount = 'prophet_blessing_simulated_global_count';

  int _personalCount = 0;
  int _globalCount = 0; // Default simulated/initial count
  Timer? _simulationTimer;

  int get personalCount => _personalCount;
  int get globalCount => _globalCount;
  bool get isUsingFirebase => false;

  ProphetBlessingService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _personalCount = prefs.getInt(_keyPersonalCount) ?? 0;
      _globalCount = prefs.getInt(_keySimulatedGlobalCount) ?? 0;
      
      // Reset global counter if it contains old huge simulated data
      if (_globalCount > 100000) {
        _globalCount = _personalCount;
        await prefs.setInt(_keySimulatedGlobalCount, _globalCount);
      }
      notifyListeners();
      _startSimulation();
    } catch (e) {
      debugPrint("Error initializing ProphetBlessingService: $e");
      _startSimulation();
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    // Periodically increment global count to simulate multiple users slowly and realistically
    final random = Random();
    _simulationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      // Increment by a random number between 1 and 3
      final increment = random.nextInt(3) + 1;
      _globalCount += increment;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keySimulatedGlobalCount, _globalCount);
    });
  }

  Future<void> increment() async {
    _personalCount++;
    _globalCount++;
    notifyListeners();

    // Save personal count locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPersonalCount, _personalCount);
    await prefs.setInt(_keySimulatedGlobalCount, _globalCount);
  }

  Future<void> resetPersonalCount() async {
    _personalCount = 0;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPersonalCount, 0);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}

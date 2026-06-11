import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ProphetBlessingService extends ChangeNotifier {
  static const String _keyPersonalCount = 'prophet_blessing_personal_count';
  static const String _keySimulatedGlobalCount = 'prophet_blessing_simulated_global_count';

  int _personalCount = 0;
  int _globalCount = 1254320; // Default simulated/initial count
  bool _isUsingFirebase = false;
  Timer? _simulationTimer;
  StreamSubscription? _firestoreSubscription;

  int get personalCount => _personalCount;
  int get globalCount => _globalCount;
  bool get isUsingFirebase => _isUsingFirebase;

  ProphetBlessingService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _personalCount = prefs.getInt(_keyPersonalCount) ?? 0;
    _globalCount = prefs.getInt(_keySimulatedGlobalCount) ?? 1254320;
    notifyListeners();

    // Check if Firebase is initialized
    try {
      if (Firebase.apps.isNotEmpty) {
        _isUsingFirebase = true;
        _listenToGlobalCount();
      } else {
        _startSimulation();
      }
    } catch (e) {
      debugPrint("Error checking Firebase: $e. Using simulation.");
      _startSimulation();
    }
  }

  void _listenToGlobalCount() {
    try {
      final docRef = FirebaseFirestore.instance.collection('campaigns').doc('prophet_blessing');
      _firestoreSubscription = docRef.snapshots().listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['global_count'] != null) {
            _globalCount = data['global_count'] as int;
            notifyListeners();
          }
        } else {
          // Create document if it doesn't exist
          docRef.set({'global_count': 1254320});
        }
      }, onError: (error) {
        debugPrint("Firestore listen error: $error. Falling back to simulation.");
        _startSimulation();
      });
    } catch (e) {
      debugPrint("Firestore setup error: $e. Falling back to simulation.");
      _startSimulation();
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    // Periodically increment global count to simulate multiple users
    final random = Random();
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      // Increment by a random number between 3 and 12
      final increment = random.nextInt(10) + 3;
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

    if (_isUsingFirebase) {
      try {
        final docRef = FirebaseFirestore.instance.collection('campaigns').doc('prophet_blessing');
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) {
            transaction.set(docRef, {'global_count': _globalCount});
          } else {
            final currentGlobal = snapshot.data()?['global_count'] as int? ?? 1254320;
            transaction.update(docRef, {'global_count': currentGlobal + 1});
          }
        });
      } catch (e) {
        debugPrint("Error updating Firestore global count: $e");
        // Save simulated counter since Firestore failed
        await prefs.setInt(_keySimulatedGlobalCount, _globalCount);
      }
    } else {
      await prefs.setInt(_keySimulatedGlobalCount, _globalCount);
    }
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
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}

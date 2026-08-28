import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../services/trip_service.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  int _xp = 0;
  int _level = 1;
  int _tripCount = 0;
  List<String> _badges = [];
  Map<String, int> _missionProgress = {};
  bool _dailyChallengeCompleted = false;

  ThemeMode get themeMode => _themeMode;
  int get xp => _xp;
  int get level => _level;
  int get tripCount => _tripCount;
  List<String> get badges => _badges;
  Map<String, int> get missionProgress => _missionProgress;
  bool get dailyChallengeCompleted => _dailyChallengeCompleted;

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    // Load local mission progress and daily challenge state
    _missionProgress = {
      'gems': prefs.getInt('mission_gems') ?? 2,
      'landmarks': prefs.getInt('mission_landmarks') ?? 1,
      'food': prefs.getInt('mission_food') ?? 3,
      'audio': prefs.getInt('mission_audio') ?? 0,
      'trips': prefs.getInt('mission_trips') ?? 1,
      'translate': prefs.getInt('mission_translate') ?? 2,
    };
    _dailyChallengeCompleted = prefs.getBool('daily_challenge_completed') ?? false;

    if (user != null) {
      final profile = await UserService.instance.getUserProfile(user.uid);
      if (profile != null) {
        _xp = profile.xp;
        _level = profile.level;
        _badges = profile.badges;
      }
      final trips = await TripService.instance.getTrips(user.uid);
      _tripCount = trips.length;
    }
    notifyListeners();
  }

  void toggleTheme(bool dark) {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final updated = await UserService.instance.updateXP(user.uid, amount);
      if (updated != null) {
        _xp = updated.xp;
        _level = updated.level;
        notifyListeners();
      }
    } else {
      _xp += amount;
      _level = UserService.calculateLevel(_xp);
      notifyListeners();
    }
  }

  Future<void> incrementMissionProgress(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final totalMap = {
      'gems': 3,
      'landmarks': 5,
      'food': 3,
      'audio': 1,
      'trips': 2,
      'translate': 5,
    };
    final xpMap = {
      'gems': 200,
      'landmarks': 350,
      'food': 150,
      'audio': 100,
      'trips': 120,
      'translate': 80,
    };

    final total = totalMap[missionId] ?? 0;
    if (total == 0) return;

    final current = _missionProgress[missionId] ?? 0;
    if (current >= total) return; // Already completed

    final newCurrent = current + 1;
    _missionProgress[missionId] = newCurrent;
    await prefs.setInt('mission_$missionId', newCurrent);

    if (newCurrent == total) {
      final xpReward = xpMap[missionId] ?? 0;
      await addXp(xpReward);
    } else {
      notifyListeners();
    }
  }

  Future<void> completeDailyChallenge() async {
    if (_dailyChallengeCompleted) return;
    _dailyChallengeCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_challenge_completed', true);
    await addXp(75);
    notifyListeners();
  }
}

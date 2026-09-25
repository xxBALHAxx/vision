import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class UserService extends ChangeNotifier {
  static const _profileKey = 'user_profile';
  UserProfile? _profile;
  bool _isLoading = true;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasProfile => _profile != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_profileKey);
    if (json != null) {
      _profile = UserProfile.fromJson(jsonDecode(json));
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile(UserProfile profile) async {
    _profile = profile;
    await _save();
    notifyListeners();
  }

  Future<void> addResult(ExerciseResult result) async {
    if (_profile == null) return;
    final newHistory = [..._profile!.history, result];
    int newScore = _profile!.totalScore + result.score;
    int newLevel = _profile!.level;

    // Level up logic
    while (newScore >= newLevel * 1000) {
      newLevel++;
    }

    // Energy consumption (1 per exercise)
    int newEnergy = (_profile!.energy - 1).clamp(0, _profile!.maxEnergy);

    _profile = _profile!.copyWith(
      history: newHistory,
      totalScore: newScore,
      level: newLevel,
      energy: newEnergy,
    );
    await _save();
    notifyListeners();
  }

  Future<void> restoreEnergy() async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(energy: _profile!.maxEnergy);
    await _save();
    notifyListeners();
  }

  /// Best stars for a given exercise
  int bestStars(String exerciseId) {
    if (_profile == null) return 0;
    final results = _profile!.history.where((r) => r.exerciseId == exerciseId);
    if (results.isEmpty) return 0;
    return results.map((r) => r.stars).reduce((a, b) => a > b ? a : b);
  }

  /// Total sessions today
  int get sessionsToday {
    if (_profile == null) return 0;
    final now = DateTime.now();
    return _profile!.history
        .where((r) =>
            r.completedAt.year == now.year &&
            r.completedAt.month == now.month &&
            r.completedAt.day == now.day)
        .length;
  }

  /// Weekly minutes of training
  int get weeklyMinutes {
    if (_profile == null) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final total = _profile!.history
        .where((r) => r.completedAt.isAfter(weekAgo))
        .fold(0, (sum, r) => sum + r.durationSeconds);
    return total ~/ 60;
  }

  Future<void> _save() async {
    if (_profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_profile!.toJson()));
  }
}

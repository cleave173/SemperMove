import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _user;
  bool _isLoading = false;
  List<Achievement> _achievements = [];

  User? get user => _user;
  bool get isLoading => _isLoading;
  List<Achievement> get achievements => _achievements;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_supabaseService.isAuthenticated) {
        _user = await _supabaseService.getProfile();
        // Check and unlock achievements based on current progress
        if (_user != null) {
          await _checkAchievements();
        }
      } else {
        _user = null;
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (!_supabaseService.isAuthenticated) return;
    try {
      _user = await _supabaseService.getProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  Future<void> updateGoals({
    int? stepsGoal,
    int? pushUpsGoal,
    int? squatsGoal,
    int? plankGoal,
    int? waterGoal,
  }) async {
    if (_user == null) return;
    try {
      _user = await _supabaseService.updateGoals(
        stepsGoal: stepsGoal,
        pushUpsGoal: pushUpsGoal,
        squatsGoal: squatsGoal,
        plankGoal: plankGoal,
        waterGoal: waterGoal,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProgress({
    int? dailySteps,
    int? pushUps,
    int? squats,
    int? plankSeconds,
    int? waterMl,
  }) async {
    if (_user == null) return;
    try {
      _user = await _supabaseService.updateProgress(
        dailySteps: dailySteps,
        pushUps: pushUps,
        squats: squats,
        plankSeconds: plankSeconds,
        waterMl: waterMl,
      );
      // Check achievements after progress update
      await _checkAchievements();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Check and unlock achievements, update local list
  Future<void> _checkAchievements() async {
    if (_user == null) return;
    try {
      await _supabaseService.checkAndUnlockAchievements(_user!);
      _achievements = await _supabaseService.getAchievements();
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    if (_user == null) return;
    try {
      await _supabaseService.uploadAvatar(imageFile);
      await refreshUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    _user = null;
    _achievements = [];
    notifyListeners();
  }
}


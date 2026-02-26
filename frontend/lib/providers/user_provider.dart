import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../services/supabase_service.dart';
import '../utils/app_logger.dart';

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
    logger.info('UserProvider', 'Loading user profile...');

    try {
      if (_supabaseService.isAuthenticated) {
        _user = await _supabaseService.getProfile();
        // Проверяем нужен ли сброс ежедневного прогресса
        if (_user != null) {
          logger.info('UserProvider', 'User loaded: ${_user!.username}, steps=${_user!.dailySteps}, pushups=${_user!.pushUps}');
          logger.test('User profile load', true, details: 'username=${_user!.username}');
          await _checkDailyReset();
          await _checkAchievements();
        }
      } else {
        _user = null;
        logger.warning('UserProvider', 'User not authenticated');
      }
    } catch (e) {
      logger.error('UserProvider', 'Failed to load user', e);
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
      logger.action('UserProvider', 'User refreshed', data: {'steps': _user?.dailySteps, 'pushups': _user?.pushUps});
      notifyListeners();
    } catch (e) {
      logger.error('UserProvider', 'Refresh failed', e);
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

  /// Check if we need to reset daily progress (new day)
  Future<void> _checkDailyReset() async {
    if (_user == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = _user!.lastActivityDate;

    logger.info('DailyReset', 'Checking: lastDate=$lastDate, today=$today');

    // Если последняя активность была не сегодня — сбрасываем
    if (lastDate != null && lastDate != today) {
      try {
        logger.action('DailyReset', 'Resetting daily progress', data: {'from': lastDate, 'to': today});
        _user = await _supabaseService.resetDailyProgress();
        logger.test('Daily reset', true, details: 'counters zeroed, history saved');
      } catch (e) {
        logger.error('DailyReset', 'Reset failed', e);
      }
    } else {
      logger.info('DailyReset', 'No reset needed (same day)');
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


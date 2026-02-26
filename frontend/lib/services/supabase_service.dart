import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app;
import '../models/duel.dart';
import '../models/progress_history.dart';
import '../models/achievement.dart';
import '../models/app_notification.dart';
import '../models/friendship.dart';

/// Supabase сервис — замена ApiService + AuthService
class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ==================== AUTH ====================

  String? get currentUserId => _client.auth.currentUser?.id;

  bool get isAuthenticated => _client.auth.currentSession != null;

  Future<app.User> signUp(String email, String username, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.user == null) {
      throw Exception('Ошибка регистрации');
    }

    // If email confirmation is enabled, session will be null
    if (response.session == null) {
      throw const AuthException('confirm_email');
    }

    final userId = response.user!.id;

    // Ждем, пока триггер создаст профиль
    for (int i = 0; i < 5; i++) {
        try {
            final profile = await _client.from('profiles').select().eq('id', userId).single();
            return app.User.fromJson(profile);
        } catch (_) {
            await Future.delayed(const Duration(milliseconds: 500));
        }
    }

    // Если триггер не сработал — создаем вручную
    try {
        final newProfile = await _client
            .from('profiles')
            .insert({
              'id': userId,
              'email': email,
              'username': username,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        return app.User.fromJson(newProfile);
    } catch (e) {
        // Если и тут ошибка — значит профиль уже есть или что-то серьезное
        return app.User(id: userId, email: email, username: username);
    }
  }

  Future<app.User> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Ошибка входа');
    }

    return await ensureProfileExists();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Сброс пароля — отправляет письмо со ссылкой на сброс
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'sempermove://callback',
    );
  }

  // ==================== PROFILE ====================

  /// Ensures a profile row exists in the `profiles` table for the current user.
  /// If the profile doesn't exist (e.g. trigger failed), it creates one
  /// using data from `auth.currentUser`.
  Future<app.User> ensureProfileExists() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) throw Exception('Не авторизован');

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .single();
      return app.User.fromJson(data);
    } on PostgrestException catch (_) {
      // Profile doesn't exist — create it from auth metadata
      final email = authUser.email ?? '';
      final username = authUser.userMetadata?['username'] ?? email.split('@')[0];
      final newProfile = await _client
          .from('profiles')
          .insert({
            'id': authUser.id,
            'email': email,
            'username': username,
          })
          .select()
          .single();
      return app.User.fromJson(newProfile);
    }
  }

  Future<app.User> getProfile() async {
    return await ensureProfileExists();
  }

  Future<app.User> updateProfile(Map<String, dynamic> updates) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return app.User.fromJson(data);
  }

  Future<app.User> updateGoals({
    int? stepsGoal,
    int? pushUpsGoal,
    int? squatsGoal,
    int? plankGoal,
    int? waterGoal,
  }) async {
    final updates = <String, dynamic>{};
    if (stepsGoal != null) updates['steps_goal'] = stepsGoal;
    if (pushUpsGoal != null) updates['push_ups_goal'] = pushUpsGoal;
    if (squatsGoal != null) updates['squats_goal'] = squatsGoal;
    if (plankGoal != null) updates['plank_goal'] = plankGoal;
    if (waterGoal != null) updates['water_goal'] = waterGoal;

    return await updateProfile(updates);
  }

  // ==================== AVATAR ====================

  Future<String> uploadAvatar(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final fileExt = imageFile.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _client.storage
        .from('avatars')
        .upload(filePath, imageFile, fileOptions: const FileOptions(upsert: true));

    final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);

    await updateProfile({'avatar_url': publicUrl});

    return publicUrl;
  }

  // ==================== DAILY RESET ====================

  /// Сбрасывает ежедневный прогресс (шаги, отжимания, приседания, планка, вода)
  /// Перед сбросом сохраняет данные в progress_history за вчера
  Future<app.User> resetDailyProgress() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final profile = await getProfile();
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    // Сохраняем вчерашний прогресс в историю (если есть данные)
    if (profile.dailySteps > 0 || profile.pushUps > 0 || profile.squats > 0 || profile.plankSeconds > 0 || profile.waterMl > 0) {
      try {
        await _client.from('progress_history').upsert({
          'user_id': userId,
          'date': profile.lastActivityDate ?? yesterday,
          'steps': profile.dailySteps,
          'push_ups': profile.pushUps,
          'squats': profile.squats,
          'plank_seconds': profile.plankSeconds,
          'water_ml': profile.waterMl,
        }, onConflict: 'user_id,date');
      } catch (_) {}
    }

    // Сбрасываем счётчики
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await updateProfile({
      'daily_steps': 0,
      'push_ups': 0,
      'squats': 0,
      'plank_seconds': 0,
      'water_ml': 0,
      'last_activity_date': today,
    });
  }

  // ==================== PROGRESS ====================

  Future<app.User> updateProgress({
    int? dailySteps,
    int? pushUps,
    int? squats,
    int? plankSeconds,
    int? waterMl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    // Get current profile
    final profile = await getProfile();

    final updates = <String, dynamic>{};
    if (dailySteps != null) updates['daily_steps'] = dailySteps;
    if (pushUps != null) updates['push_ups'] = pushUps;
    if (squats != null) updates['squats'] = squats;
    if (plankSeconds != null) updates['plank_seconds'] = plankSeconds;
    if (waterMl != null) updates['water_ml'] = waterMl;

    // Streak logic
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = profile.lastActivityDate;

    if (lastDate == null) {
      updates['current_streak'] = 1;
      updates['last_activity_date'] = today;
    } else if (lastDate != today) {
      final last = DateTime.parse(lastDate);
      final now = DateTime.parse(today);
      final diff = now.difference(last).inDays;

      if (diff == 1) {
        updates['current_streak'] = profile.currentStreak + 1;
      } else if (diff > 1) {
        updates['current_streak'] = 1;
      }
      updates['last_activity_date'] = today;
    }

    final updatedUser = await updateProfile(updates);

    // Автоматически записываем в progress_history за сегодня
    try {
      await _client.from('progress_history').upsert({
        'user_id': userId,
        'date': today,
        'steps': updatedUser.dailySteps,
        'push_ups': updatedUser.pushUps,
        'squats': updatedUser.squats,
        'plank_seconds': updatedUser.plankSeconds,
        'water_ml': updatedUser.waterMl,
      }, onConflict: 'user_id,date');
    } catch (_) {
      // Не ломаем основную логику если upsert не прошёл
    }

    return updatedUser;
  }

  // ==================== HISTORY ====================

  Future<List<ProgressHistory>> getProgressHistory() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('progress_history')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: true);

    return (data as List).map((json) => ProgressHistory.fromJson(json)).toList();
  }

  Future<ProgressHistory> addProgressHistory(ProgressHistory history) async {
    final data = await _client
        .from('progress_history')
        .insert(history.toJson())
        .select()
        .single();

    return ProgressHistory.fromJson(data);
  }

  // ==================== DUELS ====================

  Future<Duel> startDuel(String opponentId, String exerciseCategory) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('duels')
        .insert({
          'challenger_id': userId,
          'opponent_id': opponentId,
          'exercise_category': exerciseCategory,
          'status': 'IN_PROGRESS',
          'type': 'SINGLE_CATEGORY',
        })
        .select('*, challenger:profiles!duels_challenger_id_fkey(username), opponent:profiles!duels_opponent_id_fkey(username)')
        .single();

    return Duel.fromJson(data);
  }

  Future<List<Duel>> getActiveDuels() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('duels')
        .select('*, challenger:profiles!duels_challenger_id_fkey(username), opponent:profiles!duels_opponent_id_fkey(username)')
        .eq('status', 'IN_PROGRESS')
        .or('challenger_id.eq.$userId,opponent_id.eq.$userId')
        .order('created_at', ascending: false);

    return (data as List).map((json) => Duel.fromJson(json)).toList();
  }

  Future<List<Duel>> getDuelHistory() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('duels')
        .select('*, challenger:profiles!duels_challenger_id_fkey(username), opponent:profiles!duels_opponent_id_fkey(username)')
        .or('challenger_id.eq.$userId,opponent_id.eq.$userId')
        .order('created_at', ascending: false);

    return (data as List).map((json) => Duel.fromJson(json)).toList();
  }

  Future<Duel> getDuel(int duelId) async {
    final data = await _client
        .from('duels')
        .select('*, challenger:profiles!duels_challenger_id_fkey(username), opponent:profiles!duels_opponent_id_fkey(username)')
        .eq('id', duelId)
        .single();

    return Duel.fromJson(data);
  }

  Future<Duel> updateDuelScores(int duelId, int challengerScore, int opponentScore) async {
    final data = await _client
        .from('duels')
        .update({
          'challenger_score': challengerScore,
          'opponent_score': opponentScore,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', duelId)
        .select('*, challenger:profiles!duels_challenger_id_fkey(username), opponent:profiles!duels_opponent_id_fkey(username)')
        .single();

    return Duel.fromJson(data);
  }

  /// Синхронизирует очки дуэли из профилей участников
  Future<Duel> syncDuelScoresFromProfiles(int duelId) async {
    final duel = await getDuel(duelId);
    final category = duel.exerciseCategory?.toLowerCase() ?? '';

    // Получаем профили обоих участников
    final challengerProfile = await _client.from('profiles').select().eq('id', duel.challengerId).single();
    final opponentProfile = await _client.from('profiles').select().eq('id', duel.opponentId).single();

    int challengerScore = 0;
    int opponentScore = 0;

    switch (category) {
      case 'pushups':
        challengerScore = challengerProfile['push_ups'] ?? 0;
        opponentScore = opponentProfile['push_ups'] ?? 0;
        break;
      case 'squats':
        challengerScore = challengerProfile['squats'] ?? 0;
        opponentScore = opponentProfile['squats'] ?? 0;
        break;
      case 'plank':
        challengerScore = challengerProfile['plank_seconds'] ?? 0;
        opponentScore = opponentProfile['plank_seconds'] ?? 0;
        break;
      case 'steps':
        challengerScore = challengerProfile['daily_steps'] ?? 0;
        opponentScore = opponentProfile['daily_steps'] ?? 0;
        break;
    }

    return await updateDuelScores(duelId, challengerScore, opponentScore);
  }

  Future<Duel> finishDuel(int duelId) async {
    // Get current duel to determine winner
    final duel = await getDuel(duelId);
    String? winner;
    if (duel.challengerScore > duel.opponentScore) {
      winner = duel.challengerUsername;
    } else if (duel.opponentScore > duel.challengerScore) {
      winner = duel.opponentUsername;
    } else {
      winner = 'Ничья';
    }

    final data = await _client
        .from('duels')
        .update({
          'status': 'FINISHED',
          'winner': winner,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', duelId)
        .select('*, challenger:profiles!duels_challenger_id_fkey(username), opponent:profiles!duels_opponent_id_fkey(username)')
        .single();

    return Duel.fromJson(data);
  }

  // ==================== LEADERBOARD ====================

  Future<List<app.User>> getLeaderboard() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('daily_steps', ascending: false);

    return (data as List).map((json) => app.User.fromJson(json)).toList();
  }

  // ==================== USERS (for duels) ====================

  Future<List<app.User>> getAllUsers() async {
    final userId = currentUserId;
    final data = await _client
        .from('profiles')
        .select()
        .neq('id', userId ?? '');

    return (data as List).map((json) => app.User.fromJson(json)).toList();
  }

  // ==================== ACHIEVEMENTS ====================

  Future<List<Achievement>> getAchievements() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('achievements')
        .select()
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);

    return (data as List).map((json) => Achievement.fromJson(json)).toList();
  }

  Future<Achievement> unlockAchievement({
    required String type,
    required String title,
    String? description,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('achievements')
        .upsert({
          'user_id': userId,
          'type': type,
          'title': title,
          'description': description,
        }, onConflict: 'user_id,type')
        .select()
        .single();

    return Achievement.fromJson(data);
  }

  /// Проверяет прогресс и разблокирует достижения
  Future<List<Achievement>> checkAndUnlockAchievements(app.User user) async {
    final unlocked = <Achievement>[];

    final checks = <Map<String, dynamic>>[
      {'condition': user.dailySteps >= 10000, 'type': 'steps_10k', 'title': 'Марафонец', 'desc': '10 000 шагов за день'},
      {'condition': user.pushUps >= 100, 'type': 'pushups_100', 'title': 'Мастер', 'desc': '100 отжиманий'},
      {'condition': user.squats >= 100, 'type': 'squats_100', 'title': 'Атлет', 'desc': '100 приседаний'},
      {'condition': user.plankSeconds >= 300, 'type': 'plank_5min', 'title': 'Железный', 'desc': '5 минут планки'},
      {'condition': user.waterMl >= 2000, 'type': 'water_2l', 'title': 'Водный баланс', 'desc': '2 литра воды'},
      {'condition': user.currentStreak >= 7, 'type': 'streak_7', 'title': 'Неделя огня', 'desc': '7 дней подряд'},
      {'condition': user.currentStreak >= 30, 'type': 'streak_30', 'title': 'Месяц силы', 'desc': '30 дней подряд'},
    ];

    for (final check in checks) {
      if (check['condition'] == true) {
        try {
          final a = await unlockAchievement(
            type: check['type'],
            title: check['title'],
            description: check['desc'],
          );
          unlocked.add(a);
        } catch (_) {}
      }
    }

    return unlocked;
  }

  // ==================== NOTIFICATIONS ====================

  Future<List<AppNotification>> getNotifications() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List).map((json) => AppNotification.fromJson(json)).toList();
  }

  Future<int> getUnreadNotificationCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<AppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    final data = await _client
        .from('notifications')
        .insert({
          'user_id': userId,
          'title': title,
          'message': message,
          'type': type,
          'related_id': relatedId,
        })
        .select()
        .single();

    return AppNotification.fromJson(data);
  }

  // ==================== FRIENDS ====================

  Future<Friendship> sendFriendRequest(String friendId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('friends')
        .insert({
          'user_id': userId,
          'friend_id': friendId,
          'status': 'pending',
        })
        .select('*, friend:profiles!friends_friend_id_fkey(username, avatar_url)')
        .single();

    return Friendship.fromJson(data);
  }

  Future<void> acceptFriendRequest(int friendshipId) async {
    await _client
        .from('friends')
        .update({'status': 'accepted'})
        .eq('id', friendshipId);
  }

  Future<void> rejectFriendRequest(int friendshipId) async {
    await _client
        .from('friends')
        .update({'status': 'rejected'})
        .eq('id', friendshipId);
  }

  Future<List<Friendship>> getFriends() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('friends')
        .select('*, friend:profiles!friends_friend_id_fkey(username, avatar_url)')
        .eq('user_id', userId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    return (data as List).map((json) => Friendship.fromJson(json)).toList();
  }

  Future<List<Friendship>> getPendingFriendRequests() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Не авторизован');

    final data = await _client
        .from('friends')
        .select('*, friend:profiles!friends_user_id_fkey(username, avatar_url)')
        .eq('friend_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List).map((json) => Friendship.fromJson(json)).toList();
  }
}

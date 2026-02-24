/// Модель пользователя
/// Хранит все данные и прогресс пользователя
class User {
  final String? id;
  final String email;
  final String username;
  final String? avatarUrl;
  final int dailySteps;
  final int pushUps;
  final int squats;
  final int plankSeconds;
  final int waterMl;
  // Goals
  final int stepsGoal;
  final int pushUpsGoal;
  final int squatsGoal;
  final int plankGoal;
  final int waterGoal;
  // Streak
  final int currentStreak;
  final String? lastActivityDate;

  User({
    this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.dailySteps = 0,
    this.pushUps = 0,
    this.squats = 0,
    this.plankSeconds = 0,
    this.waterMl = 0,
    this.stepsGoal = 10000,
    this.pushUpsGoal = 100,
    this.squatsGoal = 100,
    this.plankGoal = 300,
    this.waterGoal = 2000,
    this.currentStreak = 0,
    this.lastActivityDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      dailySteps: json['daily_steps'] ?? 0,
      pushUps: json['push_ups'] ?? 0,
      squats: json['squats'] ?? 0,
      plankSeconds: json['plank_seconds'] ?? 0,
      waterMl: json['water_ml'] ?? 0,
      stepsGoal: json['steps_goal'] ?? 10000,
      pushUpsGoal: json['push_ups_goal'] ?? 100,
      squatsGoal: json['squats_goal'] ?? 100,
      plankGoal: json['plank_goal'] ?? 300,
      waterGoal: json['water_goal'] ?? 2000,
      currentStreak: json['current_streak'] ?? 0,
      lastActivityDate: json['last_activity_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'daily_steps': dailySteps,
      'push_ups': pushUps,
      'squats': squats,
      'plank_seconds': plankSeconds,
      'water_ml': waterMl,
      'steps_goal': stepsGoal,
      'push_ups_goal': pushUpsGoal,
      'squats_goal': squatsGoal,
      'plank_goal': plankGoal,
      'water_goal': waterGoal,
      'current_streak': currentStreak,
      'last_activity_date': lastActivityDate,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    int? dailySteps,
    int? pushUps,
    int? squats,
    int? plankSeconds,
    int? waterMl,
    int? stepsGoal,
    int? pushUpsGoal,
    int? squatsGoal,
    int? plankGoal,
    int? waterGoal,
    int? currentStreak,
    String? lastActivityDate,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dailySteps: dailySteps ?? this.dailySteps,
      pushUps: pushUps ?? this.pushUps,
      squats: squats ?? this.squats,
      plankSeconds: plankSeconds ?? this.plankSeconds,
      waterMl: waterMl ?? this.waterMl,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      pushUpsGoal: pushUpsGoal ?? this.pushUpsGoal,
      squatsGoal: squatsGoal ?? this.squatsGoal,
      plankGoal: plankGoal ?? this.plankGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  /// Общий счет активности для лидерборда
  int get activityScore => dailySteps ~/ 100 + pushUps + squats + plankSeconds ~/ 10 + waterMl ~/ 100;
}

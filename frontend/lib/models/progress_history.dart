class ProgressHistory {
  final int? id;
  final String userId;
  final DateTime date;
  final int steps;
  final int pushUps;
  final int squats;
  final int plankSeconds;
  final int waterMl;

  ProgressHistory({
    this.id,
    required this.userId,
    required this.date,
    this.steps = 0,
    this.pushUps = 0,
    this.squats = 0,
    this.plankSeconds = 0,
    this.waterMl = 0,
  });

  factory ProgressHistory.fromJson(Map<String, dynamic> json) {
    return ProgressHistory(
      id: json['id'],
      userId: json['user_id'] ?? '',
      date: DateTime.parse(json['date']),
      steps: json['steps'] ?? 0,
      pushUps: json['push_ups'] ?? 0,
      squats: json['squats'] ?? 0,
      plankSeconds: json['plank_seconds'] ?? 0,
      waterMl: json['water_ml'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'steps': steps,
      'push_ups': pushUps,
      'squats': squats,
      'plank_seconds': plankSeconds,
      'water_ml': waterMl,
    };
  }
}

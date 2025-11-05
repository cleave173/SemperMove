class ProgressHistory {
  final int? id;
  final int userId;
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
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      steps: json['steps'] ?? 0,
      pushUps: json['pushUps'] ?? 0,
      squats: json['squats'] ?? 0,
      plankSeconds: json['plankSeconds'] ?? 0,
      waterMl: json['waterMl'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String().split('T')[0],
      'steps': steps,
      'pushUps': pushUps,
      'squats': squats,
      'plankSeconds': plankSeconds,
      'waterMl': waterMl,
    };
  }
}



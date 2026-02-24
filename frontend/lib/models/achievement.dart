/// Модель достижения
class Achievement {
  final int id;
  final String userId;
  final String type;
  final String title;
  final String? description;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      unlockedAt: DateTime.parse(json['unlocked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
    };
  }
}

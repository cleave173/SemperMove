/// Модель уведомления в приложении
class AppNotification {
  final int id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'duel_invite', 'duel_finished', 'achievement', 'system'
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.relatedId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] ?? false,
      relatedId: json['related_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'related_id': relatedId,
    };
  }
}

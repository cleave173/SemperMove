/// Модель дружбы
class Friendship {
  final int id;
  final String userId;
  final String friendId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  // Joined data
  final String? friendUsername;
  final String? friendAvatarUrl;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.friendUsername,
    this.friendAvatarUrl,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      userId: json['user_id'] ?? '',
      friendId: json['friend_id'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      friendUsername: json['friend']?['username'],
      friendAvatarUrl: json['friend']?['avatar_url'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}

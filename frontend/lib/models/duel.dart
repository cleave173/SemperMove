/// Модель дуэли
/// Описывает соревнование между двумя пользователями
class Duel {
  final int id;
  final String challengerId;
  final String opponentId;
  final String? challengerUsername;
  final String? opponentUsername;
  final String status;
  final String? winner;
  final String? exerciseCategory;
  final int challengerScore;
  final int opponentScore;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Duel({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    this.challengerUsername,
    this.opponentUsername,
    required this.status,
    this.winner,
    this.exerciseCategory,
    this.challengerScore = 0,
    this.opponentScore = 0,
    this.type = 'SINGLE_CATEGORY',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Duel.fromJson(Map<String, dynamic> json) {
    return Duel(
      id: json['id'],
      challengerId: json['challenger_id'] ?? '',
      opponentId: json['opponent_id'] ?? '',
      challengerUsername: json['challenger']?['username'] ?? json['challenger_username'],
      opponentUsername: json['opponent']?['username'] ?? json['opponent_username'],
      status: json['status'] ?? 'IN_PROGRESS',
      winner: json['winner'],
      exerciseCategory: json['exercise_category'],
      challengerScore: json['challenger_score'] ?? 0,
      opponentScore: json['opponent_score'] ?? 0,
      type: json['type'] ?? 'SINGLE_CATEGORY',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isActive => status == 'IN_PROGRESS';
  bool get isFinished => status == 'FINISHED';
}

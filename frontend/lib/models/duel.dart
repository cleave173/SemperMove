class Duel {
  final int id;
  final DuelUser challenger;
  final DuelUser opponent;
  final String status;
  final String? winner;
  final String? exerciseCategory;
  final int? challengerScore;
  final int? opponentScore;
  final String? type;
  final List<String>? exerciseCategories;
  final Map<String, ExerciseScore>? exercises;
  final TotalScores? totalScores;
  final DateTime createdAt;
  final DateTime updatedAt;

  Duel({
    required this.id,
    required this.challenger,
    required this.opponent,
    required this.status,
    this.winner,
    this.exerciseCategory,
    this.challengerScore,
    this.opponentScore,
    this.type,
    this.exerciseCategories,
    this.exercises,
    this.totalScores,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Duel.fromJson(Map<String, dynamic> json) {
    return Duel(
      id: json['id'],
      challenger: DuelUser.fromJson(json['challenger']),
      opponent: DuelUser.fromJson(json['opponent']),
      status: json['status'] ?? 'IN_PROGRESS',
      winner: json['winner'],
      exerciseCategory: json['exerciseCategory'],
      challengerScore: json['challengerScore'],
      opponentScore: json['opponentScore'],
      type: json['type'],
      exerciseCategories: json['exerciseCategories'] != null
          ? List<String>.from(json['exerciseCategories'])
          : null,
      exercises: json['exercises'] != null
          ? (json['exercises'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, ExerciseScore.fromJson(value)))
          : null,
      totalScores: json['totalScores'] != null
          ? TotalScores.fromJson(json['totalScores'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isActive => status == 'IN_PROGRESS';
  bool get isFinished => status == 'FINISHED';
  bool get isSingleCategory => type == 'SINGLE_CATEGORY';
  bool get isMultipleCategories => type == 'MULTIPLE_CATEGORIES';
}

class DuelUser {
  final int id;
  final String username;
  final String email;

  DuelUser({
    required this.id,
    required this.username,
    required this.email,
  });

  factory DuelUser.fromJson(Map<String, dynamic> json) {
    return DuelUser(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ExerciseScore {
  final int challenger;
  final int opponent;

  ExerciseScore({
    required this.challenger,
    required this.opponent,
  });

  factory ExerciseScore.fromJson(Map<String, dynamic> json) {
    return ExerciseScore(
      challenger: json['challenger'] ?? 0,
      opponent: json['opponent'] ?? 0,
    );
  }
}

class TotalScores {
  final int challenger;
  final int opponent;

  TotalScores({
    required this.challenger,
    required this.opponent,
  });

  factory TotalScores.fromJson(Map<String, dynamic> json) {
    return TotalScores(
      challenger: json['challenger'] ?? 0,
      opponent: json['opponent'] ?? 0,
    );
  }
}



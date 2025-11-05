class User {
  final int? id;
  final String email;
  final String username;
  final int dailySteps;
  final int pushUps;
  final int squats;
  final int plankSeconds;
  final int waterMl;

  User({
    this.id,
    required this.email,
    required this.username,
    this.dailySteps = 0,
    this.pushUps = 0,
    this.squats = 0,
    this.plankSeconds = 0,
    this.waterMl = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      dailySteps: json['dailySteps'] ?? 0,
      pushUps: json['pushUps'] ?? 0,
      squats: json['squats'] ?? 0,
      plankSeconds: json['plankSeconds'] ?? 0,
      waterMl: json['waterMl'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'dailySteps': dailySteps,
      'pushUps': pushUps,
      'squats': squats,
      'plankSeconds': plankSeconds,
      'waterMl': waterMl,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? username,
    int? dailySteps,
    int? pushUps,
    int? squats,
    int? plankSeconds,
    int? waterMl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      dailySteps: dailySteps ?? this.dailySteps,
      pushUps: pushUps ?? this.pushUps,
      squats: squats ?? this.squats,
      plankSeconds: plankSeconds ?? this.plankSeconds,
      waterMl: waterMl ?? this.waterMl,
    );
  }
}



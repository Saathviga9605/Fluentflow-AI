class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    this.avatarEmoji = '🗣️',
    this.averageFluencyScore = 0,
    this.totalSessions = 0,
  });

  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final String avatarEmoji;
  final double averageFluencyScore;
  final int totalSessions;

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? photoUrl,
    String? avatarEmoji,
    double? averageFluencyScore,
    int? totalSessions,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      averageFluencyScore: averageFluencyScore ?? this.averageFluencyScore,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'avatarEmoji': avatarEmoji,
      'averageFluencyScore': averageFluencyScore,
      'totalSessions': totalSessions,
    };
  }

  static UserProfile fromJson(Map<dynamic, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? 'anonymous',
      name: json['name'] as String? ?? 'Learner',
      email: json['email'] as String? ?? 'learner@local.dev',
      photoUrl: json['photoUrl'] as String?,
      avatarEmoji: json['avatarEmoji'] as String? ?? '🗣️',
      averageFluencyScore: (json['averageFluencyScore'] as num?)?.toDouble() ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
    );
  }
}

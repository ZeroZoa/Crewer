class Member {
  final int? id;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final double? temperature;
  final List<String>? interests;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Member({
    this.id,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.temperature,
    this.interests,
    this.createdAt,
    this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      username: json['username'] ?? '',
      nickname: json['nickname'],
      avatarUrl: json['avatarUrl'] ?? json['profileImage'],
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      temperature: json['temperature'] != null ? (json['temperature'] as num).toDouble() : null,
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'temperature': temperature,
      'interests': interests,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
} 
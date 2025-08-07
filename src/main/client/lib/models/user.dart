class User {
  final String username;
  final String? nickname;
  final String? profileImage;
  final String? bio;
  final int followersCount;
  final int followingCount;

  User({
    required this.username,
    this.nickname,
    this.profileImage,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      nickname: json['nickname'],
      profileImage: json['profileImage'],
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nickname': nickname,
      'profileImage': profileImage,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }
} 
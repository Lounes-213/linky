class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final String? bio;
  final bool isPro;
  final String referralCode;
  final int views;
  final int score;
  final int referralsCount;
  final int? globalRank;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.bio,
    this.isPro = false,
    required this.referralCode,
    this.views = 0,
    this.score = 0,
    this.referralsCount = 0,
    this.globalRank,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profileImage: json['profile_image'],
      bio: json['bio'],
      isPro: json['is_pro'] == 1 || json['is_pro'] == true,
      referralCode: json['referral_code'],
      views: json['views'] ?? 0,
      score: json['score'] ?? 0,
      referralsCount: json['referrals_count'] ?? 0,
      globalRank: json['global_rank'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_image': profileImage,
      'bio': bio,
      'is_pro': isPro ? 1 : 0,
      'referral_code': referralCode,
    };
  }
}

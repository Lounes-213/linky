class StoryModel {
  final String id;
  final String userId;
  final String? storeId;
  final String mediaUrl;
  final String mediaType;
  final String caption;
  final int duration;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  StoryModel({
    required this.id,
    required this.userId,
    this.storeId,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.caption = '',
    this.duration = 5,
    this.viewsCount = 0,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      storeId: json['store_id'],
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      caption: json['caption'] ?? '',
      duration: json['duration'] ?? 5,
      viewsCount: json['views_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => mediaType == 'video';
}

class StoryGroupModel {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? storeName;
  final List<StoryModel> stories;

  StoryGroupModel({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.storeName,
    required this.stories,
  });

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    return StoryGroupModel(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'],
      storeName: json['store_name'],
      stories: (json['stories'] as List)
          .map((e) => StoryModel.fromJson(e))
          .toList(),
    );
  }

  bool get hasUnviewed => false;
}

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body = '',
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] : {},
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ReviewModel {
  final String id;
  final String userId;
  final String productId;
  final int rating;
  final String title;
  final String comment;
  final List<String> images;
  final bool isVerified;
  final int helpfulCount;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.title = '',
    this.comment = '',
    this.images = const [],
    this.isVerified = false,
    this.helpfulCount = 0,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      rating: json['rating'] ?? 0,
      title: json['title'] ?? '',
      comment: json['comment'] ?? '',
      images: json['images'] is List ? List<String>.from(json['images']) : [],
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      helpfulCount: json['helpful_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
    );
  }
}

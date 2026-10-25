class StoreModel {
  final String id;
  final String ownerId;
  final String name;
  final String slug;
  final String description;
  final String? logoUrl;
  final String? coverUrl;
  final String? category;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final double rating;
  final int totalReviews;
  final int totalFollowers;
  final int totalProducts;
  final bool isActive;
  final bool isVerified;
  final DateTime? createdAt;

  StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description = '',
    this.logoUrl,
    this.coverUrl,
    this.category,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.rating = 0,
    this.totalReviews = 0,
    this.totalFollowers = 0,
    this.totalProducts = 0,
    this.isActive = true,
    this.isVerified = false,
    this.createdAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo_url'],
      coverUrl: json['cover_url'],
      category: json['category'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      totalFollowers: json['total_followers'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'slug': slug,
    'description': description,
    'logo_url': logoUrl,
    'cover_url': coverUrl,
    'category': category,
    'phone': phone,
    'email': email,
    'address': address,
    'city': city,
  };
}

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? imageUrl;
  final int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
      imageUrl: json['image_url'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

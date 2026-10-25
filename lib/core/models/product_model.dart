class ProductModel {
  final String id;
  final String storeId;
  final String? categoryId;
  final String name;
  final String slug;
  final String description;
  final double basePrice;
  final double? discountPrice;
  final String currency;
  final List<String> images;
  final List<String> videos;
  final List<String> tags;
  final int stock;
  final String? sku;
  final bool isActive;
  final bool isFeatured;
  final int totalSold;
  final int totalReviews;
  final double avgRating;
  final DateTime? createdAt;
  final String? storeName;
  final String? storeSlug;
  final String? categoryName;
  final List<ProductVariantModel>? variants;

  ProductModel({
    required this.id,
    required this.storeId,
    this.categoryId,
    required this.name,
    required this.slug,
    this.description = '',
    required this.basePrice,
    this.discountPrice,
    this.currency = 'DA',
    this.images = const [],
    this.videos = const [],
    this.tags = const [],
    this.stock = 0,
    this.sku,
    this.isActive = true,
    this.isFeatured = false,
    this.totalSold = 0,
    this.totalReviews = 0,
    this.avgRating = 0,
    this.createdAt,
    this.storeName,
    this.storeSlug,
    this.categoryName,
    this.variants,
  });

  double get price => discountPrice ?? basePrice;
  double get discountPercent => discountPrice != null && basePrice > 0
      ? ((basePrice - discountPrice!) / basePrice * 100)
      : 0;
  bool get hasDiscount => discountPrice != null && discountPrice! < basePrice;
  String get primaryImage => images.isNotEmpty ? images.first : '';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      storeId: json['store_id'] ?? '',
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      basePrice: (json['base_price'] ?? 0).toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      currency: json['currency'] ?? 'DA',
      images: json['images'] is List
          ? List<String>.from(json['images'])
          : (json['images'] != null ? List<String>.from(List.from([json['images']])) : []),
      videos: json['videos'] is List
          ? List<String>.from(json['videos'])
          : [],
      tags: json['tags'] is List
          ? List<String>.from(json['tags'])
          : [],
      stock: json['stock'] ?? 0,
      sku: json['sku'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      totalSold: json['total_sold'] ?? 0,
      totalReviews: json['total_reviews'] ?? 0,
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      storeName: json['store_name'],
      storeSlug: json['store_slug'],
      categoryName: json['category_name'],
      variants: json['variants'] != null
          ? (json['variants'] as List).map((e) => ProductVariantModel.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'store_id': storeId,
    'category_id': categoryId,
    'name': name,
    'slug': slug,
    'description': description,
    'base_price': basePrice,
    'discount_price': discountPrice,
    'images': images,
    'tags': tags,
    'stock': stock,
  };
}

class ProductVariantModel {
  final String id;
  final String productId;
  final String name;
  final String? sku;
  final String? color;
  final String? colorHex;
  final String? size;
  final double price;
  final double? discountPrice;
  final int stock;
  final String? imageUrl;
  final bool isActive;

  ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.color,
    this.colorHex,
    this.size,
    required this.price,
    this.discountPrice,
    this.stock = 0,
    this.imageUrl,
    this.isActive = true,
  });

  double get finalPrice => discountPrice ?? price;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      sku: json['sku'],
      color: json['color'],
      colorHex: json['color_hex'],
      size: json['size'],
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

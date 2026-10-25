import '../api/api_service.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';

class ApiRepository {
  static final ApiRepository _instance = ApiRepository._internal();
  factory ApiRepository() => _instance;
  ApiRepository._internal();

  final ApiService _api = ApiService();

  // Auth
  Future<String?> login(String email, String password) async {
    final response = await _api.post(
      AppConstants.loginEndpoint,
      body: {'email': email, 'password': password},
    );
    if (response.isSuccess && response.data != null) {
      return response.data!['token'] as String?;
    }
    return null;
  }

  Future<String?> register(
    String email,
    String password,
    String name, {
    String? username,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
    };
    if (username != null) body['username'] = username;

    final response = await _api.post(AppConstants.registerEndpoint, body: body);
    if (response.isSuccess && response.data != null) {
      return response.data!['token'] as String?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> firebaseAuth(
    String firebaseUid, {
    String? email,
    String? name,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{'firebase_uid': firebaseUid};
    if (email != null) body['email'] = email;
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _api.post(
      AppConstants.firebaseAuthEndpoint,
      body: body,
    );
    return response.isSuccess ? response.data : null;
  }

  // Users / Profile
  Future<UserModel?> getProfile() async {
    final response = await _api.get(AppConstants.profileBase);
    if (response.isSuccess && response.data != null) {
      return UserModel.fromJson(response.data!);
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put(AppConstants.profileBase, body: data);
    return response.isSuccess;
  }

  Future<UserModel?> getUserById(String id) async {
    final response = await _api.get('${AppConstants.usersBase}/$id');
    if (response.isSuccess && response.data != null) {
      return UserModel.fromJson(response.data!);
    }
    return null;
  }

  // Stores
  Future<List<StoreModel>> getStores({String? category, int page = 1}) async {
    final params = <String, String>{'page': page.toString()};
    if (category != null) params['category'] = category;

    final response = await _api.get(
      AppConstants.storesBase,
      queryParams: params,
    );
    if (!response.isSuccess || response.data == null) return [];
    return (response.data!['stores'] as List)
        .map((e) => StoreModel.fromJson(e))
        .toList();
  }

  Future<StoreModel?> getStoreBySlug(String slug) async {
    final response = await _api.get('${AppConstants.storesBase}/$slug');
    if (response.isSuccess && response.data != null) {
      return StoreModel.fromJson(response.data!);
    }
    return null;
  }

  Future<StoreModel?> createStore(Map<String, dynamic> data) async {
    final response = await _api.post(AppConstants.storesBase, body: data);
    if (response.isSuccess && response.data != null) {
      return StoreModel.fromJson(response.data!);
    }
    return null;
  }

  Future<bool> followStore(String storeId) async {
    final response = await _api.post(
      '${AppConstants.storesBase}/$storeId/follow',
    );
    return response.isSuccess;
  }

  Future<bool> unfollowStore(String storeId) async {
    final response = await _api.delete(
      '${AppConstants.storesBase}/$storeId/follow',
    );
    return response.isSuccess;
  }

  // Products
  Future<List<ProductModel>> getProducts({
    String? category,
    String? subcategory,
    String? storeId,
    String? query,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStock,
    bool? discounted,
    bool? digital,
    String sort = 'newest',
    int page = 1,
  }) async {
    // /api/products returns empty — use store-specific endpoint when storeId is given
    final params = <String, String>{'sort': sort, 'page': page.toString()};
    if (category != null) params['category'] = category;
    if (subcategory != null) params['subcategory'] = subcategory;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (minRating != null) params['min_rating'] = minRating.toString();
    if (inStock != null) params['in_stock'] = inStock.toString();
    if (discounted != null) params['discounted'] = discounted.toString();
    if (digital != null) params['digital'] = digital.toString();

    final endpoint = storeId != null
        ? '${AppConstants.storesBase}/$storeId/products'
        : AppConstants.productsBase;

    final response = await _api.get(endpoint, queryParams: params);
    if (!response.isSuccess || response.data == null) return [];
    return (response.data!['products'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final response = await _api.get('${AppConstants.productsBase}/$id');
    if (response.isSuccess && response.data != null) {
      return ProductModel.fromJson(response.data!);
    }
    return null;
  }

  // Categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await _api.get(AppConstants.categoriesBase);
    if (!response.isSuccess || response.data == null) return [];
    return (response.data!['categories'] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }

  // Cart
  Future<Map<String, dynamic>?> getCart() async {
    final response = await _api.get(AppConstants.cartBase);
    return response.isSuccess ? response.data : null;
  }

  Future<bool> addToCart(
    String productId, {
    String? variantId,
    int quantity = 1,
  }) async {
    final body = <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };
    if (variantId != null) body['variant_id'] = variantId;

    final response = await _api.post(
      '${AppConstants.cartBase}/items',
      body: body,
    );
    return response.isSuccess;
  }

  Future<bool> updateCartItem(String itemId, int quantity) async {
    final response = await _api.put(
      '${AppConstants.cartBase}/items/$itemId',
      body: {'quantity': quantity},
    );
    return response.isSuccess;
  }

  Future<bool> removeFromCart(String itemId) async {
    final response = await _api.delete(
      '${AppConstants.cartBase}/items/$itemId',
    );
    return response.isSuccess;
  }

  Future<bool> clearCart() async {
    final response = await _api.delete(AppConstants.cartBase);
    return response.isSuccess;
  }

  // Orders
  Future<List<OrderModel>> getOrders({int page = 1}) async {
    final response = await _api.get(
      AppConstants.ordersBase,
      queryParams: {'page': page.toString()},
    );
    if (!response.isSuccess || response.data == null) return [];
    return (response.data!['orders'] as List)
        .map((e) => OrderModel.fromJson(e))
        .toList();
  }

  Future<OrderModel?> getOrderById(String id) async {
    final response = await _api.get('${AppConstants.ordersBase}/$id');
    if (response.isSuccess && response.data != null) {
      return OrderModel.fromJson(response.data!);
    }
    return null;
  }

  Future<OrderModel?> createOrder(Map<String, dynamic> data) async {
    final response = await _api.post(AppConstants.ordersBase, body: data);
    if (response.isSuccess && response.data != null) {
      return OrderModel.fromJson(response.data!);
    }
    return null;
  }

  // Reviews
  Future<List<ReviewModel>> getReviews(String productId, {int page = 1}) async {
    final response = await _api.get(
      '${AppConstants.reviewsBase}/$productId',
      queryParams: {'page': page.toString()},
    );
    if (!response.isSuccess || response.data == null) return [];
    return (response.data!['reviews'] as List)
        .map((e) => ReviewModel.fromJson(e))
        .toList();
  }

  Future<bool> createReview(
    String productId,
    int rating, {
    String? title,
    String? comment,
  }) async {
    final body = <String, dynamic>{'rating': rating};
    if (title != null) body['title'] = title;
    if (comment != null) body['comment'] = comment;

    final response = await _api.post(
      '${AppConstants.reviewsBase}/$productId',
      body: body,
    );
    return response.isSuccess;
  }

  // Stories
  Future<List<StoryGroupModel>> getStories() async {
    final response = await _api.get(AppConstants.storiesBase);
    if (!response.isSuccess || response.data == null) return [];
    return (response.data!['stories'] as List)
        .map((e) => StoryGroupModel.fromJson(e))
        .toList();
  }

  Future<bool> createStory(
    String mediaUrl, {
    String? caption,
    String? storeId,
  }) async {
    final body = <String, dynamic>{'media_url': mediaUrl};
    if (caption != null) body['caption'] = caption;
    if (storeId != null) body['store_id'] = storeId;

    final response = await _api.post(AppConstants.storiesBase, body: body);
    return response.isSuccess;
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await _api.get(
      AppConstants.notificationsBase,
      queryParams: {'page': page.toString()},
    );
    return response.isSuccess ? response.data! : {};
  }

  Future<bool> markNotificationRead(String id) async {
    final response = await _api.put(
      '${AppConstants.notificationsBase}/$id/read',
    );
    return response.isSuccess;
  }

  Future<bool> markAllNotificationsRead() async {
    final response = await _api.put(
      '${AppConstants.notificationsBase}/read-all',
    );
    return response.isSuccess;
  }

  // Search
  Future<Map<String, dynamic>> search(
    String query, {
    String type = 'all',
    int page = 1,
  }) async {
    final response = await _api.get(
      AppConstants.searchBase,
      queryParams: {'q': query, 'type': type, 'page': page.toString()},
    );
    return response.isSuccess ? response.data! : {};
  }

  Future<List<Map<String, dynamic>>> searchSuggestions(String query) async {
    final response = await _api.get(
      '${AppConstants.searchBase}/suggestions',
      queryParams: {'q': query},
    );
    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(
        response.data!['suggestions'] ?? [],
      );
    }
    return [];
  }

  // Upload
  Future<String?> uploadFile(
    List<int> bytes,
    String filename, {
    String folder = 'misc',
  }) async {
    final response = await _api.upload(
      AppConstants.uploadBase,
      bytes,
      filename,
      folder: folder,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!['url'] as String?;
    }
    return null;
  }
}

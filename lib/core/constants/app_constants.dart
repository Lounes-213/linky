class AppConstants {
  static const String appName = 'Linky';

  // API Endpoints
  static const String authBase = '/api/auth';
  static const String usersBase = '/api/users';
  static const String profileBase = '/api/profile';
  static const String storesBase = '/api/stores';
  static const String productsBase = '/api/products';
  static const String categoriesBase = '/api/categories';
  static const String cartBase = '/api/cart';
  static const String ordersBase = '/api/orders';
  static const String reviewsBase = '/api/reviews';
  static const String storiesBase = '/api/stories';
  static const String notificationsBase = '/api/notifications';
  static const String searchBase = '/api/search';
  static const String uploadBase = '/api/upload';
  static const String settingsBase = '/api/settings';

  // Auth endpoints
  static const String loginEndpoint = '$authBase/login';
  static const String registerEndpoint = '$authBase/register';
  static const String firebaseAuthEndpoint = '$authBase/firebase';
  static const String refreshTokenEndpoint = '$authBase/refresh';

  // Store endpoints
  static const String storesEndpoint = '/api/stores';

  // Product endpoints
  static const String productsEndpoint = '/api/products';

  // Wishlist endpoints
  static const String wishlistBase = '/api/wishlist';

  // Story
  static const int storyDuration = 5;
  static const int storyMaxCount = 10;

  // Order statuses
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderPreparing = 'preparing';
  static const String orderShipped = 'shipped';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';

  // Payment methods
  static const String paymentCard = 'card';
  static const String paymentGoldCard = 'gold_card';
  static const String paymentCash = 'cash';
  static const String paymentOoredoo = 'ooredoo';

  // Sort options
  static const String sortNewest = 'newest';
  static const String sortPopular = 'popular';
  static const String sortRating = 'rating';
  static const String sortPriceAsc = 'price_asc';
  static const String sortPriceDesc = 'price_desc';

  // Social platforms
  static const List<String> socialPlatforms = [
    'instagram',
    'tiktok',
    'youtube',
    'facebook',
    'twitter',
    'linkedin',
    'behance',
    'dribbble',
    'whatsapp',
    'snapchat',
    'pinterest',
  ];

  // Product categories (fallback)
  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Mode', 'icon': 'checkroom', 'slug': 'mode'},
    {'name': 'Beauté', 'icon': 'face', 'slug': 'beaute'},
    {'name': 'Électro', 'icon': 'devices', 'slug': 'electro'},
    {'name': 'Maison', 'icon': 'home', 'slug': 'maison'},
    {'name': 'Sport', 'icon': 'fitness_center', 'slug': 'sport'},
    {'name': 'NFT', 'icon': 'token', 'slug': 'nft'},
  ];

  // Regex patterns
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^[0-9]{10}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
}

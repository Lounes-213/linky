class AppConfig {
  static const String appName = 'Linky';
  static const String appVersion = '1.0.0';

  // Cloudflare Workers API
  // Set via: flutter run --dart-define=API_BASE_URL=https://your-worker.workers.dev
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://linky-api.bensebalounes2.workers.dev',
  );

  // Firebase Project ID
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'your-project-id',
  );

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Pagination
  static const int defaultPageSize = 20;
  static const int storyDuration = 5;

  // Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxStoryImages = 10;
  static const int maxProductImages = 8;

  // Delivery
  static const double freeShippingThreshold = 5000;
  static const double defaultShippingCost = 500;
  static const String defaultCurrency = 'DA';
}

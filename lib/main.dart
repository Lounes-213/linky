import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/shared_ui.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/auth_service.dart';
import 'core/api/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/store_screen.dart';
import 'screens/cart_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'widgets/animated_cart_badge.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ApiService().init();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const LinkyApp(),
    ),
  );
}

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode') ?? 'fr';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    notifyListeners();
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => _auth.currentUser != null;

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final token = await _auth.signInWithGoogle();
    _isLoading = false;
    notifyListeners();

    return token != null;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final token = await _auth.signInWithEmail(email, password);
    _isLoading = false;
    notifyListeners();

    return token != null;
  }

  Future<bool> register(
    String email,
    String password,
    String name, {
    String? username,
  }) async {
    _isLoading = true;
    notifyListeners();

    final token = await _auth.registerWithEmail(
      email,
      password,
      name,
      username: username,
    );
    _isLoading = false;
    notifyListeners();

    return token != null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}

class LinkyApp extends StatelessWidget {
  const LinkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
            title: 'Linky',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              final isArabic = localeProvider.locale.languageCode == 'ar';
              return Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isVisible = true;

  final List<Widget> _screens = const [
    HomeScreen(),
    StoreScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification &&
              notification.metrics.axis == Axis.vertical) {
            final delta = notification.scrollDelta ?? 0;
            if (delta > 2 && _isVisible) {
              setState(() => _isVisible = false);
            } else if (delta < -2 && !_isVisible) {
              setState(() => _isVisible = true);
            }
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          physics: const BouncingScrollPhysics(),
          children: _screens,
        ),
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final cartCount = cart.itemCount;
          return AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _isVisible ? Offset.zero : const Offset(0, 1),
            curve: Curves.easeOut,
            child: ClayBottomNav(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled, size: 24),
                  activeIcon: Icon(Icons.home_filled, size: 24),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined, size: 24),
                  activeIcon: Icon(Icons.storefront_rounded, size: 24),
                  label: 'Store',
                ),
                BottomNavigationBarItem(
                  icon: AnimatedCartBadge(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 24),
                        if (cartCount > 0)
                          Positioned(
                            top: -4,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B6B),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  activeIcon: AnimatedCartBadge(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_rounded, size: 24),
                        if (cartCount > 0)
                          Positioned(
                            top: -4,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B6B),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline, size: 24),
                  activeIcon: Icon(Icons.person, size: 24),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

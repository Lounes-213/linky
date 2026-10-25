import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
export 'shared_ui.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get themeData =>
      _isDarkMode ? LinkyTheme.darkTheme : LinkyTheme.lightTheme;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

class LinkyTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      fontFamily: 'Outfit',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C63FF),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1A1D26),
        secondary: Color(0xFF6C63FF),
        error: Color(0xFFFF6B6B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1D26),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Outfit',
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1D26)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Outfit'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Outfit'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6C63FF),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Outfit'),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF6C63FF),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF6C63FF),
        unselectedLabelColor: Color(0xFF6B7280),
        indicatorColor: Color(0xFF6C63FF),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Outfit'),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, fontFamily: 'Outfit'),
        dividerColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: Color(0xFF6C63FF),
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1D2E),
      fontFamily: 'Outfit',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9D97FF),
        onPrimary: Colors.white,
        surface: Color(0xFF242740),
        onSurface: Color(0xFFF0F1F5),
        secondary: Color(0xFF9D97FF),
        error: Color(0xFFFF6B6B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF0F1F5),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Outfit',
        ),
        iconTheme: IconThemeData(color: Color(0xFFF0F1F5)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF242740),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF242740),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF9D97FF), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF6B6F90), fontSize: 14, fontFamily: 'Outfit'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF9D97FF),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Outfit'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF9D97FF),
          side: const BorderSide(color: Color(0xFF363955), width: 1.5),
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Outfit'),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF242740),
        selectedColor: const Color(0xFF9D97FF),
        side: const BorderSide(color: Color(0xFF363955)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF9D97FF),
        unselectedLabelColor: Color(0xFF9CA3C0),
        indicatorColor: Color(0xFF9D97FF),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Outfit'),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, fontFamily: 'Outfit'),
        dividerColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: Color(0xFF9D97FF),
        unselectedItemColor: Color(0xFF6B6F90),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

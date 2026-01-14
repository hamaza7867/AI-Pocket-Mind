import 'package:flutter/material.dart';
import '../utils/theme_utils.dart';

class AppTheme {
  // Use FuturisticTheme colors as base
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FuturisticTheme.backgroundBlack,
    primaryColor: FuturisticTheme.neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: FuturisticTheme.neonCyan, // Cyan Primary
      secondary: FuturisticTheme.neonPurple, // Purple Secondary
      surface: FuturisticTheme.surfaceBlack,
      onSurface: FuturisticTheme.textWhite,
    ),
    // Text Theme
    textTheme: TextTheme(
      bodyLarge: FuturisticTheme.getBodyStyle(true),
      bodyMedium: FuturisticTheme.getBodyStyle(true)
          .copyWith(color: FuturisticTheme.textGray),
      titleLarge: FuturisticTheme.getTitleStyle(true),
    ),
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // Transparent for Glassmorphism
      elevation: 0,
      centerTitle: true,
      titleTextStyle: FuturisticTheme.titleStyle,
      iconTheme: const IconThemeData(color: FuturisticTheme.neonCyan),
    ),
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FuturisticTheme.surfaceBlack,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: FuturisticTheme.neonCyan.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: FuturisticTheme.neonCyan.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FuturisticTheme.neonCyan),
      ),
      hintStyle: TextStyle(color: FuturisticTheme.textGray),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: FuturisticTheme.neonCyan,
      foregroundColor: Colors.black,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: FuturisticTheme.backgroundWhite,
    primaryColor: FuturisticTheme.lightBlue,
    colorScheme: const ColorScheme.light(
      primary: FuturisticTheme.lightBlue, // Dark Teal Primary
      secondary: FuturisticTheme.lightPurple,
      surface: FuturisticTheme.surfaceWhite,
      onSurface: FuturisticTheme.textBlack,
    ),
    textTheme: TextTheme(
      bodyLarge: FuturisticTheme.getBodyStyle(false),
      bodyMedium: FuturisticTheme.getBodyStyle(false)
          .copyWith(color: FuturisticTheme.textDarkGray),
      titleLarge: FuturisticTheme.getTitleStyle(false),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: FuturisticTheme.getTitleStyle(false),
      iconTheme: const IconThemeData(color: FuturisticTheme.lightBlue),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FuturisticTheme.lightBlue),
      ),
      hintStyle: TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: FuturisticTheme.lightBlue,
      foregroundColor: Colors.white,
    ),
  );
}

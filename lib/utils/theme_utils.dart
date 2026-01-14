import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FuturisticTheme {
  // Colors
  static const Color backgroundBlack = Color(0xFF050505);
  static const Color surfaceBlack = Color(0xFF101010);
  static const Color neonCyan = Color(0xFF00FFCC);
  static const Color neonPurple = Color(0xFFD500F9);
  static const Color neonBlue = Color(0xFF2979FF);
  static const Color neonRed = Color(0xFFFF1744); // Added for Live Mode
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color textWhite = Color(0xFFEEEEEE);
  static const Color textGray = Color(0xFFAAAAAA);

  // Light Mode Colors
  static const Color backgroundWhite = Color(0xFFF0F2F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textDarkGray = Color(0xFF424242);
  static const Color lightBlue =
      Color(0xFF00796B); // Dark Teal/Cyan for readability
  static const Color lightPurple = Color(0xFFAA00FF);

  static Color getBackgroundColor(bool isDark) =>
      isDark ? backgroundBlack : backgroundWhite;
  static Color getSurfaceColor(bool isDark) =>
      isDark ? surfaceBlack : surfaceWhite;
  static Color getTextColor(bool isDark) => isDark ? textWhite : textBlack;
  static Color getAccentColor(bool isDark) => isDark ? neonCyan : lightBlue;

  static TextStyle getTitleStyle(bool isDark) => GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark
            ? neonCyan
            : const Color(0xFF00796B), // Dark Teal for Light Mode
        letterSpacing: 1.5,
      );

  static TextStyle getHeaderStyle(bool isDark) => GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark
            ? textWhite
            : const Color(0xFF1A1A1A), // Dark Black for Light Mode
        letterSpacing: 1.0,
      );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonPurple, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getBackgroundGradient(bool isDark) => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050505), Color(0xFF101015)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0F2F5), Color(0xFFE1E5EA)],
        );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x2AFFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle get titleStyle => GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: neonCyan,
        letterSpacing: 1.5,
      );

  static TextStyle getBodyStyle(bool isDark) => GoogleFonts.exo2(
        fontSize: 16,
        color: isDark ? textWhite : textBlack,
        height: 1.4,
      );

  static TextStyle getMonoStyle(bool isDark) => GoogleFonts.shareTechMono(
        fontSize: 14,
        color: isDark ? neonCyan : const Color(0xFF00796B),
      );

  // Backward Compatibility
  static TextStyle get bodyStyle => getBodyStyle(true);
  static TextStyle get monoStyle => getMonoStyle(true);

  static TextStyle get headerStyle => GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textWhite,
        letterSpacing: 2.0,
      );

  static TextStyle get buttonStyle => GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: neonCyan,
      );

  static TextStyle getButtonStyle(bool isDark) => GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: getAccentColor(isDark),
      );

  // Decorations
  static BoxDecoration get glassDecoration => BoxDecoration(
        gradient: glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration getGlassDecoration(bool isDark) => isDark
      ? glassDecoration
      : BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        );

  static BoxDecoration get neonBorderDecoration => BoxDecoration(
          color: surfaceBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: neonCyan.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: neonCyan.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ]);

  static BoxDecoration getNeonBorderDecoration(bool isDark) => BoxDecoration(
          color: getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: getAccentColor(isDark).withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: getAccentColor(isDark).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ]);
}

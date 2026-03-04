import 'package:flutter/material.dart';

class AppTheme {
  // Primary: Deep Forest
  static const Color primaryColor = Color(0xFF3A5A40);
  // Secondary: Moss
  static const Color secondaryColor = Color(0xFF588157);
  // Accent: Soft Gold
  static const Color accentColor = Color(0xFFD4A373);
  // Highlight: Dusty Rose
  static const Color highlightColor = Color(0xFFB56576);
  // Background: Light Linen
  static const Color backgroundColor = Color(0xFFFAF7F2);
  // Text: Deep Mocha
  static const Color textColor = Color(0xFF3A2F2F);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: highlightColor,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: backgroundColor,
      ),
      useMaterial3: true,
    );
  }
}

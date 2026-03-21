import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary: Deep Forest
  static const Color primaryColor = Color(0xFF3A5A40);
  // Secondary: Moss
  static const Color secondaryColor = Color(0xFF588157);
  //Teritary:
  static const Color teritaryColor = Color(0xFF81B622);
  // Accent: Soft Gold
  static const Color accentColor = Color(0xFFD4A373);
  // Highlight: Dusty Rose
  static const Color lightGreen = Color(0xFF9EAF9C);
  static const Color highlightColor = Color(0xFFB56576);
  // Background: Light Linen (Darkened for Neumorphism)
  static const Color backgroundColor = Color(0xFFEBEBDD);
  // Text: Deep Mocha
  static const Color buttonHighlightColor = Color(0xFFFFFFED);
  // Text: Deep Mocha
  static const Color buttonTextColor = Color(0xFF2F3E2E);
  // Text: Deep Mocha
  static const Color textColor = Color(0xFF2F3E2E);
  // Text: Deep Mocha
  static const Color descriptionTextColor = Color(0xFF5A6658);

  // Typography for highlight words
  static TextStyle get highlightTextStyle => GoogleFonts.playfairDisplay(
    color: highlightColor,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: teritaryColor,
        error: highlightColor,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor),
        ),
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

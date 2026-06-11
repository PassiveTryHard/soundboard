// Material package for ThemeData and color definitions
import 'package:flutter/material.dart';

class AppTheme {
  // Our primary accent color — used for buttons, highlights, and icons
  // across both light and dark themes
  static const Color accentColor = Color(0xFF6C63FF); // Purple

  // ── Dark Theme ────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true, // Uses Flutter's latest design system

    // Background colors
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      surface: const Color(0xFF1E1E1E),
    ),

    // Bottom navigation bar styling
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.white38,
    ),

    // Default text styling
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  // ── Light Theme ───────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,

    // Light background colors
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: ColorScheme.light(
      primary: accentColor,
      secondary: accentColor,
      surface: const Color(0xFFFFFFFF),
    ),

    // Bottom navigation bar styling for light mode
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.black38,
    ),

    // Default text styling for light mode
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );
}
import 'package:flutter/material.dart';

class AppTheme {
  // Our primary accent color — used for buttons, highlights, and icons
  static const Color accentColor = Color(0xFF6C63FF); // Purple

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
}
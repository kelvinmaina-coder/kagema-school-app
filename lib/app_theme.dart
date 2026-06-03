import 'package:flutter/material.dart';

class AppTheme {
  // ============ YOUR EXACT COLORS FROM YOUR APP ============
  static const Color primaryTeal = Color(0xFF00ACC1);      // Your primary color
  static const Color primaryDark = Color(0xFF006064);      // Your dark teal
  static const Color backgroundLight = Color(0xFFE0F7FA);  // Your background
  static const Color accentGreen = Color(0xFF4CAF50);
  // Role Colors (for different dashboards)
  static const Color adminColor = Color(0xFF1A237E);
  static const Color teacherColor = Color(0xFF2E7D32);
  static const Color parentColor = Color(0xFF6A1B9A);
  static const Color staffColor = Color(0xFFE65100);
  static const Color accountantColor = Color(0xFF00695C);
  static const Color secretaryColor = Color(0xFFE65100);      // Your hint color
  
  // Gradients (if needed later)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryDark],
  );
  
  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryDark,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryDark,
  );
  
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: Color(0xFF00838F),
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  // Theme Data - USES YOUR EXACT COLORS
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      hintColor: accentGreen,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: accentGreen,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
    );
  }
}


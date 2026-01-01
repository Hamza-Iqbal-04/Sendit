import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Swiggy Instamart Brand Colors
  static const Color swiggyOrange = Color(0xFFFC8019); // Main Swiggy Brand
  static const Color instamartPurple = Color(0xFF9136E6); // The distinctive Instamart gradient start
  static const Color instamartPink = Color(0xFFE535AB); // Gradient end

  static const Color qcGreen = Color(0xFF1B8021); // "Veg" or "Success" green
  static const Color qcGreenLight = Color(0xFFE8F6EA);

  static const Color background = Color(0xFFF4F4F5); // Cool grey background
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E2E7);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1C1C28); // Almost black
  static const Color textSecondary = Color(0xFF555561); // Readable grey
  static const Color textTertiary = Color(0xFF8F90A6);

  static const Color primaryColor = swiggyOrange;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primaryColor,

      // Default font family similar to Proxima Nova (Inter is the closest free alternative)
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
        titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.2),
        titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
        bodyLarge: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        bodyMedium: const TextStyle(color: textSecondary, fontSize: 13, height: 1.4, fontWeight: FontWeight.w400),
        labelSmall: const TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: swiggyOrange,
        surface: surface,
        background: background,
        primary: swiggyOrange,
        secondary: instamartPurple,
        error: const Color(0xFFE53935),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 0.8),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: swiggyOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: swiggyOrange,
          side: const BorderSide(color: swiggyOrange),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
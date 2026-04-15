import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AmarTheme {
  // Light mode colors
  static const Color primary = Color(0xFF00342D);
  static const Color primaryContainer = Color(0xFF004D43);
  static const Color primaryFixed = Color(0xFFA0F2E1);
  static const Color secondary = Color(0xFF3B6663);
  static const Color secondaryContainer = Color(0xFFBBE8E4);
  static const Color secondaryFixed = Color(0xFFBEEBE7);
  
  static const Color surface = Color(0xFFFCF9F8);
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE5E2E1);

  static const Color onSurface = Color(0xFF1C1B1B);
  static const Color onSurfaceVariant = Color(0xFF3F4945);

  static const Color tertiary = Color(0xFF735C00);
  static const Color error = Color(0xFFBA1A1A);
  static const Color outline = Color(0xFF707975);

  // Dark mode colors
  static const Color darkSurface = Color(0xFF0D1B17);
  static const Color darkSurfaceLow = Color(0xFF152019);
  static const Color darkSurfaceLowest = Color(0xFF1C2B24);
  static const Color darkOnSurface = Color(0xFFDDE4E1);
  static const Color darkOnSurfaceVariant = Color(0xFFAAB5B1);

  static TextTheme _buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.bold, fontSize: 28),
      headlineLarge: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w700, fontSize: 24),
      headlineMedium: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w600, fontSize: 20),
      titleLarge: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
      labelLarge: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 10),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        tertiary: tertiary,
        error: error,
      ),
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: primaryFixed,
        primaryContainer: secondary,
        secondary: secondaryFixed,
        secondaryContainer: Color(0xFF2A4E4B),
        surface: darkSurface,
        surfaceContainerLow: darkSurfaceLow,
        surfaceContainerLowest: darkSurfaceLowest,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        tertiary: Color(0xFFFFD966),
        error: Color(0xFFFFB4AB),
      ),
      textTheme: _buildTextTheme(darkOnSurface, darkOnSurfaceVariant),
      cardTheme: CardThemeData(
        color: darkSurfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

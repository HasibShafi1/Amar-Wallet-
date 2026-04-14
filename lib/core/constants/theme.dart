import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AmarTheme {
  // Strict "No-Line" Rule colors
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

  static const Color tertiary = Color(0xFF735C00); // Warm Gold

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
      ),
      textTheme: TextTheme(
        // Editorial Voices (Plus Jakarta Sans)
        displayLarge: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.bold, fontSize: 28),
        headlineLarge: GoogleFonts.plusJakartaSans(color: onSurface, fontWeight: FontWeight.w700, fontSize: 24),
        
        // Workhorse (Inter)
        titleLarge: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: GoogleFonts.inter(color: onSurface, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
        
        // Technical numbers/labels (Manrope)
        labelLarge: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 14),
        labelMedium: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 12),
      ),
      cardTheme: CardTheme(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // "md" to "lg" roundedness
        ),
      ),
    );
  }
}

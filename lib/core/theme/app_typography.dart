import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get darkTextTheme => _buildTextTheme(Colors.white);
  static TextTheme get lightTextTheme =>
      _buildTextTheme(AppColors.textPrimaryLight);

  static TextTheme _buildTextTheme(Color baseColor) {
    // We start with Outfit as the base for everything
    final baseTheme = GoogleFonts.googleSansFlexTextTheme().apply(
      displayColor: baseColor,
      bodyColor: baseColor,
    );

    return baseTheme.copyWith(
      // DISPLAY (Clash Display)
      displayLarge: _clashDisplay(
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      displayMedium: _clashDisplay(
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      displaySmall: _clashDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),

      // HEADLINES (Clash Display)
      headlineLarge: _clashDisplay(
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: _clashDisplay(
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: _clashDisplay(
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),

      // TITLES (Outfit - Geometric, readable)
      titleLarge: _clashDisplay(fontWeight: FontWeight.w600, color: baseColor),
      titleMedium: _clashDisplay(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: baseColor,
      ),
      titleSmall: _clashDisplay(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: baseColor,
      ),

      // BODY (Outfit)
      bodyLarge: GoogleFonts.googleSansFlex(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: baseColor,
        fontFeatures: const [FontFeature.swash(2)],
      ),
      bodyMedium: GoogleFonts.googleSansFlex(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: baseColor,
        fontFeatures: const [FontFeature.swash(2)],
      ),
      bodySmall: GoogleFonts.outfit(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: baseColor.withValues(alpha: 0.7),
      ),

      // LABELS (Outfit - UI Elements)
      labelLarge: GoogleFonts.googleSansFlex(
        fontWeight: FontWeight.w600, // Important for buttons
        letterSpacing: 0.1,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.googleSansFlex(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.googleSansFlex(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: baseColor,
      ),
    );
  }

  // Helper for Custom Font Assets
  static TextStyle _clashDisplay({
    double? fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'ClashDisplay',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      // Ensure height is not wacky for custom fonts
      height: 1.1,
    );
  }
}

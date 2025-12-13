import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_tokens.dart';

/// Typography system for NoctraFit
/// Headings: Space Grotesk (bold, modern)
/// Body: Inter (clean, readable)
class AppTypography {
  AppTypography._();

  /// Get complete TextTheme for the app
  static TextTheme getTextTheme() {
    return TextTheme(
      // ========== Display Styles (Space Grotesk) ==========
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
        letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
        letterSpacing: -0.2,
      ),

      // ========== Headline Styles (Space Grotesk) ==========
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),

      // ========== Title Styles (Space Grotesk for titles) ==========
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),

      // ========== Body Styles (Inter) ==========
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.0,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textSecondary,
        letterSpacing: 0.0,
      ),

      // ========== Label Styles (Inter) ==========
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textPrimary,
        letterSpacing: 0.1,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ColorTokens.textSecondary,
        letterSpacing: 0.1,
      ),
    );
  }

  // ========== Specific Use Case Styles ==========

  /// Large timer/counter style (for session screen)
  static TextStyle timerLarge = GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: ColorTokens.textPrimary,
    letterSpacing: -1.0,
  );

  /// Card title style
  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: 0.0,
  );

  /// Stat value style (large numbers)
  static TextStyle statValue = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.5,
  );

  /// Caption style (smallest text)
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
    letterSpacing: 0.0,
  );

  /// Micro text (very small labels)
  static TextStyle micro = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
    letterSpacing: 0.0,
  );

  /// Button text
  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: 0.2,
  );

  /// Tab label
  static TextStyle tabLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textSecondary,
    letterSpacing: 0.1,
  );
}

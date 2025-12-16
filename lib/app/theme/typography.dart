import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_tokens.dart';

/// Typography system for NoctraFit
/// Headings: Space Grotesk
/// Body: Inter
class AppTypography {
  AppTypography._();

  /// Get complete TextTheme for the app
  ///
  /// Uses ColorTokens facade (kept for backward compatibility).
  /// Make sure AppTheme updates ColorTokens BEFORE calling this.
  static TextTheme getTextTheme() {
    return TextTheme(
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

      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ColorTokens.textPrimary,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
      ),

      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ColorTokens.textPrimary,
      ),

      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ColorTokens.textSecondary,
      ),

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

  // Specific styles (kept as-is, still driven by ColorTokens)

  static TextStyle timerLarge = GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: ColorTokens.textPrimary,
    letterSpacing: -1.0,
  );

  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
  );

  static TextStyle statValue = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
  );

  static TextStyle micro = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle tabLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textSecondary,
    letterSpacing: 0.1,
  );
}

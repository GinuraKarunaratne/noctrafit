import 'package:flutter/material.dart';

/// Color tokens for NoctraFit dark theme
/// CRITICAL: NO blue accents - only luminous green (#C6FF3D)
class ColorTokens {
  // Private constructor to prevent instantiation
  ColorTokens._();

  // ========== Base Palette ==========
  /// Near-black background
  static const Color background = Color(0xFF0B0D10);

  /// Dark surface for cards and elevated elements
  static const Color surface = Color(0xFF12151B);

  /// Border color for subtle outlines
  static const Color border = Color(0xFF1B202A);

  /// Primary text color (light gray)
  static const Color textPrimary = Color(0xFFE8EDF5);

  /// Secondary text color (muted gray)
  static const Color textSecondary = Color(0xFF9AA4B2);

  /// Muted icon color
  static const Color iconMuted = Color(0xFF6F7886);

  // ========== Accent Color (ONLY green, NO blues) ==========
  /// Luminous green accent - the ONLY accent color
  static const Color accent = Color(0xFFC6FF3D);

  // ========== Functional Colors ==========
  /// Success state (green)
  static const Color success = Color(0xFF10B981);

  /// Warning state (orange)
  static const Color warning = Color(0xFFF59E0B);

  /// Error state (red)
  static const Color error = Color(0xFFEF4444);

  /// Info state (cyan - only for informational, not primary accent)
  static const Color info = Color(0xFF06B6D4);

  // ========== Helper Methods ==========
  /// Lighten a color by a percentage (0-100)
  static Color lighten(Color color, int percent) {
    assert(percent >= 0 && percent <= 100);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + (percent / 100)).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken a color by a percentage (0-100)
  static Color darken(Color color, int percent) {
    assert(percent >= 0 && percent <= 100);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - (percent / 100)).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Extension to add lighten/darken methods to Color
extension ColorExtensions on Color {
  Color lighten([int percent = 10]) => ColorTokens.lighten(this, percent);
  Color darken([int percent = 10]) => ColorTokens.darken(this, percent);
}

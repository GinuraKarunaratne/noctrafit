import 'dart:ui';
import 'color_tokens.dart';

/// Accessibility theme modes
enum AccessibilityMode {
  defaultNight,
  deuteranopia, // Red-green color blindness (most common)
  protanopia, // Red-green color blindness (variant)
  tritanopia, // Blue-yellow color blindness
  monochrome, // Black and white only
}

/// Color palettes for different accessibility modes
class AccessibilityPalettes {
  AccessibilityPalettes._();

  /// Get color palette for a specific accessibility mode
  static AccessibilityPalette getPalette(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.defaultNight:
        return _defaultNightPalette;
      case AccessibilityMode.deuteranopia:
        return _deuteranopiaPalette;
      case AccessibilityMode.protanopia:
        return _protanopiaPalette;
      case AccessibilityMode.tritanopia:
        return _tritanopiaPalette;
      case AccessibilityMode.monochrome:
        return _monochromePalette;
    }
  }

  // ========== Default Night Palette ==========
  static const AccessibilityPalette _defaultNightPalette = AccessibilityPalette(
    background: ColorTokens.background,
    surface: ColorTokens.surface,
    border: ColorTokens.border,
    textPrimary: ColorTokens.textPrimary,
    textSecondary: ColorTokens.textSecondary,
    iconMuted: ColorTokens.iconMuted,
    accent: ColorTokens.accent,
    success: ColorTokens.success,
    warning: ColorTokens.warning,
    error: ColorTokens.error,
    info: ColorTokens.info,
  );

  // ========== Deuteranopia (Red-Green Color Blind) ==========
  /// Adjusted palette for deuteranopia (6-8% of males, ~0.5% of females)
  static const AccessibilityPalette _deuteranopiaPalette = AccessibilityPalette(
    background: ColorTokens.background,
    surface: ColorTokens.surface,
    border: ColorTokens.border,
    textPrimary: ColorTokens.textPrimary,
    textSecondary: ColorTokens.textSecondary,
    iconMuted: ColorTokens.iconMuted,
    accent: Color(0xFFFFD700), // Gold instead of green
    success: Color(0xFF60A5FA), // Blue instead of green
    warning: Color(0xFFFB923C), // Orange (works for most)
    error: Color(0xFFA78BFA), // Purple instead of red
    info: Color(0xFF06B6D4), // Cyan
  );

  // ========== Protanopia (Red-Green Color Blind - Variant) ==========
  /// Adjusted palette for protanopia (1-2% of males)
  static const AccessibilityPalette _protanopiaPalette = AccessibilityPalette(
    background: ColorTokens.background,
    surface: ColorTokens.surface,
    border: ColorTokens.border,
    textPrimary: ColorTokens.textPrimary,
    textSecondary: ColorTokens.textSecondary,
    iconMuted: ColorTokens.iconMuted,
    accent: Color(0xFFFFD700), // Gold instead of green
    success: Color(0xFF3B82F6), // Blue instead of green
    warning: Color(0xFFFBBF24), // Yellow
    error: Color(0xFF8B5CF6), // Purple instead of red
    info: Color(0xFF14B8A6), // Teal
  );

  // ========== Tritanopia (Blue-Yellow Color Blind) ==========
  /// Adjusted palette for tritanopia (0.01% of population)
  static const AccessibilityPalette _tritanopiaPalette = AccessibilityPalette(
    background: ColorTokens.background,
    surface: ColorTokens.surface,
    border: ColorTokens.border,
    textPrimary: ColorTokens.textPrimary,
    textSecondary: ColorTokens.textSecondary,
    iconMuted: ColorTokens.iconMuted,
    accent: Color(0xFFFF6B9D), // Pink instead of green
    success: Color(0xFF34D399), // Aqua green (distinguishable)
    warning: Color(0xFFFF4444), // Red instead of yellow/orange
    error: Color(0xFFDC2626), // Dark red
    info: Color(0xFF10B981), // Emerald
  );

  // ========== Monochrome (Black & White) ==========
  /// Black and white palette - MUST use shapes/borders for active states
  static const AccessibilityPalette _monochromePalette = AccessibilityPalette(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF1A1A1A),
    border: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFAAAAAA),
    iconMuted: Color(0xFF666666),
    accent: Color(0xFFFFFFFF), // White accent
    success: Color(0xFFCCCCCC), // Light gray
    warning: Color(0xFF888888), // Mid gray
    error: Color(0xFF555555), // Dark gray
    info: Color(0xFF999999), // Gray
  );
}

/// Immutable color palette for an accessibility mode
class AccessibilityPalette {
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconMuted;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AccessibilityPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconMuted,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });
}

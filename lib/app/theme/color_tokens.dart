import 'package:flutter/material.dart';

/// Dynamic color tokens exposed as a ThemeExtension so widgets can read
/// `Theme.of(context).extension<AppColorTokens>()` and respond to changes.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
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

  const AppColorTokens({
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

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? iconMuted,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      iconMuted: iconMuted ?? this.iconMuted,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  @override
  String toString() =>
      'AppColorTokens(accent: ${accent.value.toRadixString(16)})';
}

/// Color helpers previously on ColorTokens. Keep as local helpers so other
/// theme code can still call `color.lighten()` / `color.darken()`.
Color _adjustLightness(Color color, int percentChange) {
  final hsl = HSLColor.fromColor(color);
  final newLightness = (hsl.lightness + (percentChange / 100)).clamp(0.0, 1.0);
  return hsl.withLightness(newLightness).toColor();
}

extension ColorExtensions on Color {
  Color lighten([int percent = 10]) => _adjustLightness(this, percent);
  Color darken([int percent = 10]) => _adjustLightness(this, -percent);
}

/// Convenience on BuildContext to access the active tokens instance.
extension AppColorTokensBuildContext on BuildContext {
  AppColorTokens get appColorTokens =>
      Theme.of(this).extension<AppColorTokens>()!;
}

/// Legacy static façade kept to avoid a massive refactor across the codebase.
/// It is updated whenever the theme is built (see `AppTheme.getTheme`).
class ColorTokens {
  /// Always-initialized defaults so callers can safely use ColorTokens.*
  /// even before AppTheme runs.
  static AppColorTokens _current = const AppColorTokens(
    background: Color(0xFF0B0D10),
    surface: Color(0xFF12151B),
    border: Color(0xFF1B202A),
    textPrimary: Color(0xFFE8EDF5),
    textSecondary: Color(0xFF9AA4B2),
    iconMuted: Color(0xFF6F7886),
    accent: Color(0xFFC6FF3D),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF06B6D4),
  );

  /// Called by the theme builder to update the global static values.
  /// NOTE: Public (no underscore) so other files can call it.
  static void setFromAppTokens(AppColorTokens tokens) {
    _current = tokens;
  }

  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get border => _current.border;
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get iconMuted => _current.iconMuted;
  static Color get accent => _current.accent;
  static Color get success => _current.success;
  static Color get warning => _current.warning;
  static Color get error => _current.error;
  static Color get info => _current.info;
}

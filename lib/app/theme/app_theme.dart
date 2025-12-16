import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'accessibility_palettes.dart';
import 'color_tokens.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData getTheme(AccessibilityMode mode) {
    final palette = AccessibilityPalettes.getPalette(mode);

    // Build tokens FIRST
    final appTokens = AppColorTokens(
      background: palette.background,
      surface: palette.surface,
      border: palette.border,
      textPrimary: palette.textPrimary,
      textSecondary: palette.textSecondary,
      iconMuted: palette.iconMuted,
      accent: palette.accent,
      success: palette.success,
      warning: palette.warning,
      error: palette.error,
      info: palette.info,
    );

    // Update legacy facade BEFORE typography is built
    ColorTokens.setFromAppTokens(appTokens);

    final textTheme = AppTypography.getTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,

      // ✅ Extension installed here
      extensions: <ThemeExtension<dynamic>>[appTokens],

      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary: palette.accent,
        onPrimary: palette.background,
        secondary: palette.accent.withValues(alpha: 0.8),
        onSecondary: palette.background,
        tertiary: palette.info,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: palette.error,
        onError: palette.textPrimary,
        outline: palette.border,
        outlineVariant: palette.border.lighten(5),
        surfaceContainerHighest: palette.surface.lighten(5),
        surfaceContainer: palette.surface,
        surfaceContainerLow: palette.surface.darken(5),
      ),

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: palette.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.button,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.iconMuted,
          highlightColor: palette.accent.withValues(alpha: 0.1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: palette.accent),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.tabLabel.copyWith(color: palette.accent);
          }
          return AppTypography.tabLabel.copyWith(color: palette.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: palette.accent, size: 24);
          }
          return IconThemeData(color: palette.iconMuted, size: 24);
        }),
        elevation: 0,
        height: 72,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: palette.accent,
        unselectedLabelColor: palette.textSecondary,
        indicatorColor: palette.accent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTypography.tabLabel,
        unselectedLabelStyle: AppTypography.tabLabel,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        deleteIconColor: palette.textSecondary,
        disabledColor: palette.surface.darken(10),
        selectedColor: palette.accent.withValues(alpha: 0.2),
        secondarySelectedColor: palette.accent.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelSmall!,
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface.lighten(10),
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: palette.accent,
      ),

      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        circularTrackColor: palette.surface,
        linearTrackColor: palette.surface,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.accent;
          return palette.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accent.withValues(alpha: 0.5);
          }
          return palette.surface.lighten(10);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(palette.background),
        side: BorderSide(color: palette.border, width: 2),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.accent;
          return palette.textSecondary;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.surface.lighten(10),
        thumbColor: palette.accent,
        overlayColor: palette.accent.withValues(alpha: 0.2),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 8,
      ),

      iconTheme: IconThemeData(color: palette.iconMuted, size: 24),
      primaryIconTheme: IconThemeData(color: palette.accent, size: 24),
    );
  }
}

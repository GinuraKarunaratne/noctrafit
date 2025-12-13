import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'theme/accessibility_palettes.dart';
import 'router/app_router.dart';
import '../data/local/db/app_database.dart';

/// Main application widget
/// Uses Riverpod for state management and Material 3 theming
class NoctraFitApp extends ConsumerWidget {
  final AppDatabase database;

  const NoctraFitApp({
    super.key,
    required this.database,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Watch accessibility mode provider to switch themes
    // For now, use Default Night mode
    final theme = AppTheme.getTheme(AccessibilityMode.defaultNight);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NoctraFit',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}

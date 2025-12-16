import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'theme/accessibility_palettes.dart';
import 'router/app_router.dart';
import 'providers/service_providers.dart';
import 'providers/repository_providers.dart';
import '../data/local/db/app_database.dart';

/// Main application widget
/// Uses Riverpod for state management and Material 3 theming
class NoctraFitApp extends ConsumerStatefulWidget {
  final AppDatabase database;

  const NoctraFitApp({
    super.key,
    required this.database,
  });

  @override
  ConsumerState<NoctraFitApp> createState() => _NoctraFitAppState();
}

class _NoctraFitAppState extends ConsumerState<NoctraFitApp> {
  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final enabled = await prefs.isTtsEnabled();
    final rate = await prefs.getTtsRate();

    final tts = ref.read(ttsServiceProvider);
    await tts.initialize(enabled: enabled, rate: rate);
  }

  @override
  Widget build(BuildContext context) {
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

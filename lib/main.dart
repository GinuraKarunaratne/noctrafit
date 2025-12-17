import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'data/local/db/app_database.dart';
import 'data/local/seed/seed_loader.dart';

/// Application entry point
/// CRITICAL: Seeds database BEFORE runApp() for offline-first experience
void main() async {
  // Ensure Flutter is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  try {
    // Initialize Firebase (required for Firestore, even if used later)
    await Firebase.initializeApp();
    logger.i('Firebase initialized');
  } catch (e) {
    // Firebase initialization might fail if config missing - OK for development
    logger.w('Firebase initialization failed (OK for offline development)', error: e);
  }

  // Initialize notification service
  try {
    await NotificationService.initialize();
    logger.i('Notification service initialized');
  } catch (e) {
    logger.w('Notification initialization failed', error: e);
  }

  // Initialize database (local-first)
  final db = AppDatabase();
  logger.i('Database initialized');

  // Load seed data if needed (BEFORE UI)
  // This ensures the app has content on first launch without internet
  try {
    final seedLoader = SeedLoader(db);
    final didSeed = await seedLoader.loadSeedDataIfNeeded();
    if (didSeed) {
      logger.i('Seed data loaded successfully (first launch)');
    } else {
      logger.i('Seed data already exists, skipping');
    }
  } catch (e, stack) {
    logger.e('Failed to load seed data', error: e, stackTrace: stack);
    // Don't throw - app should still run even if seed fails
  }

  // Run app with Riverpod for state management
  runApp(
    ProviderScope(
      child: NoctraFitApp(database: db),
    ),
  );
}

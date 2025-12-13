import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/database_provider.dart';
import 'package:noctrafit/core/services/connectivity_service.dart';
import 'package:noctrafit/core/services/sync_service.dart';
import 'package:noctrafit/core/services/tts_service.dart';
import 'package:noctrafit/data/remote/firestore/firestore_client.dart';
import 'package:noctrafit/data/remote/firestore/sets_remote_datasource.dart';
import 'package:noctrafit/data/remote/firestore/user_remote_datasource.dart';

/// Provider for ConnectivityService - monitors network status
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for TtsService - text-to-speech for workout instructions
final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

/// Provider for FirestoreClient - centralized Firestore instance
final firestoreClientProvider = Provider<FirestoreClient>((ref) {
  return FirestoreClient();
});

/// Provider for SetsRemoteDataSource - Firestore operations for sets
final setsRemoteDataSourceProvider = Provider<SetsRemoteDataSource>((ref) {
  final client = ref.watch(firestoreClientProvider);
  return SetsRemoteDataSource(client: client);
});

/// Provider for UserRemoteDataSource - Firestore operations for user data (favorites, schedule, etc.)
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(FirebaseFirestore.instance);
});

/// Provider for SyncService - background synchronization with Firestore
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final remote = ref.watch(setsRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  return SyncService(
    database: db,
    remote: remote,
    connectivity: connectivity,
  );
});

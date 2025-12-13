import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noctrafit/app/providers/auth_provider.dart';
import 'package:noctrafit/app/providers/repository_providers.dart';
import 'package:noctrafit/data/local/db/app_database.dart';

// ========== State Providers (Filter & Sort) ==========

/// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category filter (null = all categories)
/// Options: 'Cardio', 'Strength', 'Flexibility'
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Selected difficulty filter (null = all difficulties)
/// Options: 'Beginner', 'Intermediate', 'Advanced'
final selectedDifficultyProvider = StateProvider<String?>((ref) => null);

/// Sort by option
/// Options: 'recent', 'popular', 'difficulty', 'duration'
final sortByProvider = StateProvider<String>((ref) => 'recent');

// ========== Data Stream Providers ==========

/// App sets (source='seed') - filtered and sorted
final appSetsProvider = StreamProvider<List<WorkoutSet>>((ref) async* {
  final repo = ref.watch(setsRepositoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final difficulty = ref.watch(selectedDifficultyProvider);
  final sortBy = ref.watch(sortByProvider);

  // Use filterAndSearch for real-time filtering
  final sets = await repo.filterAndSearch(
    query: searchQuery.isEmpty ? null : searchQuery,
    source: 'seed',
    category: category?.toLowerCase(),
    difficulty: difficulty?.toLowerCase(),
    sortBy: sortBy,
    ascending: false,
  );

  yield sets;

  // Watch for changes and re-filter
  await for (final _ in repo.watchSetsBySource('seed')) {
    final updatedSets = await repo.filterAndSearch(
      query: searchQuery.isEmpty ? null : searchQuery,
      source: 'seed',
      category: category?.toLowerCase(),
      difficulty: difficulty?.toLowerCase(),
      sortBy: sortBy,
      ascending: false,
    );
    yield updatedSets;
  }
});

/// Community sets (source='community') - filtered and sorted
final communitySetsProvider = StreamProvider<List<WorkoutSet>>((ref) async* {
  final repo = ref.watch(setsRepositoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final difficulty = ref.watch(selectedDifficultyProvider);
  final sortBy = ref.watch(sortByProvider);

  // Use filterAndSearch for real-time filtering
  final sets = await repo.filterAndSearch(
    query: searchQuery.isEmpty ? null : searchQuery,
    source: 'community',
    category: category?.toLowerCase(),
    difficulty: difficulty?.toLowerCase(),
    sortBy: sortBy,
    ascending: false,
  );

  yield sets;

  // Watch for changes and re-filter
  await for (final _ in repo.watchSetsBySource('community')) {
    final updatedSets = await repo.filterAndSearch(
      query: searchQuery.isEmpty ? null : searchQuery,
      source: 'community',
      category: category?.toLowerCase(),
      difficulty: difficulty?.toLowerCase(),
      sortBy: sortBy,
      ascending: false,
    );
    yield updatedSets;
  }
});

/// All sets (no source filter) - filtered and sorted
final allSetsProvider = StreamProvider<List<WorkoutSet>>((ref) async* {
  final repo = ref.watch(setsRepositoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final difficulty = ref.watch(selectedDifficultyProvider);
  final sortBy = ref.watch(sortByProvider);

  // Use filterAndSearch for real-time filtering
  final sets = await repo.filterAndSearch(
    query: searchQuery.isEmpty ? null : searchQuery,
    source: null,
    category: category?.toLowerCase(),
    difficulty: difficulty?.toLowerCase(),
    sortBy: sortBy,
    ascending: false,
  );

  yield sets;

  // Watch for changes and re-filter
  await for (final _ in repo.watchAllSets()) {
    final updatedSets = await repo.filterAndSearch(
      query: searchQuery.isEmpty ? null : searchQuery,
      source: null,
      category: category?.toLowerCase(),
      difficulty: difficulty?.toLowerCase(),
      sortBy: sortBy,
      ascending: false,
    );
    yield updatedSets;
  }
});

/// User favorites from Firestore (stream)
/// Returns list of workout set UUIDs that the user has favorited
final userFavoritesProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});

/// Check if a specific set is favorited by the current user
final isFavoriteProvider = Provider.family<bool, String>((ref, setUuid) {
  final favorites = ref.watch(userFavoritesProvider).value ?? [];
  return favorites.contains(setUuid);
});

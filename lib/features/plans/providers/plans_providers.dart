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

/// Community sets from Firestore - filtered and sorted
final communitySetsProvider = StreamProvider<List<WorkoutSet>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final difficulty = ref.watch(selectedDifficultyProvider);
  final sortBy = ref.watch(sortByProvider);

  return FirebaseFirestore.instance
      .collection('community_sets')
      .snapshots()
      .map((snapshot) {
    // Convert Firestore docs to WorkoutSet objects
    var sets = snapshot.docs.map((doc) {
      final data = doc.data();
      return WorkoutSet(
        id: 0, // Firestore sets don't have local id
        uuid: doc.id,
        name: data['name'] ?? '',
        description: data['description'],
        difficulty: data['difficulty'] ?? 'intermediate',
        category: data['category'] ?? 'hybrid',
        source: 'community',
        estimatedMinutes: data['estimated_minutes'] ?? 30,
        exercises: data['exercises'] ?? [],
        authorName: data['author_name'],
        authorId: data['author_uid'],
        isFavorite: false, // Will be checked separately via favorites provider
        createdAt: data['created_at'] != null
            ? (data['created_at'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['created_at'] != null
            ? (data['created_at'] as Timestamp).toDate()
            : DateTime.now(),
        lastSyncedAt: null,
      );
    }).toList();

    // Apply filters
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      sets = sets.where((set) =>
          set.name.toLowerCase().contains(query) ||
          (set.description?.toLowerCase().contains(query) ?? false)).toList();
    }

    if (category != null) {
      sets = sets.where((set) => set.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (difficulty != null) {
      sets = sets.where((set) => set.difficulty.toLowerCase() == difficulty.toLowerCase()).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'recent':
        sets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popular':
        // For now, sort by creation date (can add popularity metrics later)
        sets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'difficulty':
        final difficultyOrder = {'beginner': 1, 'intermediate': 2, 'advanced': 3};
        sets.sort((a, b) {
          final aOrder = difficultyOrder[a.difficulty.toLowerCase()] ?? 2;
          final bOrder = difficultyOrder[b.difficulty.toLowerCase()] ?? 2;
          return aOrder.compareTo(bOrder);
        });
        break;
      case 'duration':
        sets.sort((a, b) => a.estimatedMinutes.compareTo(b.estimatedMinutes));
        break;
    }

    return sets;
  });
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

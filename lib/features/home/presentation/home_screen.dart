import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/color_tokens.dart';
import '../../../app/widgets/composite/stats_grid.dart';
import '../../../data/local/db/app_database.dart';
import '../providers/home_providers.dart';
import '../widgets/adaptive_banner_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<WorkoutSet> _trendingWorkouts = [];
  bool _showBanner = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final showBanner = await prefs.getBool('show_home_banner') ?? true;

    final setsRepo = ref.read(setsRepositoryProvider);
    final sets = await setsRepo.getAllSets();

    final trending = sets.where((s) => s.source == 'seed').take(3).toList();

    if (mounted) {
      setState(() {
        _showBanner = showBanner;
        _trendingWorkouts = trending;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NoctraFit'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showBanner)
              AdaptiveBannerCard.timeAware(
                onTap: () {
                  if (_trendingWorkouts.isNotEmpty) {
                    context.push('/plans/details/${_trendingWorkouts.first.uuid}');
                  }
                },
                onDismiss: () async {
                  await ref.read(preferencesRepositoryProvider).setBool('show_home_banner', false);
                  setState(() => _showBanner = false);
                },
              ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'This Week',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ColorTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            Consumer(
              builder: (context, ref, child) {
                final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
                return weeklyStatsAsync.when(
                  data: (stats) => StatsGrid(stats: stats),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Workouts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ColorTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/plans'),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _trendingWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = _trendingWorkouts[index];
                  return _WorkoutCard(
                    name: workout.name,
                    duration: '${workout.estimatedMinutes} min',
                    difficulty: workout.difficulty,
                    onTap: () => context.push('/plans/details/${workout.uuid}'),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

}

class _WorkoutCard extends StatelessWidget {
  final String name;
  final String duration;
  final String difficulty;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.name,
    required this.duration,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorTokens.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  TablerIcons.barbell,
                  color: ColorTokens.accent,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ColorTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          TablerIcons.clock,
                          size: 12,
                          color: ColorTokens.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            difficulty,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getDifficultyColor(difficulty),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                TablerIcons.chevron_right,
                color: ColorTokens.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return ColorTokens.success;
      case 'intermediate':
        return ColorTokens.warning;
      case 'advanced':
        return ColorTokens.error;
      default:
        return ColorTokens.textSecondary;
    }
  }
}

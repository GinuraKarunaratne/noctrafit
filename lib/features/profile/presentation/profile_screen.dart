import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/service_providers.dart';
import '../../../app/theme/color_tokens.dart';
import '../../../app/widgets/composite/stats_grid.dart';
import '../providers/profile_providers.dart';
import '../widgets/progress_heatmap_card.dart';

/// Profile screen - User stats, heatmap, and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Load real data from providers
    final lifetimeStatsAsync = ref.watch(lifetimeStatsProvider);
    final heatmapDataAsync = ref.watch(activityHeatmapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.settings),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // User info
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorTokens.accent.withOpacity(0.2),
                      border: Border.all(
                        color: ColorTokens.accent,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      TablerIcons.user,
                      size: 40,
                      color: ColorTokens.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final user = ref.watch(currentUserProvider);
                      return FutureBuilder<String?>(
                        future: user != null
                            ? ref.read(userRemoteDataSourceProvider).getUserProfile(user.uid).then((profile) => profile?['display_name'] as String?)
                            : Future.value(null),
                        builder: (context, snapshot) {
                          final displayName = snapshot.data ?? user?.email?.split('@').first ?? 'User';
                          return Column(
                            children: [
                              Text(
                                displayName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: ColorTokens.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ColorTokens.textSecondary,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress Heatmap Card
            heatmapDataAsync.when(
              data: (heatmapData) => ProgressHeatmapCard(
                title: 'Workout Activity',
                completionsByDate: heatmapData,
                maxIntensity: 3,
                onTap: () {},
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Section: Lifetime Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Lifetime Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Stats Grid
            lifetimeStatsAsync.when(
              data: (stats) => StatsGrid(stats: stats, crossAxisCount: 2),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Achievements section (placeholder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Achievements',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            _AchievementsList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Achievements list (placeholder)
class _AchievementsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'title': 'Night Owl', 'description': 'Complete 10 night workouts', 'icon': TablerIcons.moon},
      {'title': 'Streak Master', 'description': '30-day streak achieved', 'icon': TablerIcons.flame},
      {'title': 'Century Club', 'description': '100 total workouts', 'icon': TablerIcons.trophy},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _AchievementCard(
          title: achievement['title']! as String,
          description: achievement['description']! as String,
          icon: achievement['icon']! as IconData,
        );
      },
    );
  }
}

/// Achievement card widget
class _AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _AchievementCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
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
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ColorTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ColorTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            TablerIcons.check,
            color: ColorTokens.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}

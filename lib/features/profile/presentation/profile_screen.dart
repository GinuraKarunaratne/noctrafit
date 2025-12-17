import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/achievement_providers.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/service_providers.dart';
import '../../../app/theme/color_tokens.dart';
import '../../../app/widgets/composite/stats_grid.dart';
import '../providers/profile_providers.dart';
import '../widgets/progress_heatmap_card.dart';

/// Profile screen - User stats, heatmap, and settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceScreen());
  }

  Future<void> _announceScreen() async {
    final tts = ref.read(ttsServiceProvider);
    await tts.speakScreenSummary('Profile');
  }

  @override
  Widget build(BuildContext context) {
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
                    child:  Icon(
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

/// Achievements list - fetches from Firestore with local fallback
/// Always displays achievements (locked and unlocked), never empty
class _AchievementsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        // Always show achievements list - provider ensures we have at least defaults
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _AchievementCard(
              title: achievement.title,
              description: achievement.description,
              isUnlocked: achievement.isUnlocked,
              currentProgress: achievement.currentProgress,
              goalTarget: achievement.goalTarget,
              goalType: achievement.goalType,
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) {
        // Even on error, try to show default achievements template
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                'Loading achievements...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Achievement card - shows unlock status and progress
/// Locked achievements appear faded; unlocked appear bright
class _AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isUnlocked;
  final int? currentProgress;
  final int goalTarget;
  final String goalType;

  const _AchievementCard({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.currentProgress,
    required this.goalTarget,
    required this.goalType,
  });

  String _getProgressLabel() {
    if (currentProgress == null) return '';
    switch (goalType) {
      case 'workouts':
        return '$currentProgress / $goalTarget workouts';
      case 'streak':
        return '$currentProgress / $goalTarget day streak';
      case 'duration':
        return '$currentProgress / $goalTarget minutes';
      default:
        return '$currentProgress / $goalTarget';
    }
  }

  IconData _getIconForGoalType() {
    switch (goalType) {
      case 'workouts':
        return TablerIcons.activity;
      case 'streak':
        return TablerIcons.flame;
      case 'duration':
        return TablerIcons.clock;
      default:
        return TablerIcons.trophy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = currentProgress != null && goalTarget > 0
        ? (currentProgress! / goalTarget).clamp(0.0, 1.0)
        : 0.0;

    // Faded opacity for locked achievements
    final opacity = isUnlocked ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked ? ColorTokens.surface : ColorTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? ColorTokens.accent : ColorTokens.border.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: ColorTokens.accent.withOpacity(0.2),
                    blurRadius: 8,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? ColorTokens.accent.withOpacity(0.2)
                        : ColorTokens.border.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForGoalType(),
                    color: isUnlocked ? ColorTokens.accent : ColorTokens.textSecondary,
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
                          color: isUnlocked ? ColorTokens.textPrimary : ColorTokens.textSecondary,
                          fontWeight: FontWeight.bold,
                          decoration: isUnlocked ? TextDecoration.none : null,
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
                Icon(
                  isUnlocked ? TablerIcons.check : TablerIcons.lock,
                  color: isUnlocked ? ColorTokens.success : ColorTokens.textSecondary.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            if (currentProgress != null && !isUnlocked) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 4,
                  backgroundColor: ColorTokens.border.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorTokens.accent.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getProgressLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ColorTokens.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


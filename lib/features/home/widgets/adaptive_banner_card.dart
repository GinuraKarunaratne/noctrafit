import 'package:flutter/material.dart';
import '../../../app/theme/color_tokens.dart';

/// CW1: Adaptive Banner Card - Time-aware workout suggestions
///
/// Features:
/// - Time-based suggestions (night = meditation, evening = stretch, etc.)
/// - Dismissible with swipe gesture
/// - Gradient background with luminous green accent
/// - Fully reusable with custom data
///
/// Reused in: HomeScreen
class AdaptiveBannerCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? workoutName;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AdaptiveBannerCard({
    super.key,
    required this.title,
    this.subtitle,
    this.workoutName,
    required this.icon,
    this.onTap,
    this.onDismiss,
  });

  /// Factory: Create time-aware suggestion based on current hour
  factory AdaptiveBannerCard.timeAware({
    Key? key,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final hour = DateTime.now().hour;

    // Night shift hours: 10 PM - 6 AM
    if (hour >= 22 || hour < 6) {
      return AdaptiveBannerCard(
        key: key,
        title: 'Night Shift Mode',
        subtitle: 'Stay energized with a quick workout',
        workoutName: 'Night Shift Quick Starter',
        icon: Icons.nights_stay,
        onTap: onTap,
        onDismiss: onDismiss,
      );
    }
    // Early morning: 6 AM - 9 AM
    else if (hour >= 6 && hour < 9) {
      return AdaptiveBannerCard(
        key: key,
        title: 'Good Morning',
        subtitle: 'Start your day with energy',
        workoutName: 'Midnight Full Body Burn',
        icon: Icons.wb_sunny,
        onTap: onTap,
        onDismiss: onDismiss,
      );
    }
    // Late evening: 6 PM - 10 PM
    else if (hour >= 18 && hour < 22) {
      return AdaptiveBannerCard(
        key: key,
        title: 'Wind Down',
        subtitle: 'Relax and stretch before bed',
        workoutName: 'Late Night Wind Down',
        icon: Icons.self_improvement,
        onTap: onTap,
        onDismiss: onDismiss,
      );
    }
    // Daytime: 9 AM - 6 PM
    else {
      return AdaptiveBannerCard(
        key: key,
        title: 'Midday Boost',
        subtitle: 'Take a break and move',
        workoutName: 'Night Shift Energy Boost',
        icon: Icons.flash_on,
        onTap: onTap,
        onDismiss: onDismiss,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorTokens.surface,
            ColorTokens.accent.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorTokens.accent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.accent.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorTokens.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: ColorTokens.accent,
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ColorTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorTokens.textSecondary,
                        ),
                      ),
                    ],
                    if (workoutName != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorTokens.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ColorTokens.accent.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          workoutName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon (if tappable)
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: ColorTokens.accent,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );

    // Wrap in Dismissible if onDismiss is provided
    if (onDismiss != null) {
      return Dismissible(
        key: ValueKey('adaptive_banner_${DateTime.now().millisecondsSinceEpoch}'),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) {
          onDismiss?.call();
        },
        background: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: ColorTokens.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.delete_outline,
            color: ColorTokens.error,
            size: 28,
          ),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: ColorTokens.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete_outline,
            color: ColorTokens.error,
            size: 28,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}

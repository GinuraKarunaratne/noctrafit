import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../app/theme/color_tokens.dart';

/// CW5: Active Session Mini Bar - Global floating bar
///
/// Features:
/// - Shows workout name + elapsed time
/// - Visible on ALL screens when session active
/// - Tap to return to ActiveSessionProgressScreen
/// - Pulsing green indicator + luminous border + shadow
/// - Watches activeSessionProvider
///
/// Reused in: BottomNavScaffold (global overlay)
class ActiveSessionMiniBar extends ConsumerStatefulWidget {
  const ActiveSessionMiniBar({super.key});

  @override
  ConsumerState<ActiveSessionMiniBar> createState() => _ActiveSessionMiniBarState();
}

class _ActiveSessionMiniBarState extends ConsumerState<ActiveSessionMiniBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Update elapsed time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // TODO: Calculate from active session start time
          _elapsed = _elapsed + const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Watch active session provider
    // final activeSession = ref.watch(activeSessionProvider);
    // if (activeSession == null) return const SizedBox.shrink();

    // For now, return empty - will be implemented when session provider exists
    // Uncomment below when ready:
    /*
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorTokens.surface,
              ColorTokens.accent.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorTokens.accent.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.accent.withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to active session screen
              // context.go('/session/${activeSession.sessionUuid}');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Pulsing indicator
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ColorTokens.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ColorTokens.accent.withOpacity(
                                0.6 * (1 - _pulseController.value),
                              ),
                              blurRadius: 8 * _pulseController.value,
                              spreadRadius: 4 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 12),

                  // Workout name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Workout in Progress', // TODO: activeSession.workoutName
                          style: const TextStyle(
                            color: ColorTokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatElapsed(_elapsed),
                          style: const TextStyle(
                            color: ColorTokens.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: ColorTokens.accent,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    */

    // Temporary: return empty until active session provider is implemented
    return const SizedBox.shrink();
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

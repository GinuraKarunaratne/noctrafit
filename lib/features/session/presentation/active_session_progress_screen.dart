import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/theme/color_tokens.dart';

/// UF3: Active Session Progress Screen
///
/// Features (matches Image 3 exactly):
/// - Dark background
/// - Luminous green circular progress ring
/// - Large timer display
/// - Current exercise info
/// - Previous/Next exercise buttons
/// - Complete Workout button
/// - Timer updates every second
/// - Persists to active_session table
/// - TTS announcements at milestones (50%, 10min remaining, completed)
class ActiveSessionProgressScreen extends ConsumerStatefulWidget {
  final String sessionUuid;

  const ActiveSessionProgressScreen({
    super.key,
    required this.sessionUuid,
  });

  @override
  ConsumerState<ActiveSessionProgressScreen> createState() =>
      _ActiveSessionProgressScreenState();
}

class _ActiveSessionProgressScreenState
    extends ConsumerState<ActiveSessionProgressScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  int _currentExerciseIndex = 0;
  final List<String> _completedExercises = [];

  // Mock data - will be replaced with actual session data from provider
  final String _workoutName = 'Night Shift Quick Starter';
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Push-ups',
      'sets': 3,
      'reps': 12,
      'rest': '30s',
    },
    {
      'name': 'Squats',
      'sets': 3,
      'reps': 15,
      'rest': '30s',
    },
    {
      'name': 'Plank',
      'sets': 3,
      'duration': '45s',
      'rest': '30s',
    },
    {
      'name': 'Lunges',
      'sets': 3,
      'reps': 12,
      'rest': '30s',
    },
  ];
  final int _estimatedMinutes = 15;

  bool _hasSpoken50Percent = false;
  bool _hasSpoken10MinRemaining = false;

  @override
  void initState() {
    super.initState();

    // TODO: Load session from active_session table
    // final session = ref.read(activeSessionProvider);
    // _elapsed = Duration(seconds: DateTime.now().difference(session.startedAt).inSeconds);
    // _currentExerciseIndex = session.currentExerciseIndex;
    // _completedExercises.addAll(session.completedExercises);

    // Start timer
    _startTimer();

    // TODO: Speak screen entry
    // ref.read(ttsServiceProvider).speakScreenSummary(
    //   'Active Workout',
    //   details: 'Starting $_workoutName. $_estimatedMinutes minutes estimated.',
    // );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = _elapsed + const Duration(seconds: 1);
        });

        // Check for milestones
        _checkMilestones();

        // TODO: Persist to active_session table
        // ref.read(sessionRepositoryProvider).updateElapsedTime(widget.sessionUuid, _elapsed);
      }
    });
  }

  void _checkMilestones() {
    final progress = _getProgressPercentage();
    final remainingMinutes =
        _estimatedMinutes - (_elapsed.inMinutes);

    // 50% milestone
    if (progress >= 0.5 && !_hasSpoken50Percent) {
      _hasSpoken50Percent = true;
      // TODO: TTS announcement
      // ref.read(ttsServiceProvider).speakMilestone('You are halfway through the workout!');
    }

    // 10 minutes remaining
    if (remainingMinutes <= 10 && remainingMinutes > 9 && !_hasSpoken10MinRemaining) {
      _hasSpoken10MinRemaining = true;
      // TODO: TTS announcement
      // ref.read(ttsServiceProvider).speakMilestone('10 minutes remaining');
    }
  }

  double _getProgressPercentage() {
    return (_currentExerciseIndex + 1) / _exercises.length;
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });

      // TODO: Persist to active_session table
      // ref.read(sessionRepositoryProvider).updateCurrentExercise(widget.sessionUuid, _currentExerciseIndex);
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      // Mark current as completed if not already
      final currentExerciseId = _exercises[_currentExerciseIndex]['name'];
      if (!_completedExercises.contains(currentExerciseId)) {
        _completedExercises.add(currentExerciseId);
      }

      setState(() {
        _currentExerciseIndex++;
      });

      // TODO: Persist to active_session table
      // ref.read(sessionRepositoryProvider).updateCurrentExercise(
      //   widget.sessionUuid,
      //   _currentExerciseIndex,
      //   _completedExercises,
      // );
    }
  }

  Future<void> _completeWorkout() async {
    _timer?.cancel();

    // TODO: Save to completion_logs table
    // await ref.read(sessionRepositoryProvider).completeWorkout(
    //   widget.sessionUuid,
    //   _elapsed,
    //   _completedExercises,
    // );

    // TODO: TTS announcement
    // await ref.read(ttsServiceProvider).speakWorkoutCompleted();

    if (mounted) {
      // Show completion dialog
      await showDialog(
        context: context,
        builder: (context) => _CompletionDialog(
          workoutName: _workoutName,
          duration: _elapsed,
          exercisesCompleted: _completedExercises.length,
          totalExercises: _exercises.length,
        ),
      );

      // Navigate back to home
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentExercise = _exercises[_currentExerciseIndex];
    final progress = _getProgressPercentage();

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: Text(
          _workoutName,
          style: const TextStyle(
            color: ColorTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.x, color: ColorTokens.textSecondary),
          onPressed: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('End Workout?'),
                content: const Text(
                    'Are you sure you want to end this workout? Progress will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      // TODO: Clear active session
                      // ref.read(sessionRepositoryProvider).clearSession();
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close screen
                    },
                    child: const Text('End',
                        style: TextStyle(color: ColorTokens.error)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Progress ring with timer (matches Image 3)
            Expanded(
              child: Center(
                child: _LuminousProgressRing(
                  progress: progress,
                  size: 280,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large timer
                      Text(
                        _formatElapsed(_elapsed),
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: ColorTokens.accent,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elapsed Time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorTokens.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Current exercise info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorTokens.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorTokens.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercise ${_currentExerciseIndex + 1}/${_exercises.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorTokens.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorTokens.accent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentExercise['name'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: ColorTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    children: [
                      if (currentExercise['sets'] != null)
                        _ExerciseDetail(
                          icon: TablerIcons.repeat,
                          label: '${currentExercise['sets']} sets',
                        ),
                      if (currentExercise['reps'] != null)
                        _ExerciseDetail(
                          icon: TablerIcons.number,
                          label: '${currentExercise['reps']} reps',
                        ),
                      if (currentExercise['duration'] != null)
                        _ExerciseDetail(
                          icon: TablerIcons.clock,
                          label: currentExercise['duration'],
                        ),
                      if (currentExercise['rest'] != null)
                        _ExerciseDetail(
                          icon: TablerIcons.clock_pause,
                          label: 'Rest ${currentExercise['rest']}',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Previous button
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _currentExerciseIndex > 0 ? _previousExercise : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: _currentExerciseIndex > 0
                              ? ColorTokens.border
                              : ColorTokens.border.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            TablerIcons.chevron_left,
                            color: _currentExerciseIndex > 0
                                ? ColorTokens.textPrimary
                                : ColorTokens.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Previous',
                            style: TextStyle(
                              color: _currentExerciseIndex > 0
                                  ? ColorTokens.textPrimary
                                  : ColorTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Next button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentExerciseIndex < _exercises.length - 1
                          ? _nextExercise
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            _currentExerciseIndex < _exercises.length - 1
                                ? ColorTokens.accent
                                : ColorTokens.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color:
                                  _currentExerciseIndex < _exercises.length - 1
                                      ? ColorTokens.background
                                      : ColorTokens.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            TablerIcons.chevron_right,
                            color:
                                _currentExerciseIndex < _exercises.length - 1
                                    ? ColorTokens.background
                                    : ColorTokens.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Complete workout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeWorkout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: ColorTokens.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TablerIcons.check, color: ColorTokens.background),
                      SizedBox(width: 8),
                      Text(
                        'Complete Workout',
                        style: TextStyle(
                          color: ColorTokens.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// Luminous green progress ring (matches Image 3)
class _LuminousProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Widget child;

  const _LuminousProgressRing({
    required this.progress,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: 1.0,
              color: ColorTokens.surface,
              strokeWidth: 12,
            ),
          ),

          // Progress ring with glow
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress,
              color: ColorTokens.accent,
              strokeWidth: 12,
              showGlow: true,
            ),
          ),

          // Center content
          child,
        ],
      ),
    );
  }
}

/// Custom painter for progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool showGlow;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.showGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Add glow effect for progress ring
    if (showGlow) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    // Draw arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Exercise detail chip
class _ExerciseDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExerciseDetail({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ColorTokens.accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ColorTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Completion dialog
class _CompletionDialog extends StatelessWidget {
  final String workoutName;
  final Duration duration;
  final int exercisesCompleted;
  final int totalExercises;

  const _CompletionDialog({
    required this.workoutName,
    required this.duration,
    required this.exercisesCompleted,
    required this.totalExercises,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return AlertDialog(
      backgroundColor: ColorTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ColorTokens.success, width: 2),
      ),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorTokens.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.circle_check_filled,
              color: ColorTokens.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Workout Complete!',
            style: theme.textTheme.titleLarge?.copyWith(
              color: ColorTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            workoutName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: ColorTokens.accent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CompletionStat(
                icon: TablerIcons.clock,
                value: '$minutes:${seconds.toString().padLeft(2, '0')}',
                label: 'Duration',
              ),
              _CompletionStat(
                icon: TablerIcons.check,
                value: '$exercisesCompleted/$totalExercises',
                label: 'Exercises',
              ),
            ],
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.success,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                color: ColorTokens.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Completion stat widget
class _CompletionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CompletionStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: ColorTokens.accent, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: ColorTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ColorTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

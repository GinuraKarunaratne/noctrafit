import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../app/providers/service_providers.dart';
import '../../../app/theme/color_tokens.dart';
import '../../../data/local/db/app_database.dart';

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

  const ActiveSessionProgressScreen({super.key, required this.sessionUuid});

  @override
  ConsumerState<ActiveSessionProgressScreen> createState() =>
      _ActiveSessionProgressScreenState();
}

class _ActiveSessionProgressScreenState
    extends ConsumerState<ActiveSessionProgressScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  ActiveSession? _session;
  WorkoutSet? _workoutSet;
  List<Map<String, dynamic>> _exercises = [];

  bool _hasSpoken50Percent = false;
  bool _hasSpoken10MinRemaining = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _startTimer();
    _announceStart();
  }

  Future<void> _announceStart() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final tts = ref.read(ttsServiceProvider);
    final s = _session;
    if (s != null) {
      await tts.speakWorkoutStarted(s.workoutSetName);
    }
  }

  // ✅ Safe helpers
  String _safeString(dynamic v, {String fallback = 'Unknown exercise'}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String? _safeNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// ✅ Decode exercises JSON safely (and accept your keys: duration_sec/rest_sec)
  List<Map<String, dynamic>> _safeDecodeExercises(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadSession() async {
    // ✅ IMPORTANT: load the active session ONLY if its uuid matches this route param.
    final session = await ref
        .read(sessionRepositoryProvider)
        .getSessionByUuid(widget.sessionUuid);

    if (!mounted) return;

    // If route is stale or session ended, show loading/error state (no random fallback!)
    if (session == null) {
      setState(() {
        _session = null;
        _workoutSet = null;
        _exercises = [];
      });
      return;
    }

    final setsRepo = ref.read(setsRepositoryProvider);

    // ✅ Find the correct workout set (no getSetById method needed)
    WorkoutSet? workoutSet;

    // Prefer UUID mapping when present (best for community sets)
    final setUuid = session.workoutSetUuid;
    if (setUuid != null && setUuid.trim().isNotEmpty) {
      workoutSet = await setsRepo.getSetByUuid(setUuid);
    }

    // Fallback: try by numeric ID via getAllSets() + filter
    if (workoutSet == null) {
      final allSets = await setsRepo.getAllSets();
      final matches = allSets.where((s) => s.id == session.workoutSetId).toList();
      workoutSet = matches.isNotEmpty ? matches.first : null;
    }

    if (!mounted) return;

    // If we STILL can't resolve the workout set, don't display seeded random.
    if (workoutSet == null) {
      setState(() {
        _session = session;
        _workoutSet = null;
        _exercises = [];
        _elapsed = DateTime.now().difference(session.startedAt);
      });
      return;
    }

    // Parse exercises (from workout set)
    final parsedExercises = _safeDecodeExercises(workoutSet.exercises);

    setState(() {
      _session = session;
      _workoutSet = workoutSet;
      _exercises = parsedExercises;
      _elapsed = DateTime.now().difference(session.startedAt);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = _elapsed + const Duration(seconds: 1);
      });

      _checkMilestones();
    });
  }

  void _checkMilestones() {
    final s = _session;
    if (s == null) return;

    final progress = _getProgressPercentage();
    final remainingMinutes = s.estimatedMinutes - (_elapsed.inMinutes);

    final tts = ref.read(ttsServiceProvider);

    if (progress >= 0.5 && !_hasSpoken50Percent) {
      _hasSpoken50Percent = true;
      tts.speakHalfwayMilestone();
    }

    if (remainingMinutes <= 10 &&
        remainingMinutes > 9 &&
        !_hasSpoken10MinRemaining) {
      _hasSpoken10MinRemaining = true;
      tts.speakTenMinutesRemaining();
    }
  }

  double _getProgressPercentage() {
    final s = _session;
    if (s == null || _exercises.isEmpty) return 0;
    return (s.currentExerciseIndex + 1) / _exercises.length;
  }

  Future<void> _previousExercise() async {
    final s = _session;
    if (s == null || s.currentExerciseIndex <= 0) return;

    await ref.read(sessionRepositoryProvider).goToPreviousExercise();
    await _loadSession();
  }

  Future<void> _nextExercise() async {
    final s = _session;
    if (s == null) return;

    if (_exercises.isEmpty) return;
    if (s.currentExerciseIndex >= _exercises.length - 1) return;

    await ref.read(sessionRepositoryProvider).progressToNextExercise();
    await _loadSession();

    // Announce next exercise
    final tts = ref.read(ttsServiceProvider);
    final s2 = _session;
    if (s2 != null && _exercises.isNotEmpty) {
      final nextIndex = (s2.currentExerciseIndex + 1).clamp(0, _exercises.length - 1);
      final nextExercise = _exercises[nextIndex];
      final exerciseName = _safeString(nextExercise['name']);
      await tts.speakNextExercise(exerciseName);
    }
  }

  Future<void> _completeWorkout() async {
    final s = _session;
    final ws = _workoutSet;
    if (s == null || ws == null) return;

    _timer?.cancel();

    final tts = ref.read(ttsServiceProvider);
    await tts.speakWorkoutCompleted();

    await ref.read(sessionRepositoryProvider).completeSession();

    if (!mounted) return;

    int completedCount = 0;
    try {
      final completed = jsonDecode(s.completedExercises) as List<dynamic>;
      completedCount = completed.length;
    } catch (_) {
      completedCount = s.currentExerciseIndex;
    }

    await showDialog(
      context: context,
      builder: (context) => _CompletionDialog(
        workoutName: ws.name,
        duration: _elapsed,
        exercisesCompleted: completedCount,
        totalExercises: _exercises.length,
      ),
    );

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Loading / missing states (no random seeded fallback)
    if (_session == null) {
      return Scaffold(
        backgroundColor: ColorTokens.background,
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_workoutSet == null) {
      return Scaffold(
        backgroundColor: ColorTokens.background,
        appBar: AppBar(
          title: const Text('Workout'),
          leading: IconButton(
            icon: Icon(TablerIcons.arrow_left, color: ColorTokens.textPrimary),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Workout set not found for this session.\n(Maybe it was deleted or not synced yet)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ColorTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_exercises.isEmpty) {
      return Scaffold(
        backgroundColor: ColorTokens.background,
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentExerciseIndex = _session!.currentExerciseIndex;
    final safeIndex = currentExerciseIndex.clamp(0, _exercises.length - 1);
    final currentExercise = _exercises[safeIndex];

    final progress = _getProgressPercentage();

    final exerciseName = _safeString(currentExercise['name']);
    final sets = _safeInt(currentExercise['sets']);
    final reps = _safeInt(currentExercise['reps']);

    // ✅ IMPORTANT: your JSON uses duration_sec / rest_sec (based on your table comment)
    final durationSec = currentExercise['duration_sec'] ?? currentExercise['duration'];
    final restSec = currentExercise['rest_sec'] ?? currentExercise['rest'];

    final duration = _safeNullableString(durationSec);
    final rest = _safeNullableString(restSec);

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: Text(
          _workoutSet!.name,
          style: TextStyle(
            color: ColorTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(TablerIcons.arrow_left, color: ColorTokens.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(TablerIcons.x, color: ColorTokens.textSecondary),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: ColorTokens.surface,
                  title: Text(
                    'End Workout?',
                    style: TextStyle(color: ColorTokens.textPrimary),
                  ),
                  content: Text(
                    'Are you sure you want to end this workout? Progress will be saved.',
                    style: TextStyle(color: ColorTokens.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('End', style: TextStyle(color: ColorTokens.error)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                _timer?.cancel();
                await ref.read(sessionRepositoryProvider).completeSession();
                if (!mounted) return;
                context.go('/home');
              }
            },
          ),
        ],
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
                        'Exercise ${safeIndex + 1}/${_exercises.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    exerciseName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: ColorTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    children: [
                      if (sets != null)
                        _ExerciseDetail(icon: TablerIcons.repeat, label: '$sets sets'),
                      if (reps != null)
                        _ExerciseDetail(icon: TablerIcons.number, label: '$reps reps'),
                      if (duration != null)
                        _ExerciseDetail(icon: TablerIcons.clock, label: '${duration}s'),
                      if (rest != null)
                        _ExerciseDetail(icon: TablerIcons.clock_pause, label: 'Rest ${rest}s'),
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: safeIndex > 0 ? _previousExercise : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: safeIndex > 0
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
                            color: safeIndex > 0
                                ? ColorTokens.textPrimary
                                : ColorTokens.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Previous',
                            style: TextStyle(
                              color: safeIndex > 0
                                  ? ColorTokens.textPrimary
                                  : ColorTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: safeIndex < _exercises.length - 1 ? _nextExercise : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: safeIndex < _exercises.length - 1
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
                              color: safeIndex < _exercises.length - 1
                                  ? ColorTokens.background
                                  : ColorTokens.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            TablerIcons.chevron_right,
                            color: safeIndex < _exercises.length - 1
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TablerIcons.check, color: ColorTokens.background),
                      const SizedBox(width: 8),
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
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: 1.0,
              color: ColorTokens.surface,
              strokeWidth: 12,
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress,
              color: ColorTokens.accent,
              strokeWidth: 12,
              showGlow: true,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

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

class _ExerciseDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExerciseDetail({required this.icon, required this.label});

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

/// Completion dialog (unchanged UI)
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
            child: Icon(
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
            child: Text(
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

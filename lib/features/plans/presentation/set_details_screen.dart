import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/color_tokens.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/firestore/user_remote_datasource.dart';

/// Set Details Screen - View workout set details
class SetDetailsScreen extends ConsumerStatefulWidget {
  final String workoutSetUuid;

  const SetDetailsScreen({
    super.key,
    required this.workoutSetUuid,
  });

  @override
  ConsumerState<SetDetailsScreen> createState() => _SetDetailsScreenState();
}

class _SetDetailsScreenState extends ConsumerState<SetDetailsScreen> {
  WorkoutSet? _workoutSet;
  List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadWorkoutSet();
  }

  // ✅ Safe helpers to avoid Null -> String crashes
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

  /// ✅ Convert TimeOfDay to a stable DB-friendly string (24h "HH:mm")
  String _timeOfDayTo24hString(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _loadWorkoutSet() async {
    final set = await ref.read(setsRepositoryProvider).getSetByUuid(widget.workoutSetUuid);
    if (set != null && mounted) {
      setState(() {
        _workoutSet = set;
        // Parse exercises JSON
        try {
          final exercisesJson = jsonDecode(set.exercises) as List<dynamic>;
          _exercises = exercisesJson.cast<Map<String, dynamic>>();
        } catch (e) {
          _exercises = [];
        }
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_workoutSet == null) return;

    final newFavoriteStatus = !_workoutSet!.isFavorite;

    setState(() {
      _workoutSet = _workoutSet!.copyWith(isFavorite: newFavoriteStatus);
    });

    await ref.read(setsRepositoryProvider).toggleFavorite(_workoutSet!.id, newFavoriteStatus);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final userDataSource = UserRemoteDataSource(FirebaseFirestore.instance);
      try {
        if (newFavoriteStatus) {
          await userDataSource.addFavorite(user.uid, widget.workoutSetUuid);
        } else {
          await userDataSource.removeFavorite(user.uid, widget.workoutSetUuid);
        }
      } catch (e) {
        // Offline - will sync later
      }
    }
  }

  Future<void> _startWorkout() async {
    if (_workoutSet == null) return;

    await ref.read(sessionRepositoryProvider).startSession(
      workoutSetId: _workoutSet!.id,
      workoutSetName: _workoutSet!.name,
      totalExercises: _exercises.length,
      estimatedMinutes: _workoutSet!.estimatedMinutes,
    );

    final session = await ref.read(sessionRepositoryProvider).getActiveSession();
    if (session != null && mounted) {
      context.go('/session/${session.sessionUuid}');
    }
  }

  Future<void> _addToCalendar() async {
    if (_workoutSet == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddToCalendarDialog(),
    );

    if (result != null) {
      final DateTime date = result['date'] as DateTime;
      final TimeOfDay time = result['time'] as TimeOfDay;
      final String timeString = _timeOfDayTo24hString(time);
      final String? note = (result['note'] as String?)?.trim().isEmpty ?? true
          ? null
          : (result['note'] as String?)?.trim();

      // ✅ FIX: pass String, not TimeOfDay
      await ref.read(scheduleRepositoryProvider).scheduleWorkout(
        workoutSetId: _workoutSet!.id,
        scheduledDate: date,
        timeOfDay: timeString, // ✅ was: result['time']
        note: note,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout scheduled for ${date.toString().split(' ')[0]} at $timeString'),
            backgroundColor: ColorTokens.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_workoutSet == null) {
      return Scaffold(
        backgroundColor: ColorTokens.background,
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorTokens.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: ColorTokens.background,
            leading: IconButton(
              icon: const Icon(TablerIcons.arrow_left, color: ColorTokens.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _workoutSet!.isFavorite ? TablerIcons.star_filled : TablerIcons.star,
                  color: _workoutSet!.isFavorite ? ColorTokens.accent : ColorTokens.textPrimary,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorTokens.accent.withOpacity(0.15),
                      ColorTokens.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _workoutSet!.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: ColorTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _InfoChip(
                              icon: TablerIcons.clock,
                              label: '${_workoutSet!.estimatedMinutes} min',
                            ),
                            _InfoChip(
                              icon: TablerIcons.trending_up,
                              label: _capitalize(_workoutSet!.difficulty),
                            ),
                            _InfoChip(
                              icon: TablerIcons.tag,
                              label: _capitalize(_workoutSet!.category),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_workoutSet!.description != null) ...[
                    Text(
                      'About',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ColorTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _workoutSet!.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ColorTokens.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercises',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: ColorTokens.textPrimary,
                          fontWeight: FontWeight.bold,
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
                          '${_exercises.length} exercises',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ..._exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;

                    return _ExerciseCard(
                      number: index + 1,
                      name: _safeString(exercise['name']),
                      sets: _safeInt(exercise['sets']),
                      reps: _safeInt(exercise['reps']),
                      duration: exercise['duration']?.toString(),
                      rest: exercise['rest']?.toString(),
                      muscleGroup: exercise['muscleGroup']?.toString(),
                      equipment: exercise['equipment']?.toString(),
                    );
                  }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorTokens.background,
            border: Border(
              top: BorderSide(color: ColorTokens.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _addToCalendar,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: ColorTokens.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TablerIcons.calendar_plus, color: ColorTokens.accent),
                      SizedBox(width: 8),
                      Text(
                        'Schedule',
                        style: TextStyle(
                          color: ColorTokens.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _startWorkout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: ColorTokens.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TablerIcons.player_play, color: ColorTokens.background),
                      SizedBox(width: 8),
                      Text(
                        'Start Workout',
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
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorTokens.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ColorTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Exercise card widget
class _ExerciseCard extends StatelessWidget {
  final int number;
  final String name;
  final int? sets;
  final int? reps;
  final String? duration;
  final String? rest;
  final String? muscleGroup;
  final String? equipment;

  const _ExerciseCard({
    required this.number,
    required this.name,
    this.sets,
    this.reps,
    this.duration,
    this.rest,
    this.muscleGroup,
    this.equipment,
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
        border: Border.all(color: ColorTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorTokens.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorTokens.accent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ColorTokens.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ColorTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (sets != null)
                      _ExerciseDetail(
                        icon: TablerIcons.repeat,
                        label: '$sets sets',
                      ),
                    if (reps != null)
                      _ExerciseDetail(
                        icon: TablerIcons.number,
                        label: '$reps reps',
                      ),
                    if (duration != null)
                      _ExerciseDetail(
                        icon: TablerIcons.clock,
                        label: duration!,
                      ),
                    if (rest != null)
                      _ExerciseDetail(
                        icon: TablerIcons.clock_pause,
                        label: 'Rest $rest',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (muscleGroup != null)
                      _Tag(label: muscleGroup!, color: ColorTokens.accent),
                    if (equipment != null)
                      _Tag(label: equipment!, color: ColorTokens.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        Icon(icon, size: 14, color: ColorTokens.textSecondary),
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Add to calendar dialog
class _AddToCalendarDialog extends StatefulWidget {
  @override
  State<_AddToCalendarDialog> createState() => _AddToCalendarDialogState();
}

class _AddToCalendarDialogState extends State<_AddToCalendarDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: ColorTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Schedule Workout',
        style: theme.textTheme.titleLarge?.copyWith(
          color: ColorTokens.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorTokens.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(TablerIcons.calendar, color: ColorTokens.accent),
            ),
            title: Text(
              'Date',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ColorTokens.textSecondary,
              ),
            ),
            subtitle: Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorTokens.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(TablerIcons.clock, color: ColorTokens.accent),
            ),
            title: Text(
              'Time',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ColorTokens.textSecondary,
              ),
            ),
            subtitle: Text(
              _selectedTime.format(context),
              style: theme.textTheme.titleSmall?.copyWith(
                color: ColorTokens.textPrimary,
              ),
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
          ),
          const SizedBox(height: 12),

          // ✅ Note field (so result['note'] exists)
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              labelStyle: TextStyle(color: ColorTokens.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ColorTokens.border),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ColorTokens.accent),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: ColorTokens.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'date': _selectedDate,
              'time': _selectedTime, // keep as TimeOfDay, convert later in _addToCalendar()
              'note': _noteController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorTokens.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Schedule',
            style: TextStyle(
              color: ColorTokens.background,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

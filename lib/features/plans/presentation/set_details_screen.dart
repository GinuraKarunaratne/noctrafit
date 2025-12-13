import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/color_tokens.dart';

/// Set Details Screen - View workout set details
///
/// Features:
/// - Workout details (name, description, difficulty, category)
/// - Exercise list with sets/reps/duration
/// - "Start Workout" button → launches active session
/// - "Add to Calendar" button → schedule workout
/// - Favorite toggle
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
  bool _isFavorite = false;

  // Mock data - will be replaced with actual data from provider
  final Map<String, dynamic> _workoutSet = {
    'uuid': 'ws-001',
    'name': 'Night Shift Quick Starter',
    'description':
        'Perfect 15-minute energizer designed for night shift workers. Get your blood flowing with this quick cardio and strength combo.',
    'difficulty': 'Beginner',
    'category': 'Cardio',
    'estimatedMinutes': 15,
    'source': 'App',
    'exercises': [
      {
        'name': 'Jumping Jacks',
        'sets': 3,
        'reps': 20,
        'rest': '30s',
        'muscleGroup': 'Full Body',
        'equipment': 'None',
      },
      {
        'name': 'Push-ups',
        'sets': 3,
        'reps': 12,
        'rest': '30s',
        'muscleGroup': 'Chest',
        'equipment': 'None',
      },
      {
        'name': 'Squats',
        'sets': 3,
        'reps': 15,
        'rest': '30s',
        'muscleGroup': 'Legs',
        'equipment': 'None',
      },
      {
        'name': 'Plank',
        'sets': 3,
        'duration': '45s',
        'rest': '30s',
        'muscleGroup': 'Core',
        'equipment': 'None',
      },
    ],
  };

  @override
  void initState() {
    super.initState();

    // TODO: Load workout set from provider
    // final workoutSet = ref.read(setsRepositoryProvider).getSetByUuid(widget.workoutSetUuid);
    // _isFavorite = workoutSet.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // TODO: Update favorite status in database
    // await ref.read(setsRepositoryProvider).toggleFavorite(widget.workoutSetUuid, _isFavorite);
  }

  Future<void> _startWorkout() async {
    // Generate session UUID
    final sessionUuid = const Uuid().v4();

    // TODO: Create active session in database
    // await ref.read(sessionRepositoryProvider).startSession(
    //   sessionUuid: sessionUuid,
    //   workoutSetId: widget.workoutSetUuid,
    // );

    // Navigate to active session screen
    if (mounted) {
      // TODO: Use go_router navigation
      // context.go('/session/$sessionUuid');

      // For now, show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting workout: ${_workoutSet['name']}'),
          backgroundColor: ColorTokens.success,
        ),
      );
    }
  }

  Future<void> _addToCalendar() async {
    // Show date/time picker dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddToCalendarDialog(),
    );

    if (result != null && mounted) {
      // TODO: Save to schedule_entries table
      // await ref.read(scheduleRepositoryProvider).scheduleWorkout(
      //   workoutSetUuid: widget.workoutSetUuid,
      //   scheduledDate: result['date'],
      //   timeOfDay: result['time'],
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Workout scheduled for ${result['date'].toString().split(' ')[0]}'),
          backgroundColor: ColorTokens.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercises = _workoutSet['exercises'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: ColorTokens.background,
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: ColorTokens.background,
            leading: IconButton(
              icon: const Icon(TablerIcons.arrow_left,
                  color: ColorTokens.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? TablerIcons.heart_filled : TablerIcons.heart,
                  color: _isFavorite ? ColorTokens.error : ColorTokens.textPrimary,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(TablerIcons.share,
                    color: ColorTokens.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share workout')),
                  );
                },
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
                          _workoutSet['name'],
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
                              label: '${_workoutSet['estimatedMinutes']} min',
                            ),
                            _InfoChip(
                              icon: TablerIcons.trending_up,
                              label: _workoutSet['difficulty'],
                            ),
                            _InfoChip(
                              icon: TablerIcons.tag,
                              label: _workoutSet['category'],
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

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ColorTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _workoutSet['description'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ColorTokens.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Exercises header
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
                          '${exercises.length} exercises',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Exercise list
                  ...exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    return _ExerciseCard(
                      number: index + 1,
                      name: exercise['name'],
                      sets: exercise['sets'],
                      reps: exercise['reps'],
                      duration: exercise['duration'],
                      rest: exercise['rest'],
                      muscleGroup: exercise['muscleGroup'],
                      equipment: exercise['equipment'],
                    );
                  }),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom action buttons
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
              // Add to calendar button
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

              // Start workout button
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
                      Icon(TablerIcons.player_play,
                          color: ColorTokens.background),
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
          // Exercise number
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

          // Exercise details
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

                // Sets/Reps/Duration
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

                // Muscle group & equipment
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

/// Exercise detail widget
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

/// Tag widget
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
          // Date picker
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

          // Time picker
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: ColorTokens.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'date': _selectedDate,
              'time': _selectedTime,
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
            style: TextStyle(color: ColorTokens.background, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

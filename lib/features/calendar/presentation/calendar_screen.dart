import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../app/providers/service_providers.dart';
import '../../../app/theme/color_tokens.dart';
import '../../../data/local/db/app_database.dart';

/// Calendar screen - Schedule and view upcoming workouts
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<ScheduleEntry> _scheduleEntries = [];
  Map<int, WorkoutSet> _workoutSetsCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduleEntries();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceScreen());
  }

  Future<void> _announceScreen() async {
    final tts = ref.read(ttsServiceProvider);
    final count = _scheduleEntries.length;
    await tts.speakScreenSummary(
      'Calendar',
      details: '$count workouts scheduled',
    );
  }

  Future<void> _loadScheduleEntries() async {
    setState(() => _isLoading = true);

    final scheduleRepo = ref.read(scheduleRepositoryProvider);
    final setsRepo = ref.read(setsRepositoryProvider);

    try {
      // Load schedule entries for selected date
      final entries = await scheduleRepo.getEntriesForDate(_selectedDate);

      // Load workout sets for all entries - with fallback
      List<WorkoutSet> allSets;
      try {
        allSets = await setsRepo.getAllSets();
      } catch (e) {
        // Fallback: use empty list if offline (prevents null crash)
        allSets = [];
      }

      final setsCache = <int, WorkoutSet>{};
      for (final set in allSets) {
        setsCache[set.id] = set;
      }

      if (mounted) {
        setState(() {
          _scheduleEntries = entries;
          _workoutSetsCache = setsCache;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error loading schedule - show empty state instead of crashing
      if (mounted) {
        setState(() {
          _scheduleEntries = [];
          _workoutSetsCache = {};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: tokens.surface,
            child: _WeekView(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
                _loadScheduleEntries();
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scheduled Workouts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(_selectedDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _scheduleEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          TablerIcons.calendar_off,
                          size: 64,
                          color: tokens.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts scheduled',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _scheduleEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _scheduleEntries[index];
                      final workoutSet = _workoutSetsCache[entry.workoutSetId];

                      return _ScheduledWorkoutCard(
                        name: workoutSet?.name ?? 'Unknown Workout',
                        time: entry.timeOfDay,
                        duration: workoutSet != null
                            ? '${workoutSet.estimatedMinutes} min'
                            : '-',
                        isCompleted: entry.isCompleted,
                        onTap: () {},
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _WeekView({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((date) {
        final isSelected =
            date.day == selectedDate.day &&
            date.month == selectedDate.month &&
            date.year == selectedDate.year;
        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            width: 40,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? tokens.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7],
                  style: TextStyle(
                    color: isSelected
                        ? tokens.background
                        : tokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected ? tokens.background : tokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScheduledWorkoutCard extends StatelessWidget {
  final String name;
  final String time;
  final String duration;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ScheduledWorkoutCard({
    required this.name,
    required this.time,
    required this.duration,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? tokens.success : tokens.border,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Icon(
                    TablerIcons.clock,
                    size: 20,
                    color: isCompleted ? tokens.success : tokens.accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCompleted ? tokens.success : tokens.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted
                    ? TablerIcons.circle_check_filled
                    : TablerIcons.play_card,
                color: isCompleted ? tokens.success : tokens.accent,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

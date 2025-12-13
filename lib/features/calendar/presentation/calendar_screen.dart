import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/repository_providers.dart';
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
  }

  Future<void> _loadScheduleEntries() async {
    setState(() => _isLoading = true);

    final scheduleRepo = ref.read(scheduleRepositoryProvider);
    final setsRepo = ref.read(setsRepositoryProvider);

    // Load schedule entries for selected date
    final entries = await scheduleRepo.getEntriesForDate(_selectedDate);

    // Load workout sets for all entries
    final allSets = await setsRepo.getAllSets();
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.calendar_plus),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule workout')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: ColorTokens.surface,
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
                    color: ColorTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(_selectedDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ColorTokens.textSecondary,
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
                            Icon(TablerIcons.calendar_off, size: 64, color: ColorTokens.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('No workouts scheduled', style: TextStyle(color: ColorTokens.textSecondary, fontSize: 16)),
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
                            duration: workoutSet != null ? '${workoutSet.estimatedMinutes} min' : '-',
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _WeekView({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((date) {
        final isSelected = date.day == selectedDate.day && date.month == selectedDate.month && date.year == selectedDate.year;
        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            width: 40,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? ColorTokens.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7],
                    style: TextStyle(color: isSelected ? ColorTokens.background : ColorTokens.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${date.day}',
                    style: TextStyle(color: isSelected ? ColorTokens.background : ColorTokens.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
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

  const _ScheduledWorkoutCard({required this.name, required this.time, required this.duration, required this.isCompleted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCompleted ? ColorTokens.success : ColorTokens.border, width: isCompleted ? 2 : 1),
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
                  Icon(TablerIcons.clock, size: 20, color: isCompleted ? ColorTokens.success : ColorTokens.accent),
                  const SizedBox(height: 4),
                  Text(time, style: theme.textTheme.bodySmall?.copyWith(color: isCompleted ? ColorTokens.success : ColorTokens.accent, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleSmall?.copyWith(color: ColorTokens.textPrimary, fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                    const SizedBox(height: 4),
                    Text(duration, style: theme.textTheme.bodySmall?.copyWith(color: ColorTokens.textSecondary)),
                  ],
                ),
              ),
              Icon(isCompleted ? TablerIcons.circle_check_filled : TablerIcons.play_card, color: isCompleted ? ColorTokens.success : ColorTokens.accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

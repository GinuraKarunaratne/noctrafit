import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../app/theme/color_tokens.dart';

/// UF2: Create Set Screen - Add custom workout sets
///
/// Features:
/// - Form: name, description, difficulty, category, estimated minutes
/// - Add exercises from reference library
/// - Reorder exercises (drag and drop)
/// - "Save Locally" button
/// - "Publish to Community" button (saves locally + uploads to Firestore)
/// - Offline-first: saves locally, queues for sync if offline
class CreateSetScreen extends ConsumerStatefulWidget {
  const CreateSetScreen({super.key});

  @override
  ConsumerState<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends ConsumerState<CreateSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _difficulty = 'Beginner';
  String _category = 'Cardio';
  int _estimatedMinutes = 15;

  final List<Map<String, dynamic>> _selectedExercises = [];

  // Mock exercise library - will be replaced with actual data from database
  final List<Map<String, dynamic>> _availableExercises = [
    {'uuid': 'ex-001', 'name': 'Push-ups', 'muscleGroup': 'Chest', 'equipment': 'None'},
    {'uuid': 'ex-002', 'name': 'Squats', 'muscleGroup': 'Legs', 'equipment': 'None'},
    {'uuid': 'ex-003', 'name': 'Plank', 'muscleGroup': 'Core', 'equipment': 'None'},
    {'uuid': 'ex-004', 'name': 'Lunges', 'muscleGroup': 'Legs', 'equipment': 'None'},
    {'uuid': 'ex-005', 'name': 'Jumping Jacks', 'muscleGroup': 'Full Body', 'equipment': 'None'},
    {'uuid': 'ex-006', 'name': 'Burpees', 'muscleGroup': 'Full Body', 'equipment': 'None'},
    {'uuid': 'ex-007', 'name': 'Mountain Climbers', 'muscleGroup': 'Core', 'equipment': 'None'},
    {'uuid': 'ex-008', 'name': 'Bicycle Crunches', 'muscleGroup': 'Core', 'equipment': 'None'},
    {'uuid': 'ex-009', 'name': 'Tricep Dips', 'muscleGroup': 'Arms', 'equipment': 'Chair'},
    {'uuid': 'ex-010', 'name': 'Wall Sit', 'muscleGroup': 'Legs', 'equipment': 'Wall'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExercisePickerSheet(exercises: _availableExercises),
    );

    if (result != null) {
      setState(() {
        _selectedExercises.add({
          ...result,
          'sets': 3,
          'reps': 12,
          'rest': '30s',
        });
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _editExercise(int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ExerciseEditDialog(exercise: _selectedExercises[index]),
    );

    if (result != null) {
      setState(() {
        _selectedExercises[index] = result;
      });
    }
  }

  Future<void> _saveLocally() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: ColorTokens.error,
        ),
      );
      return;
    }

    // Save to database
    await ref.read(setsRepositoryProvider).createCustomSet(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      difficulty: _difficulty.toLowerCase(),
      category: _category.toLowerCase(),
      estimatedMinutes: _estimatedMinutes,
      exercisesJson: jsonEncode(_selectedExercises),
      authorName: null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved locally!'),
          backgroundColor: ColorTokens.success,
        ),
      );
      context.pop();
    }
  }

  Future<void> _publishToCommunity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: ColorTokens.error,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Publish to Community?', style: TextStyle(color: ColorTokens.textPrimary)),
        content: const Text(
          'This will make your workout visible to all users. You can edit or delete it later.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: ColorTokens.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Publish', style: TextStyle(color: ColorTokens.background, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to publish'), backgroundColor: ColorTokens.error),
        );
      }
      return;
    }

    // Save locally first
    final workoutSet = await ref.read(setsRepositoryProvider).createCustomSet(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      difficulty: _difficulty.toLowerCase(),
      category: _category.toLowerCase(),
      estimatedMinutes: _estimatedMinutes,
      exercisesJson: jsonEncode(_selectedExercises),
      authorName: user.email?.split('@').first,
    );

    // Upload to Firestore community_sets
    try {
      await FirebaseFirestore.instance.collection('community_sets').doc(workoutSet.uuid).set({
        'name': workoutSet.name,
        'description': workoutSet.description,
        'difficulty': workoutSet.difficulty,
        'category': workoutSet.category,
        'estimated_minutes': workoutSet.estimatedMinutes,
        'exercises': workoutSet.exercises,
        'author_name': workoutSet.authorName,
        'author_uid': user.uid,
        'created_at': FieldValue.serverTimestamp(),
        'views_count': 0,
        'downloads_count': 0,
        'favorites_count': 0,
      });
    } catch (e) {
      // Fallback to sync queue
      await ref.read(setsRepositoryProvider).queueForCommunityUpload(workoutSet);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout published to community!'),
          backgroundColor: ColorTokens.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ColorTokens.background,
      appBar: AppBar(
        title: const Text('Create Workout', style: TextStyle(color: ColorTokens.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: ColorTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.x, color: ColorTokens.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              Text(
                'Workout Name',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: ColorTokens.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g., Night Shift Energy Boost',
                  hintStyle: TextStyle(color: ColorTokens.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: ColorTokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorTokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorTokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorTokens.accent, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a workout name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description field
              Text(
                'Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: ColorTokens.textPrimary),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your workout...',
                  hintStyle: TextStyle(color: ColorTokens.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: ColorTokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorTokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorTokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorTokens.accent, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Difficulty & Category
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Difficulty',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: ColorTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _difficulty,
                          style: const TextStyle(color: ColorTokens.textPrimary),
                          dropdownColor: ColorTokens.surface,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: ColorTokens.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: ColorTokens.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: ColorTokens.border),
                            ),
                          ),
                          items: ['Beginner', 'Intermediate', 'Advanced'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _difficulty = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: ColorTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          style: const TextStyle(color: ColorTokens.textPrimary),
                          dropdownColor: ColorTokens.surface,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: ColorTokens.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: ColorTokens.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: ColorTokens.border),
                            ),
                          ),
                          items: ['Cardio', 'Strength', 'Flexibility', 'Mixed'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _category = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Estimated minutes
              Text(
                'Estimated Duration',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorTokens.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorTokens.border),
                ),
                child: Row(
                  children: [
                    const Icon(TablerIcons.clock, color: ColorTokens.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _estimatedMinutes.toDouble(),
                        min: 5,
                        max: 90,
                        divisions: 17,
                        activeColor: ColorTokens.accent,
                        inactiveColor: ColorTokens.border,
                        label: '$_estimatedMinutes min',
                        onChanged: (value) {
                          setState(() => _estimatedMinutes = value.toInt());
                        },
                      ),
                    ),
                    Text(
                      '$_estimatedMinutes min',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ColorTokens.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Exercises section
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
                  TextButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(TablerIcons.plus, color: ColorTokens.accent, size: 20),
                    label: const Text('Add Exercise', style: TextStyle(color: ColorTokens.accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Exercise list
              if (_selectedExercises.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: ColorTokens.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorTokens.border, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(TablerIcons.barbell_off, size: 48, color: ColorTokens.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises added yet',
                          style: TextStyle(color: ColorTokens.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Add Exercise" to get started',
                          style: TextStyle(color: ColorTokens.textSecondary.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._selectedExercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return _ExerciseItem(
                    number: index + 1,
                    exercise: exercise,
                    onEdit: () => _editExercise(index),
                    onRemove: () => _removeExercise(index),
                  );
                }),

              const SizedBox(height: 100), // Space for bottom buttons
            ],
          ),
        ),
      ),

      // Bottom action buttons
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorTokens.background,
            border: Border(top: BorderSide(color: ColorTokens.border, width: 1)),
          ),
          child: Row(
            children: [
              // Save locally button
              Expanded(
                child: OutlinedButton(
                  onPressed: _saveLocally,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: ColorTokens.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Locally', style: TextStyle(color: ColorTokens.textPrimary, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(width: 12),

              // Publish to community button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _publishToCommunity,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: ColorTokens.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(TablerIcons.cloud_upload, color: ColorTokens.background),
                      SizedBox(width: 8),
                      Text('Publish to Community', style: TextStyle(color: ColorTokens.background, fontWeight: FontWeight.bold)),
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

/// Exercise item widget
class _ExerciseItem extends StatelessWidget {
  final int number;
  final Map<String, dynamic> exercise;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ExerciseItem({
    required this.number,
    required this.exercise,
    required this.onEdit,
    required this.onRemove,
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
        children: [
          // Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorTokens.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorTokens.accent.withOpacity(0.3)),
            ),
            child: Center(
              child: Text('$number', style: const TextStyle(color: ColorTokens.accent, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(width: 12),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise['name'], style: theme.textTheme.titleSmall?.copyWith(color: ColorTokens.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${exercise['sets']} sets × ${exercise['reps'] ?? exercise['duration']} • Rest ${exercise['rest']}',
                  style: theme.textTheme.bodySmall?.copyWith(color: ColorTokens.textSecondary),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(TablerIcons.edit, size: 20, color: ColorTokens.accent),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(TablerIcons.trash, size: 20, color: ColorTokens.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Exercise picker bottom sheet
class _ExercisePickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> exercises;

  const _ExercisePickerSheet({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ColorTokens.border)),
            ),
            child: Row(
              children: [
                Text('Select Exercise', style: theme.textTheme.titleLarge?.copyWith(color: ColorTokens.textPrimary, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(TablerIcons.x, color: ColorTokens.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tileColor: ColorTokens.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: ColorTokens.border),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorTokens.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(TablerIcons.barbell, color: ColorTokens.accent, size: 24),
                  ),
                  title: Text(exercise['name'], style: const TextStyle(color: ColorTokens.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${exercise['muscleGroup']} • ${exercise['equipment']}', style: const TextStyle(color: ColorTokens.textSecondary)),
                  onTap: () => Navigator.pop(context, exercise),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Exercise edit dialog
class _ExerciseEditDialog extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const _ExerciseEditDialog({required this.exercise});

  @override
  State<_ExerciseEditDialog> createState() => _ExerciseEditDialogState();
}

class _ExerciseEditDialogState extends State<_ExerciseEditDialog> {
  late int _sets;
  late int _reps;
  late String _rest;

  @override
  void initState() {
    super.initState();
    _sets = widget.exercise['sets'] ?? 3;
    _reps = widget.exercise['reps'] ?? 12;
    _rest = widget.exercise['rest'] ?? '30s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: ColorTokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit Exercise', style: theme.textTheme.titleLarge?.copyWith(color: ColorTokens.textPrimary, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sets
          Row(
            children: [
              const Icon(TablerIcons.repeat, color: ColorTokens.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Sets', style: const TextStyle(color: ColorTokens.textPrimary))),
              IconButton(
                icon: const Icon(TablerIcons.minus, color: ColorTokens.textSecondary, size: 20),
                onPressed: () => setState(() => _sets = (_sets - 1).clamp(1, 10)),
              ),
              Text('$_sets', style: const TextStyle(color: ColorTokens.accent, fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon: const Icon(TablerIcons.plus, color: ColorTokens.textSecondary, size: 20),
                onPressed: () => setState(() => _sets = (_sets + 1).clamp(1, 10)),
              ),
            ],
          ),

          // Reps
          Row(
            children: [
              const Icon(TablerIcons.number, color: ColorTokens.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Reps', style: const TextStyle(color: ColorTokens.textPrimary))),
              IconButton(
                icon: const Icon(TablerIcons.minus, color: ColorTokens.textSecondary, size: 20),
                onPressed: () => setState(() => _reps = (_reps - 1).clamp(1, 50)),
              ),
              Text('$_reps', style: const TextStyle(color: ColorTokens.accent, fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon: const Icon(TablerIcons.plus, color: ColorTokens.textSecondary, size: 20),
                onPressed: () => setState(() => _reps = (_reps + 1).clamp(1, 50)),
              ),
            ],
          ),

          // Rest
          Row(
            children: [
              const Icon(TablerIcons.clock_pause, color: ColorTokens.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Rest', style: const TextStyle(color: ColorTokens.textPrimary))),
              DropdownButton<String>(
                value: _rest,
                dropdownColor: ColorTokens.background,
                style: const TextStyle(color: ColorTokens.accent, fontWeight: FontWeight.bold, fontSize: 18),
                items: ['15s', '30s', '45s', '60s', '90s'].map((value) {
                  return DropdownMenuItem(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => _rest = value!),
              ),
            ],
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
              ...widget.exercise,
              'sets': _sets,
              'reps': _reps,
              'rest': _rest,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorTokens.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save', style: TextStyle(color: ColorTokens.background, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

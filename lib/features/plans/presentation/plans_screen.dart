import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../app/theme/color_tokens.dart';

/// Plans screen - Browse and filter workout sets
/// Features: 3 tabs (App/Community/All), search, filter, sort
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String? _selectedCategory;
  String? _selectedDifficulty;
  String _sortBy = 'recent'; // recent, popular, difficulty, duration

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'App Sets'),
            Tab(text: 'Community'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search workouts...',
                prefixIcon: const Icon(TablerIcons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter button
                    IconButton(
                      icon: Icon(
                        TablerIcons.filter,
                        color: _hasActiveFilters()
                            ? ColorTokens.accent
                            : ColorTokens.textSecondary,
                      ),
                      onPressed: _showFilterSheet,
                    ),
                    // Sort button
                    IconButton(
                      icon: const Icon(TablerIcons.arrows_sort),
                      onPressed: _showSortMenu,
                    ),
                  ],
                ),
                filled: true,
                fillColor: ColorTokens.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorTokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorTokens.border),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to filter
              },
            ),
          ),

          // Active filters chips
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCategory != null)
                    _FilterChip(
                      label: _selectedCategory!,
                      onRemove: () => setState(() => _selectedCategory = null),
                    ),
                  if (_selectedDifficulty != null)
                    _FilterChip(
                      label: _selectedDifficulty!,
                      onRemove: () => setState(() => _selectedDifficulty = null),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _WorkoutList(source: 'seed'),
                _WorkoutList(source: 'community'),
                _WorkoutList(source: null), // All
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create set screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create workout coming soon...')),
          );
        },
        icon: const Icon(TablerIcons.plus),
        label: const Text('Create'),
        backgroundColor: ColorTokens.accent,
        foregroundColor: ColorTokens.background,
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null || _selectedDifficulty != null;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        selectedDifficulty: _selectedDifficulty,
        onApply: (category, difficulty) {
          setState(() {
            _selectedCategory = category;
            _selectedDifficulty = difficulty;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SortMenu(
        currentSort: _sortBy,
        onSelect: (sort) {
          setState(() => _sortBy = sort);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: ColorTokens.accent.withOpacity(0.2),
      deleteIconColor: ColorTokens.accent,
      labelStyle: const TextStyle(
        color: ColorTokens.accent,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Workout list widget
class _WorkoutList extends ConsumerWidget {
  final String? source; // 'seed', 'community', null (all)

  const _WorkoutList({this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Watch filtered workouts from repository
    final mockWorkouts = _getMockWorkouts();

    if (mockWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.inbox,
              size: 64,
              color: ColorTokens.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts found',
              style: TextStyle(
                color: ColorTokens.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: mockWorkouts.length,
      itemBuilder: (context, index) {
        final workout = mockWorkouts[index];
        return _WorkoutCard(
          name: workout['name']!,
          description: workout['description']!,
          difficulty: workout['difficulty']!,
          category: workout['category']!,
          duration: workout['duration']!,
          source: workout['source']!,
          onTap: () {
            // TODO: Navigate to workout details
          },
        );
      },
    );
  }

  List<Map<String, String>> _getMockWorkouts() {
    return [
      {
        'name': 'Night Shift Quick Starter',
        'description': 'Perfect 15-minute energizer for night shift workers',
        'difficulty': 'Beginner',
        'category': 'Cardio',
        'duration': '15 min',
        'source': 'App',
      },
      {
        'name': 'Midnight Full Body Burn',
        'description': 'Comprehensive full-body workout for late-night training',
        'difficulty': 'Intermediate',
        'category': 'Strength',
        'duration': '30 min',
        'source': 'App',
      },
      {
        'name': 'Night Owl HIIT',
        'description': 'High-intensity interval training for maximum calorie burn',
        'difficulty': 'Advanced',
        'category': 'Cardio',
        'duration': '25 min',
        'source': 'App',
      },
      {
        'name': 'Late Night Wind Down',
        'description': 'Gentle stretching and relaxation before bed',
        'difficulty': 'Beginner',
        'category': 'Flexibility',
        'duration': '12 min',
        'source': 'App',
      },
      {
        'name': 'Graveyard Shift Strength',
        'description': 'Build strength during the graveyard shift',
        'difficulty': 'Intermediate',
        'category': 'Strength',
        'duration': '35 min',
        'source': 'App',
      },
    ];
  }
}

/// Workout card widget
class _WorkoutCard extends StatelessWidget {
  final String name;
  final String description;
  final String difficulty;
  final String category;
  final String duration;
  final String source;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.duration,
    required this.source,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorTokens.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ColorTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    source == 'Community'
                        ? TablerIcons.users
                        : TablerIcons.star,
                    size: 16,
                    color: source == 'Community'
                        ? ColorTokens.info
                        : ColorTokens.accent,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ColorTokens.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(
                    icon: TablerIcons.clock,
                    label: duration,
                  ),
                  _Tag(
                    icon: _getCategoryIcon(category),
                    label: category,
                  ),
                  _DifficultyTag(difficulty: difficulty),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return TablerIcons.run;
      case 'strength':
        return TablerIcons.barbell;
      case 'flexibility':
        return TablerIcons.yoga;
      default:
        return TablerIcons.activity;
    }
  }
}

/// Tag widget
class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorTokens.surface.lighten(5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ColorTokens.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ColorTokens.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Difficulty tag widget
class _DifficultyTag extends StatelessWidget {
  final String difficulty;

  const _DifficultyTag({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getDifficultyColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        difficulty,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return ColorTokens.success;
      case 'intermediate':
        return ColorTokens.warning;
      case 'advanced':
        return ColorTokens.error;
      default:
        return ColorTokens.textSecondary;
    }
  }
}

/// Filter sheet widget
class _FilterSheet extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedDifficulty;
  final Function(String?, String?) onApply;

  const _FilterSheet({
    this.selectedCategory,
    this.selectedDifficulty,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _category;
  String? _difficulty;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _difficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Workouts',
            style: theme.textTheme.titleLarge?.copyWith(
              color: ColorTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Category filter
          Text(
            'Category',
            style: theme.textTheme.titleSmall?.copyWith(
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Cardio', 'Strength', 'Flexibility'].map((cat) {
              return ChoiceChip(
                label: Text(cat),
                selected: _category == cat,
                onSelected: (selected) {
                  setState(() => _category = selected ? cat : null);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Difficulty filter
          Text(
            'Difficulty',
            style: theme.textTheme.titleSmall?.copyWith(
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Beginner', 'Intermediate', 'Advanced'].map((diff) {
              return ChoiceChip(
                label: Text(diff),
                selected: _difficulty == diff,
                onSelected: (selected) {
                  setState(() => _difficulty = selected ? diff : null);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _difficulty = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onApply(_category, _difficulty),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sort menu widget
class _SortMenu extends StatelessWidget {
  final String currentSort;
  final Function(String) onSelect;

  const _SortMenu({
    required this.currentSort,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      {'value': 'recent', 'label': 'Most Recent', 'icon': TablerIcons.clock},
      {'value': 'popular', 'label': 'Most Popular', 'icon': TablerIcons.flame},
      {'value': 'difficulty', 'label': 'Difficulty', 'icon': TablerIcons.trending_up},
      {'value': 'duration', 'label': 'Duration', 'icon': TablerIcons.hourglass},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: theme.textTheme.titleLarge?.copyWith(
              color: ColorTokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) {
            final isSelected = currentSort == option['value'];
            return ListTile(
              leading: Icon(
                option['icon'] as IconData,
                color: isSelected ? ColorTokens.accent : ColorTokens.textSecondary,
              ),
              title: Text(
                option['label'] as String,
                style: TextStyle(
                  color: isSelected ? ColorTokens.accent : ColorTokens.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(TablerIcons.check, color: ColorTokens.accent)
                  : null,
              onTap: () => onSelect(option['value'] as String),
            );
          }),
        ],
      ),
    );
  }
}

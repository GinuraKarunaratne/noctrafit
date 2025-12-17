/// Achievement model - represents an achievement the user can unlock
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final String goalType; // 'workouts', 'streak', 'total_duration', etc.
  final int goalTarget;
  final int? currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.goalType,
    required this.goalTarget,
    this.currentProgress,
  });

  /// Factory to create from Firestore document
  factory Achievement.fromFirestore(String id, Map<String, dynamic> data) {
    return Achievement(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'trophy',
      isUnlocked: data['is_unlocked'] as bool? ?? false,
      goalType: data['goal_type'] as String? ?? 'workouts',
      goalTarget: data['goal_target'] as int? ?? 0,
      currentProgress: data['current_progress'] as int?,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'is_unlocked': isUnlocked,
      'goal_type': goalType,
      'goal_target': goalTarget,
      'current_progress': currentProgress,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Achievement copyWith({
    bool? isUnlocked,
    int? currentProgress,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      goalType: goalType,
      goalTarget: goalTarget,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }
}

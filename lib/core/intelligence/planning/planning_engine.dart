import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a planned task or goal.
class PlannedTask {
  final String id;
  final String title;
  final int priority;
  final DateTime? scheduledTime;
  final bool isCompleted;

  const PlannedTask({
    required this.id,
    required this.title,
    this.priority = 0,
    this.scheduledTime,
    this.isCompleted = false,
  });

  PlannedTask copyWith({
    String? title,
    int? priority,
    DateTime? scheduledTime,
    bool? isCompleted,
  }) {
    return PlannedTask(
      id: id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Represents the state of the PlanningEngine.
class PlanningState {
  final List<PlannedTask> tasks;
  final bool isPlanning;

  const PlanningState({
    this.tasks = const [],
    this.isPlanning = false,
  });

  PlanningState copyWith({
    List<PlannedTask>? tasks,
    bool? isPlanning,
  }) {
    return PlanningState(
      tasks: tasks ?? this.tasks,
      isPlanning: isPlanning ?? this.isPlanning,
    );
  }
}

/// The PlanningEngine handles task planning, goal decomposition, priority calculation,
/// scheduling, and conflict detection.
class PlanningEngine extends StateNotifier<PlanningState> {
  PlanningEngine() : super(const PlanningState());

  List<PlannedTask> get tasks => state.tasks;

  int _taskCounter = 0;

  /// Creates a new plan or task.
  Future<void> createPlan(String title) async {
    _taskCounter++;
    final newTask = PlannedTask(
      id: '${DateTime.now().microsecondsSinceEpoch}_$_taskCounter',
      title: title,
    );
    state = state.copyWith(tasks: [...state.tasks, newTask]);
  }

  /// Re-calculates priorities for all tasks.
  void prioritize() {
    final sortedTasks = List<PlannedTask>.from(state.tasks)
      ..sort((a, b) => b.priority.compareTo(a.priority));
    state = state.copyWith(tasks: sortedTasks);
  }

  /// Schedules a task for a specific time.
  void schedule(String taskId, DateTime time) {
    _updateTask(taskId, (t) => t.copyWith(scheduledTime: time));
  }

  /// Reschedules a task to a new time.
  void reschedule(String taskId, DateTime newTime) {
    schedule(taskId, newTime);
  }

  /// Marks a task as complete.
  void completeTask(String taskId) {
    _updateTask(taskId, (t) => t.copyWith(isCompleted: true));
  }

  /// Generates a daily summary of planned tasks.
  String dailySummary() {
    final completed = state.tasks.where((t) => t.isCompleted).length;
    final pending = state.tasks.length - completed;
    return 'You have $completed completed tasks and $pending pending tasks today.';
  }

  /// Decomposes a major goal into structured daily tasks.
  List<PlannedTask> decomposeGoal(String goal, int daysRemaining) {
    final days = daysRemaining > 0 ? daysRemaining : 1;
    final decomposed = <PlannedTask>[];
    
    decomposed.add(PlannedTask(
      id: '${DateTime.now().microsecondsSinceEpoch}_phase1',
      title: 'Foundation & Core Concepts: $goal',
      priority: 2,
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
    ));

    if (days >= 3) {
      decomposed.add(PlannedTask(
        id: '${DateTime.now().microsecondsSinceEpoch}_phase2',
        title: 'Deep Practice & Problem Solving: $goal',
        priority: 1,
        scheduledTime: DateTime.now().add(const Duration(days: 1, hours: 14)),
      ));
    }

    decomposed.add(PlannedTask(
      id: '${DateTime.now().microsecondsSinceEpoch}_phase3',
      title: 'Final Revision & Mock Assessment: $goal',
      priority: 3,
      scheduledTime: DateTime.now().add(Duration(days: days - 1, hours: 18)),
    ));

    state = state.copyWith(tasks: [...state.tasks, ...decomposed]);
    return decomposed;
  }

  /// Detects scheduling overlaps between planned tasks.
  List<PlannedTask> detectConflicts() {
    final scheduled = state.tasks.where((t) => t.scheduledTime != null).toList();
    final conflicts = <PlannedTask>[];
    for (int i = 0; i < scheduled.length; i++) {
      for (int j = i + 1; j < scheduled.length; j++) {
        final diff = scheduled[i].scheduledTime!.difference(scheduled[j].scheduledTime!).abs();
        if (diff.inMinutes < 45) {
          if (!conflicts.contains(scheduled[i])) conflicts.add(scheduled[i]);
          if (!conflicts.contains(scheduled[j])) conflicts.add(scheduled[j]);
        }
      }
    }
    return conflicts;
  }

  /// Adaptively replans by redistributing incomplete tasks.
  void adaptivelyReplan() {
    final incomplete = state.tasks.where((t) => !t.isCompleted).toList();
    var nextSlot = DateTime.now().add(const Duration(hours: 1));
    for (final task in incomplete) {
      schedule(task.id, nextSlot);
      nextSlot = nextSlot.add(const Duration(hours: 2));
    }
  }

  void _updateTask(String taskId, PlannedTask Function(PlannedTask) updateFn) {
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        return updateFn(t);
      }
      return t;
    }).toList();
    state = state.copyWith(tasks: updatedTasks);
  }
}

/// Provider for the PlanningEngine.
final planningEngineProvider = StateNotifierProvider<PlanningEngine, PlanningState>((ref) {
  return PlanningEngine();
});

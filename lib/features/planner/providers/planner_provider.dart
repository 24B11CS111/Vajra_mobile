import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planner_model.dart';
import '../models/calendar_event_model.dart';
import '../services/planner_repository.dart';

// --- PLANNER TASKS NOTIFIER ---
class PlannerNotifier extends StateNotifier<AsyncValue<List<PlannerTask>>> {
  final PlannerRepository _repository;

  PlannerNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      // 1. Immediately present cached tasks if available
      final cached = await _repository.localDataSource.getCachedTasks();
      if (cached != null && cached.isNotEmpty && state.valueOrNull == null) {
        state = AsyncValue.data(cached);
      }

      // 2. Fetch remote (or fallback to cache)
      final response = await _repository.getTasks(DateTime.now());
      if (response.data != null) {
        state = AsyncValue.data(response.data!);
      } else if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (_) {
      final cached = await _repository.localDataSource.getCachedTasks();
      state = AsyncValue.data(cached ?? []);
    }
  }

  Future<bool> createTask({
    required String title,
    String? description,
    String category = 'Study',
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'category': category,
      'priority': priority,
    };
    if (description != null) data['description'] = description;
    if (dueDate != null) data['due_date'] = dueDate.toIso8601String();

    final res = await _repository.createTask(data);
    if (res.isSuccess) {
      await loadTasks();
      return true;
    }
    return false;
  }

  Future<void> toggleCompletion(String id) async {
    state.whenData((tasks) {
      final newTasks = tasks.map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t).toList();
      state = AsyncValue.data(newTasks);
      _repository.toggleTaskCompletion(id, newTasks.firstWhere((t) => t.id == id).isCompleted);
    });
  }

  Future<bool> deleteTask(String id) async {
    final res = await _repository.deleteTask(id);
    if (res.isSuccess) {
      await loadTasks();
      return true;
    }
    return false;
  }

  void reorderTasks(int oldIndex, int newIndex) {
    state.whenData((tasks) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, item);
      final updatedList = List<PlannerTask>.from(tasks);
      state = AsyncValue.data(updatedList);
      _repository.reorderTasks(updatedList.map((t) => t.id).toList());
    });
  }
}

final plannerProvider = StateNotifierProvider<PlannerNotifier, AsyncValue<List<PlannerTask>>>((ref) {
  return PlannerNotifier(ref.watch(plannerRepositoryProvider));
});

// --- CALENDAR EVENTS NOTIFIER ---
class CalendarEventsNotifier extends StateNotifier<AsyncValue<List<CalendarEventModel>>> {
  final PlannerRepository _repository;

  CalendarEventsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents({DateTime? startDate, DateTime? endDate, String? eventType}) async {
    try {
      final cached = await _repository.localDataSource.getCachedCalendarEvents();
      if (cached != null && cached.isNotEmpty && state.valueOrNull == null) {
        state = AsyncValue.data(cached);
      }

      final response = await _repository.getCalendarEvents(
        startDate: startDate,
        endDate: endDate,
        eventType: eventType,
      );
      if (response.data != null) {
        state = AsyncValue.data(response.data!);
      } else if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (_) {
      final cached = await _repository.localDataSource.getCachedCalendarEvents();
      state = AsyncValue.data(cached ?? []);
    }
  }

  Future<bool> createEvent({
    required String title,
    String? description,
    String eventType = 'study_session',
    required DateTime startTime,
    DateTime? endTime,
    bool isAllDay = false,
    String? location,
    String color = '#8B5CF6',
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'event_type': eventType,
      'start_time': startTime.toIso8601String(),
      'is_all_day': isAllDay,
      'color': color,
    };
    if (description != null) data['description'] = description;
    if (endTime != null) data['end_time'] = endTime.toIso8601String();
    if (location != null) data['location'] = location;

    final res = await _repository.createCalendarEvent(data);
    if (res.isSuccess) {
      await loadEvents();
      return true;
    }
    return false;
  }

  Future<bool> updateEvent(String id, Map<String, dynamic> data) async {
    final res = await _repository.updateCalendarEvent(id, data);
    if (res.isSuccess) {
      await loadEvents();
      return true;
    }
    return false;
  }

  Future<bool> deleteEvent(String id) async {
    final res = await _repository.deleteCalendarEvent(id);
    if (res.isSuccess) {
      await loadEvents();
      return true;
    }
    return false;
  }
}

final calendarEventsProvider = StateNotifierProvider<CalendarEventsNotifier, AsyncValue<List<CalendarEventModel>>>((ref) {
  return CalendarEventsNotifier(ref.watch(plannerRepositoryProvider));
});

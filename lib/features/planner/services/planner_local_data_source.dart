import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/planner_model.dart';
import '../models/calendar_event_model.dart';

abstract class PlannerLocalDataSource {
  Future<void> cacheTasks(List<PlannerTask> tasks);
  Future<List<PlannerTask>?> getCachedTasks();
  Future<void> saveTask(PlannerTask task);
  Future<void> deleteTask(String id);

  Future<void> cacheCalendarEvents(List<CalendarEventModel> events);
  Future<List<CalendarEventModel>?> getCachedCalendarEvents();
  Future<void> saveCalendarEvent(CalendarEventModel event);
  Future<void> deleteCalendarEvent(String id);

  Future<void> clearCache();
}

class PlannerLocalDataSourceImpl implements PlannerLocalDataSource {
  static const String _tasksKey = 'cached_planner_tasks';
  static const String _eventsKey = 'cached_calendar_events';
  final String? _explicitUserId;
  static final Map<String, List<String>> _fallbackMemory = {};

  PlannerLocalDataSourceImpl({String? userId}) : _explicitUserId = userId;

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<String> _getScopedKey(String baseKey) async {
    if (_explicitUserId != null && _explicitUserId.isNotEmpty) {
      return 'vajra_${_explicitUserId}_$baseKey';
    }
    final prefs = await _getPrefs();
    final userId = prefs?.getString('vajra_current_user_id');
    if (userId != null && userId.isNotEmpty) {
      return 'vajra_${userId}_$baseKey';
    }
    return 'vajra_$baseKey';
  }

  @override
  Future<void> cacheTasks(List<PlannerTask> tasks) async {
    final key = await _getScopedKey(_tasksKey);
    final jsonList = tasks.map((t) => jsonEncode(t.toJson())).toList();
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setStringList(key, jsonList);
    } else {
      _fallbackMemory[key] = jsonList;
    }
  }

  @override
  Future<List<PlannerTask>?> getCachedTasks() async {
    final key = await _getScopedKey(_tasksKey);
    final prefs = await _getPrefs();
    final jsonList = prefs != null ? prefs.getStringList(key) : _fallbackMemory[key];
    if (jsonList != null) {
      try {
        return jsonList.map((j) => PlannerTask.fromJson(jsonDecode(j) as Map<String, dynamic>)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveTask(PlannerTask task) async {
    final current = await getCachedTasks() ?? [];
    final index = current.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      current[index] = task;
    } else {
      current.insert(0, task);
    }
    await cacheTasks(current);
  }

  @override
  Future<void> deleteTask(String id) async {
    final current = await getCachedTasks() ?? [];
    current.removeWhere((t) => t.id == id);
    await cacheTasks(current);
  }

  @override
  Future<void> cacheCalendarEvents(List<CalendarEventModel> events) async {
    final key = await _getScopedKey(_eventsKey);
    final jsonList = events.map((e) => jsonEncode(e.toJson())).toList();
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setStringList(key, jsonList);
    } else {
      _fallbackMemory[key] = jsonList;
    }
  }

  @override
  Future<List<CalendarEventModel>?> getCachedCalendarEvents() async {
    final key = await _getScopedKey(_eventsKey);
    final prefs = await _getPrefs();
    final jsonList = prefs != null ? prefs.getStringList(key) : _fallbackMemory[key];
    if (jsonList != null) {
      try {
        return jsonList.map((j) => CalendarEventModel.fromJson(jsonDecode(j) as Map<String, dynamic>)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveCalendarEvent(CalendarEventModel event) async {
    final current = await getCachedCalendarEvents() ?? [];
    final index = current.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      current[index] = event;
    } else {
      current.insert(0, event);
    }
    await cacheCalendarEvents(current);
  }

  @override
  Future<void> deleteCalendarEvent(String id) async {
    final current = await getCachedCalendarEvents() ?? [];
    current.removeWhere((e) => e.id == id);
    await cacheCalendarEvents(current);
  }

  @override
  Future<void> clearCache() async {
    final tasksKey = await _getScopedKey(_tasksKey);
    final eventsKey = await _getScopedKey(_eventsKey);
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.remove(tasksKey);
      await prefs.remove(eventsKey);
    }
    _fallbackMemory.remove(tasksKey);
    _fallbackMemory.remove(eventsKey);
  }
}

final plannerLocalDataSourceProvider = Provider<PlannerLocalDataSource>((ref) {
  return PlannerLocalDataSourceImpl();
});

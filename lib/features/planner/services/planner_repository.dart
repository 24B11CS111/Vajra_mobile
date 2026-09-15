import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/intelligence/sync/sync_queue.dart';
import '../models/planner_model.dart';
import '../models/calendar_event_model.dart';
import 'planner_local_data_source.dart';

abstract class PlannerRepository {
  Future<ApiResponse<List<PlannerTask>>> getTasks(DateTime date);
  Future<ApiResponse<PlannerTask>> createTask(Map<String, dynamic> data);
  Future<ApiResponse<bool>> toggleTaskCompletion(String id, bool isCompleted);
  Future<ApiResponse<void>> deleteTask(String id);
  Future<ApiResponse<void>> reorderTasks(List<String> taskIds);

  Future<ApiResponse<List<CalendarEventModel>>> getCalendarEvents({DateTime? startDate, DateTime? endDate, String? eventType});
  Future<ApiResponse<CalendarEventModel>> createCalendarEvent(Map<String, dynamic> data);
  Future<ApiResponse<CalendarEventModel>> updateCalendarEvent(String id, Map<String, dynamic> data);
  Future<ApiResponse<void>> deleteCalendarEvent(String id);

  PlannerLocalDataSource get localDataSource;
}

class PlannerRepositoryImpl implements PlannerRepository {
  final ApiClient _apiClient;
  final PlannerLocalDataSource _localDataSource;
  final SyncQueue? _syncQueue;

  PlannerRepositoryImpl(
    this._apiClient, [
    PlannerLocalDataSource? localDataSource,
    this._syncQueue,
  ]) : _localDataSource = localDataSource ?? PlannerLocalDataSourceImpl();

  @override
  PlannerLocalDataSource get localDataSource => _localDataSource;

  PlannerTask _fromBackendJson(Map<String, dynamic> json) {
    DateTime? rawStart;
    if (json['due_date'] != null) {
      rawStart = DateTime.tryParse(json['due_date'].toString());
    } else if (json['startTime'] != null) {
      rawStart = DateTime.tryParse(json['startTime'].toString());
    } else if (json['start_time'] != null) {
      rawStart = DateTime.tryParse(json['start_time'].toString());
    }
    final start = rawStart?.toLocal() ?? DateTime.now();

    DateTime? rawEnd;
    if (json['endTime'] != null) {
      rawEnd = DateTime.tryParse(json['endTime'].toString());
    } else if (json['end_time'] != null) {
      rawEnd = DateTime.tryParse(json['end_time'].toString());
    }
    final end = rawEnd?.toLocal() ?? start.add(const Duration(hours: 1));

    return PlannerTask(
      id: json['id']?.toString() ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      startTime: start,
      endTime: end,
      isCompleted: json['is_completed'] == true || json['isCompleted'] == true,
      aiSuggestion: json['aiSuggestion'] ?? json['description'],
    );
  }

  @override
  Future<ApiResponse<List<PlannerTask>>> getTasks(DateTime date) async {
    final cached = await _localDataSource.getCachedTasks();

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.plannerTasks);
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => _fromBackendJson(item as Map<String, dynamic>))
            .toList();

        await _localDataSource.cacheTasks(list);
        _syncQueue?.setOnlineStatus(true);
        return ApiResponse.success(list);
      }
      return ApiResponse.success(cached ?? const []);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      // Offline fallback: return cached tasks with no raw technical error
      return ApiResponse.success(cached ?? const []);
    }
  }

  @override
  Future<ApiResponse<PlannerTask>> createTask(Map<String, dynamic> data) async {
    // 1. Create local task first
    final localId = data['id']?.toString() ?? 'task_${DateTime.now().millisecondsSinceEpoch}';
    final localTask = _fromBackendJson({...data, 'id': localId});
    await _localDataSource.saveTask(localTask);

    // 2. Attempt remote sync
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.plannerTasks, data: data);
      final serverTask = _fromBackendJson(response.data as Map<String, dynamic>);
      // Replace temporary local ID with server ID if different
      if (serverTask.id != localTask.id) {
        await _localDataSource.deleteTask(localTask.id);
        await _localDataSource.saveTask(serverTask);
      }
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(serverTask);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      // Offline: Enqueue for background sync
      await _syncQueue?.enqueue(
        entityType: 'planner_task',
        entityId: localTask.id,
        operation: SyncOperationType.create,
        payload: data,
      );
      // Return local task immediately so UI is optimistic and responsive
      return ApiResponse.success(localTask);
    }
  }

  @override
  Future<ApiResponse<bool>> toggleTaskCompletion(String id, bool isCompleted) async {
    // 1. Update local cache first
    final cached = await _localDataSource.getCachedTasks();
    if (cached != null) {
      final idx = cached.indexWhere((t) => t.id == id);
      if (idx >= 0) {
        cached[idx] = cached[idx].copyWith(isCompleted: isCompleted);
        await _localDataSource.cacheTasks(cached);
      }
    }

    // 2. Attempt remote sync
    try {
      await _apiClient.dio.post('${ApiEndpoints.plannerTasks}/$id/toggle');
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(true);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'planner_task',
        entityId: id,
        operation: SyncOperationType.update,
        payload: {'is_completed': isCompleted},
      );
      return ApiResponse.success(true);
    }
  }

  @override
  Future<ApiResponse<void>> deleteTask(String id) async {
    // 1. Remove from local store first
    await _localDataSource.deleteTask(id);

    // 2. Attempt remote sync
    try {
      await _apiClient.dio.delete('${ApiEndpoints.plannerTasks}/$id');
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(null);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'planner_task',
        entityId: id,
        operation: SyncOperationType.delete,
        payload: {'id': id},
      );
      return ApiResponse.success(null);
    }
  }

  @override
  Future<ApiResponse<void>> reorderTasks(List<String> taskIds) async {
    try {
      await _apiClient.dio.post('${ApiEndpoints.plannerTasks}/reorder', data: {'task_ids': taskIds});
      return ApiResponse.success(null);
    } catch (_) {
      return ApiResponse.success(null);
    }
  }

  @override
  Future<ApiResponse<List<CalendarEventModel>>> getCalendarEvents({DateTime? startDate, DateTime? endDate, String? eventType}) async {
    final cached = await _localDataSource.getCachedCalendarEvents();

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (eventType != null) queryParams['event_type'] = eventType;

      final response = await _apiClient.dio.get(ApiEndpoints.calendarEvents, queryParameters: queryParams);
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => CalendarEventModel.fromJson(item as Map<String, dynamic>))
            .toList();

        await _localDataSource.cacheCalendarEvents(list);
        _syncQueue?.setOnlineStatus(true);
        return ApiResponse.success(list);
      }
      return ApiResponse.success(cached ?? const []);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      return ApiResponse.success(cached ?? const []);
    }
  }

  @override
  Future<ApiResponse<CalendarEventModel>> createCalendarEvent(Map<String, dynamic> data) async {
    final localId = data['id']?.toString() ?? 'event_${DateTime.now().millisecondsSinceEpoch}';
    final localEvent = CalendarEventModel.fromJson({
      ...data,
      'id': localId,
      'user_id': data['user_id'] ?? 'local_user',
      'title': data['title'] ?? 'New Event',
      'start_time': data['start_time'] ?? DateTime.now().toIso8601String(),
    });
    await _localDataSource.saveCalendarEvent(localEvent);

    try {
      final response = await _apiClient.dio.post(ApiEndpoints.calendarEvents, data: data);
      final serverEvent = CalendarEventModel.fromJson(response.data as Map<String, dynamic>);
      if (serverEvent.id != localEvent.id) {
        await _localDataSource.deleteCalendarEvent(localEvent.id);
        await _localDataSource.saveCalendarEvent(serverEvent);
      }
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(serverEvent);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'calendar_event',
        entityId: localEvent.id,
        operation: SyncOperationType.create,
        payload: data,
      );
      return ApiResponse.success(localEvent);
    }
  }

  @override
  Future<ApiResponse<CalendarEventModel>> updateCalendarEvent(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiEndpoints.calendarEvents}/$id', data: data);
      final updated = CalendarEventModel.fromJson(response.data as Map<String, dynamic>);
      await _localDataSource.saveCalendarEvent(updated);
      return ApiResponse.success(updated);
    } catch (_) {
      return ApiResponse.error("Unable to update calendar event offline.");
    }
  }

  @override
  Future<ApiResponse<void>> deleteCalendarEvent(String id) async {
    await _localDataSource.deleteCalendarEvent(id);
    try {
      await _apiClient.dio.delete('${ApiEndpoints.calendarEvents}/$id');
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(null);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'calendar_event',
        entityId: id,
        operation: SyncOperationType.delete,
        payload: {'id': id},
      );
      return ApiResponse.success(null);
    }
  }
}

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(plannerLocalDataSourceProvider),
    ref.watch(syncQueueProvider.notifier),
  );
});

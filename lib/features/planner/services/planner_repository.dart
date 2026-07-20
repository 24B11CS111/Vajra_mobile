import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/planner_model.dart';

abstract class PlannerRemoteDataSource {
  Future<List<PlannerTask>> getTasks(DateTime date);
  Future<void> toggleTaskCompletion(String id, bool isCompleted);
}

class PlannerRemoteDataSourceImpl implements PlannerRemoteDataSource {
  final ApiClient _apiClient;

  PlannerRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<PlannerTask>> getTasks(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      PlannerTask(
        id: '1',
        title: 'Physics Revision',
        category: 'Exams',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        isCompleted: false,
      ),
      PlannerTask(
        id: '2',
        title: 'Gym',
        category: 'Habits',
        startTime: DateTime.now().add(const Duration(hours: 4)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
        isCompleted: false,
        aiSuggestion: "Move Gym to 6 PM because you have an exam revision at 5 PM.",
      )
    ];
  }

  @override
  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

abstract class PlannerLocalDataSource {
  Future<void> cacheTasks(DateTime date, List<PlannerTask> tasks);
  Future<List<PlannerTask>?> getCachedTasks(DateTime date);
}

class PlannerLocalDataSourceImpl implements PlannerLocalDataSource {
  String _getCacheKey(DateTime date) => 'cached_tasks_${date.year}_${date.month}_${date.day}';

  @override
  Future<void> cacheTasks(DateTime date, List<PlannerTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_getCacheKey(date), jsonList);
  }

  @override
  Future<List<PlannerTask>?> getCachedTasks(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_getCacheKey(date));
    if (jsonList != null) {
      try {
        return jsonList.map((j) => PlannerTask.fromJson(jsonDecode(j))).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

abstract class PlannerRepository {
  Future<ApiResponse<List<PlannerTask>>> getTasks(DateTime date);
  Future<ApiResponse<bool>> toggleTaskCompletion(String id, bool isCompleted);
}

class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerRemoteDataSource _remoteDataSource;
  final PlannerLocalDataSource _localDataSource;

  PlannerRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<List<PlannerTask>>> getTasks(DateTime date) async {
    try {
      final tasks = await _remoteDataSource.getTasks(date);
      await _localDataSource.cacheTasks(date, tasks);
      return ApiResponse.success(tasks);
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedTasks(date);
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.message ?? 'Network error and no cache');
    } catch (e) {
      final cached = await _localDataSource.getCachedTasks(date);
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> toggleTaskCompletion(String id, bool isCompleted) async {
    try {
      await _remoteDataSource.toggleTaskCompletion(id, isCompleted);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

final plannerRemoteDataSourceProvider = Provider<PlannerRemoteDataSource>((ref) {
  return PlannerRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final plannerLocalDataSourceProvider = Provider<PlannerLocalDataSource>((ref) {
  return PlannerLocalDataSourceImpl();
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepositoryImpl(
    ref.watch(plannerRemoteDataSourceProvider),
    ref.watch(plannerLocalDataSourceProvider),
  );
});

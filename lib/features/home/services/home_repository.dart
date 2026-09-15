import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/briefing_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class HomeRemoteDataSource {
  Future<BriefingModel> getBriefing();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  // ignore: unused_field
  final ApiClient _apiClient;

  HomeRemoteDataSourceImpl(this._apiClient);

  @override
  Future<BriefingModel> getBriefing() async {
    try {
      final response = await _apiClient.get('/home/briefing');
      if (response.data is Map<String, dynamic>) {
        return BriefingModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // If remote briefing endpoint is unavailable, compute dynamic briefing from local time
    }

    final now = DateTime.now();
    final hour = now.hour;
    final timeTitle = hour < 12
        ? 'Morning Briefing'
        : hour < 17
            ? 'Afternoon Briefing'
            : 'Evening Wrap-Up';
    final greeting = hour < 12
        ? 'Good morning. Let\'s review your schedule and focus areas for today.'
        : hour < 17
            ? 'Good afternoon. Hope your day is going productively.'
            : 'Good evening. Review your achievements and rest well.';

    return BriefingModel(
      title: timeTitle,
      message: greeting,
      weatherContext: 'Schedule synchronized with device local time.',
      priorityTaskTitle: 'Daily Priorities',
      priorityTaskSubtitle: 'Check Planner for today\'s tasks and study blocks.',
      eveningWrapUp: 'Stay consistent with your personal goals.',
    );
  }
}

abstract class HomeLocalDataSource {
  Future<void> cacheBriefing(BriefingModel briefing);
  Future<BriefingModel?> getCachedBriefing();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  static const String _briefingCacheKey = 'cached_briefing';

  @override
  Future<void> cacheBriefing(BriefingModel briefing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_briefingCacheKey, jsonEncode(briefing.toJson()));
  }

  @override
  Future<BriefingModel?> getCachedBriefing() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_briefingCacheKey);
    if (jsonString != null) {
      try {
        return BriefingModel.fromJson(jsonDecode(jsonString));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

abstract class HomeRepository {
  Future<ApiResponse<BriefingModel>> getBriefing();
}

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;

  HomeRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<BriefingModel>> getBriefing() async {
    try {
      final briefing = await _remoteDataSource.getBriefing();
      await _localDataSource.cacheBriefing(briefing);
      return ApiResponse.success(briefing);
    } on DioException catch (e) {
      // Offline fallback
      final cached = await _localDataSource.getCachedBriefing();
      if (cached != null) {
        return ApiResponse.success(cached);
      }
      return ApiResponse.error(e.message ?? 'Network error and no cache available');
    } catch (e) {
      // Offline fallback
      final cached = await _localDataSource.getCachedBriefing();
      if (cached != null) {
        return ApiResponse.success(cached);
      }
      return ApiResponse.error(e.toString());
    }
  }
}

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  return HomeLocalDataSourceImpl();
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    ref.watch(homeRemoteDataSourceProvider),
    ref.watch(homeLocalDataSourceProvider),
  );
});

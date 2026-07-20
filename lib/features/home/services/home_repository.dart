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
  final ApiClient _apiClient;

  HomeRemoteDataSourceImpl(this._apiClient);

  @override
  Future<BriefingModel> getBriefing() async {
    // In real implementation:
    // final response = await _apiClient.get('/home/briefing');
    // return BriefingModel.fromJson(response.data);
    
    // Simulating API for now to prevent breaking while no backend exists
    await Future.delayed(const Duration(milliseconds: 600));
    return const BriefingModel(
      title: 'Morning Briefing',
      message: 'Good Morning.\nYour primary focus today is Quantum Physics.',
      weatherContext: 'Sunny, 22°C. A good day for a walk.',
      priorityTaskTitle: 'Priority Task',
      priorityTaskSubtitle: 'Physics Revision at 10:00 AM',
      eveningWrapUp: 'You completed 4 out of 5 tasks today.',
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

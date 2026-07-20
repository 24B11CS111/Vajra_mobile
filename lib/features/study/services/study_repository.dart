import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/study_session_model.dart';

abstract class StudyRemoteDataSource {
  Future<List<StudySessionModel>> getUpcomingSessions();
}

class StudyRemoteDataSourceImpl implements StudyRemoteDataSource {
  final ApiClient _apiClient;

  StudyRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<StudySessionModel>> getUpcomingSessions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      StudySessionModel(
        id: 's_1',
        subject: 'Computer Science',
        topic: 'Operating Systems - Deadlocks',
        durationMinutes: 45,
        progress: 0.0,
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
      ),
      StudySessionModel(
        id: 's_2',
        subject: 'Mathematics',
        topic: 'Linear Algebra - Eigenvectors',
        durationMinutes: 60,
        progress: 0.3,
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      ),
    ];
  }
}

abstract class StudyLocalDataSource {
  Future<void> cacheSessions(List<StudySessionModel> sessions);
  Future<List<StudySessionModel>?> getCachedSessions();
}

class StudyLocalDataSourceImpl implements StudyLocalDataSource {
  static const String _cacheKey = 'cached_study_sessions';

  @override
  Future<void> cacheSessions(List<StudySessionModel> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonList);
  }

  @override
  Future<List<StudySessionModel>?> getCachedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cacheKey);
    if (jsonList != null) {
      try {
        return jsonList.map((j) => StudySessionModel.fromJson(jsonDecode(j))).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

abstract class StudyRepository {
  Future<ApiResponse<List<StudySessionModel>>> getUpcomingSessions();
}

class StudyRepositoryImpl implements StudyRepository {
  final StudyRemoteDataSource _remoteDataSource;
  final StudyLocalDataSource _localDataSource;

  StudyRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<List<StudySessionModel>>> getUpcomingSessions() async {
    try {
      final sessions = await _remoteDataSource.getUpcomingSessions();
      await _localDataSource.cacheSessions(sessions);
      return ApiResponse.success(sessions);
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedSessions();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.message ?? 'Network error');
    } catch (e) {
      final cached = await _localDataSource.getCachedSessions();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.toString());
    }
  }
}

final studyRemoteDataSourceProvider = Provider<StudyRemoteDataSource>((ref) {
  return StudyRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final studyLocalDataSourceProvider = Provider<StudyLocalDataSource>((ref) {
  return StudyLocalDataSourceImpl();
});

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepositoryImpl(
    ref.watch(studyRemoteDataSourceProvider),
    ref.watch(studyLocalDataSourceProvider),
  );
});

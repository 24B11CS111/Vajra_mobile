import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> clearAll();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      NotificationModel(
        id: 'n1',
        message: 'Good Morning.\nYou have one hour before your Data Structures lecture.\nWould you like a quick revision session?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      NotificationModel(
        id: 'n2',
        message: 'Good Evening.\nYou completed every planned task today.\nExcellent work.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> clearAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

abstract class NotificationLocalDataSource {
  Future<void> cacheNotifications(List<NotificationModel> notifications);
  Future<List<NotificationModel>?> getCachedNotifications();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  static const String _cacheKey = 'cached_notifications';

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonList);
  }

  @override
  Future<List<NotificationModel>?> getCachedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cacheKey);
    if (jsonList != null) {
      try {
        return jsonList.map((j) => NotificationModel.fromJson(jsonDecode(j))).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

abstract class NotificationRepository {
  Future<ApiResponse<List<NotificationModel>>> getNotifications();
  Future<ApiResponse<bool>> markAsRead(String id);
  Future<ApiResponse<bool>> clearAll();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationLocalDataSource _localDataSource;

  NotificationRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    try {
      final notifications = await _remoteDataSource.getNotifications();
      await _localDataSource.cacheNotifications(notifications);
      return ApiResponse.success(notifications);
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedNotifications();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.message ?? 'Network error and no cache');
    } catch (e) {
      final cached = await _localDataSource.getCachedNotifications();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> markAsRead(String id) async {
    try {
      await _remoteDataSource.markAsRead(id);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> clearAll() async {
    try {
      await _remoteDataSource.clearAll();
      await _localDataSource.cacheNotifications([]);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSourceImpl();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteDataSourceProvider),
    ref.watch(notificationLocalDataSourceProvider),
  );
});

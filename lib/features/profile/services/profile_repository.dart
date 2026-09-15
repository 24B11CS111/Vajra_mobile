import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/user_profile_model.dart';
import '../models/companion_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<UserProfileModel> updateUserProfile(String name);
  Future<CompanionProfileModel> getCompanionProfile();
  Future<void> updateCompanionProfile(CompanionProfileModel profile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfileModel> getUserProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return UserProfileModel(
          id: data['id']?.toString() ?? '',
          name: data['display_name'] ?? data['full_name'] ?? data['name'] ?? (data['email'] != null ? data['email'].toString().split('@').first : 'VAJRA User'),
          email: data['email']?.toString() ?? '',
          avatarUrl: data['avatar_url']?.toString(),
        );
      }
      return const UserProfileModel(id: '', name: 'VAJRA User', email: '');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch user profile');
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(String name) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.me, data: {'display_name': name});
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return UserProfileModel(
          id: data['id']?.toString() ?? '',
          name: data['display_name'] ?? data['full_name'] ?? name,
          email: data['email']?.toString() ?? '',
          avatarUrl: data['avatar_url']?.toString(),
        );
      }
      return UserProfileModel(id: '', name: name, email: '');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update user profile');
    }
  }

  @override
  Future<CompanionProfileModel> getCompanionProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cached_companion_profile');
    if (jsonString != null) {
      try {
        return CompanionProfileModel.fromJson(jsonDecode(jsonString));
      } catch (_) {}
    }
    return const CompanionProfileModel();
  }

  @override
  Future<void> updateCompanionProfile(CompanionProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_companion_profile', jsonEncode(profile.toJson()));
  }
}

abstract class ProfileLocalDataSource {
  Future<void> cacheUserProfile(UserProfileModel profile);
  Future<UserProfileModel?> getCachedUserProfile();
  Future<void> cacheCompanionProfile(CompanionProfileModel profile);
  Future<CompanionProfileModel?> getCachedCompanionProfile();
  Future<void> clearCache([String? userId]);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  static const String _userCacheKey = 'cached_user_profile';
  static const String _companionCacheKey = 'cached_companion_profile';
  final String? _explicitUserId;

  ProfileLocalDataSourceImpl({String? userId}) : _explicitUserId = userId;

  Future<String> _getScopedKey(String baseKey) async {
    if (_explicitUserId != null && _explicitUserId.isNotEmpty) {
      return 'vajra_${_explicitUserId}_$baseKey';
    }
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('vajra_current_user_id');
    if (userId != null && userId.isNotEmpty) {
      return 'vajra_${userId}_$baseKey';
    }
    return 'vajra_$baseKey';
  }

  @override
  Future<void> cacheUserProfile(UserProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_userCacheKey);
    await prefs.setString(key, jsonEncode(profile.toJson()));
  }

  @override
  Future<UserProfileModel?> getCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_userCacheKey);
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      try {
        return UserProfileModel.fromJson(jsonDecode(jsonString));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> cacheCompanionProfile(CompanionProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_companionCacheKey);
    await prefs.setString(key, jsonEncode(profile.toJson()));
  }

  @override
  Future<CompanionProfileModel?> getCachedCompanionProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_companionCacheKey);
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      try {
        return CompanionProfileModel.fromJson(jsonDecode(jsonString));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> clearCache([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    final targetId = userId ?? _explicitUserId ?? prefs.getString('vajra_current_user_id');
    if (targetId != null && targetId.isNotEmpty) {
      await prefs.remove('vajra_${targetId}_$_userCacheKey');
      await prefs.remove('vajra_${targetId}_$_companionCacheKey');
    }
    await prefs.remove(_userCacheKey);
    await prefs.remove(_companionCacheKey);
    await prefs.remove('vajra_$_userCacheKey');
    await prefs.remove('vajra_$_companionCacheKey');
  }
}

abstract class ProfileRepository {
  Future<ApiResponse<UserProfileModel>> getUserProfile();
  Future<ApiResponse<UserProfileModel>> updateUserProfile(String name);
  Future<ApiResponse<CompanionProfileModel>> getCompanionProfile();
  Future<ApiResponse<bool>> updateCompanionProfile(CompanionProfileModel profile);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;

  ProfileRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<UserProfileModel>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('vajra_current_user_id');

    if (currentUserId == 'guest_user') {
      final cached = await _localDataSource.getCachedUserProfile();
      if (cached != null && cached.name.trim().isNotEmpty) {
        return ApiResponse.success(cached);
      }
      const guestProfile = UserProfileModel(
        id: 'guest_user',
        name: 'Guest',
        email: 'guest@vajra.local',
      );
      await _localDataSource.cacheUserProfile(guestProfile);
      return ApiResponse.success(guestProfile);
    }

    try {
      final profile = await _remoteDataSource.getUserProfile();
      await _localDataSource.cacheUserProfile(profile);
      return ApiResponse.success(profile);
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedUserProfile();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.message ?? 'Network error');
    } catch (e) {
      final cached = await _localDataSource.getCachedUserProfile();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<UserProfileModel>> updateUserProfile(String name) async {
    try {
      final profile = await _remoteDataSource.updateUserProfile(name);
      await _localDataSource.cacheUserProfile(profile);
      return ApiResponse.success(profile);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<CompanionProfileModel>> getCompanionProfile() async {
    try {
      final profile = await _remoteDataSource.getCompanionProfile();
      await _localDataSource.cacheCompanionProfile(profile);
      return ApiResponse.success(profile);
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedCompanionProfile();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.message ?? 'Network error');
    } catch (e) {
      final cached = await _localDataSource.getCachedCompanionProfile();
      if (cached != null) return ApiResponse.success(cached);
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> updateCompanionProfile(CompanionProfileModel profile) async {
    try {
      await _remoteDataSource.updateCompanionProfile(profile);
      await _localDataSource.cacheCompanionProfile(profile);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSourceImpl();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileRemoteDataSourceProvider),
    ref.watch(profileLocalDataSourceProvider),
  );
});

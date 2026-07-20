import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/user_profile_model.dart';
import '../models/companion_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile();
  Future<CompanionProfileModel> getCompanionProfile();
  Future<void> updateCompanionProfile(CompanionProfileModel profile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfileModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const UserProfileModel(
      id: 'usr_123',
      name: 'Alex',
      email: 'alex@example.com',
    );
  }

  @override
  Future<CompanionProfileModel> getCompanionProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const CompanionProfileModel();
  }

  @override
  Future<void> updateCompanionProfile(CompanionProfileModel profile) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

abstract class ProfileLocalDataSource {
  Future<void> cacheUserProfile(UserProfileModel profile);
  Future<UserProfileModel?> getCachedUserProfile();
  Future<void> cacheCompanionProfile(CompanionProfileModel profile);
  Future<CompanionProfileModel?> getCachedCompanionProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  static const String _userCacheKey = 'cached_user_profile';
  static const String _companionCacheKey = 'cached_companion_profile';

  @override
  Future<void> cacheUserProfile(UserProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCacheKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<UserProfileModel?> getCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userCacheKey);
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
    await prefs.setString(_companionCacheKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<CompanionProfileModel?> getCachedCompanionProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_companionCacheKey);
    if (jsonString != null) {
      try {
        return CompanionProfileModel.fromJson(jsonDecode(jsonString));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

abstract class ProfileRepository {
  Future<ApiResponse<UserProfileModel>> getUserProfile();
  Future<ApiResponse<CompanionProfileModel>> getCompanionProfile();
  Future<ApiResponse<bool>> updateCompanionProfile(CompanionProfileModel profile);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;

  ProfileRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<UserProfileModel>> getUserProfile() async {
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

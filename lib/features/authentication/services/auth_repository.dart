import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/intelligence/sync/sync_queue.dart';
import '../../planner/services/planner_local_data_source.dart';
import '../../study/services/study_local_data_source.dart';
import '../../memory/services/memory_repository.dart';
import '../../profile/services/profile_repository.dart';
import '../../profile/models/user_profile_model.dart';

enum AuthProviderType { google, apple, email, guest }

abstract class AuthRemoteDataSource {
  Future<String> signup(String email, String password, String? fullName);
  Future<String> login(String username, String password);
  Future<String> socialLogin(AuthProviderType provider, String token);
  Future<void> logout(String token);
  Future<String> refreshToken(String refreshToken);
  Future<bool> validateSession(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<String> signup(String email, String password, String? fullName) async {
    try {
      final data = <String, dynamic>{'email': email, 'password': password};
      if (fullName != null) data['full_name'] = fullName;

      final response = await _apiClient.post(ApiEndpoints.signup, data: data);
      if (response.data is Map) {
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) return token.toString();
      }
      throw ApiException('Unexpected authentication response format');
    } on DioException catch (e) {
      final String msg = (e.response?.data is Map && e.response?.data['detail'] != null)
          ? e.response!.data['detail'].toString()
          : (e.message ?? 'Signup failed');
      throw ApiException(msg, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<String> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': username, 'password': password},
      );
      if (response.data is Map) {
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) return token.toString();
      }
      throw ApiException('Unexpected authentication response format');
    } on DioException catch (e) {
      final String msg = (e.response?.data is Map && e.response?.data['detail'] != null)
          ? e.response!.data['detail'].toString()
          : (e.message ?? 'Authentication request failed');
      throw ApiException(msg, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<String> socialLogin(AuthProviderType provider, String token) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.socialLogin,
        data: {'provider': provider.name, 'token': token},
      );
      if (response.data is Map) {
        final jwt = response.data['token'] ?? response.data['access_token'];
        if (jwt != null) return jwt.toString();
      }
      throw ApiException('Unexpected social authentication response format');
    } on DioException catch (e) {
      final String msg = (e.response?.data is Map && e.response?.data['detail'] != null)
          ? e.response!.data['detail'].toString()
          : (e.message ?? 'Social login failed');
      throw ApiException(msg, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> logout(String token) async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort remote logout
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );
      if (response.data is Map) {
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) return token.toString();
      }
      throw ApiException('Unexpected token refresh response');
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Token refresh failed', statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<bool> validateSession(String token) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw ApiException('Session expired or unauthorized', statusCode: status);
      }
      rethrow;
    }
  }
}

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> saveRememberLogin(bool remember);
  Future<bool> getRememberLogin();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _storage;

  AuthLocalDataSourceImpl(this._storage);

  @override
  Future<void> saveToken(String token) => _storage.saveToken(token);

  @override
  Future<String?> getToken() => _storage.getToken();

  @override
  Future<void> deleteToken() => _storage.deleteToken();
  
  @override
  Future<void> saveRememberLogin(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vajra_remember_login', remember);
  }

  @override
  Future<bool> getRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vajra_remember_login') ?? true;
  }
}

abstract class AuthRepository {
  Future<ApiResponse<bool>> signup(String email, String password, String? fullName);
  Future<ApiResponse<bool>> login(String username, String password);
  Future<ApiResponse<bool>> socialLogin(AuthProviderType provider, String token);
  Future<ApiResponse<bool>> guestLogin();
  Future<void> logout();
  Future<bool> restoreSession();
  Future<ApiResponse<bool>> refreshToken();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<ApiResponse<bool>> signup(String email, String password, String? fullName) async {
    try {
      final token = await _remoteDataSource.signup(email, password, fullName);
      await _localDataSource.saveToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vajra_current_user_id', email);
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.error(e.message ?? 'Signup network error');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> login(String username, String password) async {
    try {
      final token = await _remoteDataSource.login(username, password);
      await _localDataSource.saveToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vajra_current_user_id', username);
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.error(e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<bool>> socialLogin(AuthProviderType provider, String token) async {
    try {
      final jwtToken = await _remoteDataSource.socialLogin(provider, token);
      await _localDataSource.saveToken(jwtToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vajra_current_user_id', '${provider.name}_user');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  Future<void> _clearAllUserData([String? targetUserId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = targetUserId ?? prefs.getString('vajra_current_user_id');

      if (userId != null && userId.isNotEmpty) {
        await PlannerLocalDataSourceImpl(userId: userId).clearCache();
        await StudyLocalDataSourceImpl(userId: userId).clearCache();
        await MemoryLocalDataSourceImpl(userId: userId).clearCache();
        await ProfileLocalDataSourceImpl(userId: userId).clearCache();
      }

      // Clear unscoped and current session caches
      await PlannerLocalDataSourceImpl().clearCache();
      await StudyLocalDataSourceImpl().clearCache();
      await MemoryLocalDataSourceImpl().clearCache();
      await ProfileLocalDataSourceImpl().clearCache();
      await SyncQueue().clearQueue();

      await prefs.remove('cached_user_profile');
      await prefs.remove('cached_companion_profile');
      await prefs.remove('cached_briefing');
      await prefs.remove('cached_notifications');
      await prefs.remove('vajra_remember_login');
      await prefs.remove('vajra_permissions_setup_completed');
      await prefs.remove('vajra_current_user_id');
    } catch (_) {}
  }

  @override
  Future<ApiResponse<bool>> guestLogin() async {
    try {
      // 1. Completely clear any previous user state and cached artifacts
      await _localDataSource.deleteToken();
      await _clearAllUserData();

      // 2. Obtain guest session token
      final jwtToken = await _remoteDataSource.socialLogin(AuthProviderType.guest, 'guest_token');
      await _localDataSource.saveToken(jwtToken);

      // 3. Mark current user as guest_user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vajra_current_user_id', 'guest_user');

      // 4. Pre-populate clean isolated guest profile
      const guestProfile = UserProfileModel(
        id: 'guest_user',
        name: 'Guest',
        email: 'guest@vajra.local',
      );
      await ProfileLocalDataSourceImpl(userId: 'guest_user').cacheUserProfile(guestProfile);

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    final token = await _localDataSource.getToken();
    if (token != null) {
      try {
        await _remoteDataSource.logout(token);
      } catch (_) {
        // Ignore network error on logout
      }
    }
    await _localDataSource.deleteToken();

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('vajra_current_user_id');
    await _clearAllUserData(currentUserId);
  }

  @override
  Future<bool> restoreSession() async {
    final token = await _localDataSource.getToken();
    if (token == null || token.trim().isEmpty) return false;

    try {
      final isValid = await _remoteDataSource.validateSession(token);
      return isValid;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Token is expired or unauthorized, attempt token refresh
        final refreshRes = await refreshToken();
        if (refreshRes.isSuccess) {
          return true;
        }
        await logout();
        return false;
      }
      // Other server responses (e.g. 5xx): tolerate temporary server downtime and preserve offline session
      return true;
    } catch (_) {
      // Network failure / offline: preserve existing valid session
      return true;
    }
  }
  
  @override
  Future<ApiResponse<bool>> refreshToken() async {
    try {
      final currentToken = await _localDataSource.getToken();
      if (currentToken == null) return ApiResponse.error('No token found');
      
      final newToken = await _remoteDataSource.refreshToken(currentToken);
      await _localDataSource.saveToken(newToken);
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});

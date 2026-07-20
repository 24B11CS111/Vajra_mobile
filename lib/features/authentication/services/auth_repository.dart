import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/services/secure_storage_service.dart';

enum AuthProviderType { google, apple, email, guest }

abstract class AuthRemoteDataSource {
  Future<String> login(String username, String password);
  Future<String> socialLogin(AuthProviderType provider, String token);
  Future<void> logout(String token);
  Future<String> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<String> login(String username, String password) async {
    // Simulate network delay for real API structure
    await Future.delayed(const Duration(milliseconds: 500));
    // MOCK: Replace with real _apiClient.post when backend is ready
    // final response = await _apiClient.post('/auth/login', data: {'email': username, 'password': password});
    // return response.data['token'];
    return "mock_jwt_token_$username";
  }

  @override
  Future<String> socialLogin(AuthProviderType provider, String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return "mock_jwt_token_${provider.name}";
  }

  @override
  Future<void> logout(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // await _apiClient.post('/auth/logout');
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return "mock_refreshed_token";
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
    // In a real scenario, use shared_preferences or secure_storage with a specific key
    if (remember) {
      await _storage.saveToken("remember_true"); 
    } else {
      await _storage.deleteToken();
    }
  }

  @override
  Future<bool> getRememberLogin() async {
    // Mock implementation for the architecture
    return true;
  }
}

abstract class AuthRepository {
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
  Future<ApiResponse<bool>> login(String username, String password) async {
    try {
      final token = await _remoteDataSource.login(username, password);
      await _localDataSource.saveToken(token);
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
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  @override
  Future<ApiResponse<bool>> guestLogin() async {
    try {
      final jwtToken = await _remoteDataSource.socialLogin(AuthProviderType.guest, 'guest_token');
      await _localDataSource.saveToken(jwtToken);
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
  }

  @override
  Future<bool> restoreSession() async {
    final token = await _localDataSource.getToken();
    if (token == null) return false;
    
    // Attempt token refresh if expired, here we assume it's valid for simplicity
    return true;
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

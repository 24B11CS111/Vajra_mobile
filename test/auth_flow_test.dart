import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vajra_mobile/core/network/api_exception.dart';
import 'package:vajra_mobile/core/services/secure_storage_service.dart';
import 'package:vajra_mobile/features/authentication/providers/auth_provider.dart';
import 'package:vajra_mobile/features/authentication/services/auth_repository.dart';

class _FakeSecureStorageService implements SecureStorageService {
  String? _token;

  _FakeSecureStorageService([this._token]);

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  bool shouldValidateSucceed;
  bool isExpired;
  int guestLoginCalls = 0;

  _FakeAuthRemoteDataSource({
    this.shouldValidateSucceed = true,
    this.isExpired = false,
  });

  @override
  Future<String> login(String username, String password) async => 'real_jwt_token_123';

  @override
  Future<String> signup(String email, String password, String? fullName) async => 'real_jwt_token_456';

  @override
  Future<String> socialLogin(AuthProviderType provider, String token) async {
    if (provider == AuthProviderType.guest) {
      guestLoginCalls++;
      return 'guest_token_abc';
    }
    return 'social_token_xyz';
  }

  @override
  Future<void> logout(String token) async {}

  @override
  Future<String> refreshToken(String refreshToken) async {
    if (isExpired) {
      throw ApiException('Refresh failed', statusCode: 401);
    }
    return 'refreshed_token_789';
  }

  @override
  Future<bool> validateSession(String token) async {
    if (isExpired) {
      throw ApiException('Session expired', statusCode: 401);
    }
    return shouldValidateSucceed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow & Persistence Audit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Fresh install with no session initializes to AuthState.unauthenticated and does NOT auto-guest login', () async {
      final fakeStorage = _FakeSecureStorageService(null);
      final fakeRemote = _FakeAuthRemoteDataSource();
      final localDataSource = AuthLocalDataSourceImpl(fakeStorage);
      final repository = AuthRepositoryImpl(fakeRemote, localDataSource);

      final notifier = AuthNotifier(repository);
      // Allow async _checkAuth to execute
      await Future.delayed(const Duration(milliseconds: 100));

      // Must NOT be authenticated
      expect(notifier.state, AuthState.unauthenticated);
      // Must NOT have called guestLogin automatically
      expect(fakeRemote.guestLoginCalls, 0);
      // Secure storage must remain null
      expect(await fakeStorage.getToken(), isNull);
    });

    test('Existing valid session restores to AuthState.authenticated', () async {
      final fakeStorage = _FakeSecureStorageService('saved_valid_jwt_token');
      final fakeRemote = _FakeAuthRemoteDataSource(shouldValidateSucceed: true);
      final localDataSource = AuthLocalDataSourceImpl(fakeStorage);
      final repository = AuthRepositoryImpl(fakeRemote, localDataSource);

      final notifier = AuthNotifier(repository);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, AuthState.authenticated);
      expect(await fakeStorage.getToken(), 'saved_valid_jwt_token');
    });

    test('Expired session (401 on validation and refresh) clears token and transitions to unauthenticated', () async {
      final fakeStorage = _FakeSecureStorageService('expired_jwt_token');
      final fakeRemote = _FakeAuthRemoteDataSource(isExpired: true);
      final localDataSource = AuthLocalDataSourceImpl(fakeStorage);
      final repository = AuthRepositoryImpl(fakeRemote, localDataSource);

      final notifier = AuthNotifier(repository);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, AuthState.unauthenticated);
      // Storage token must have been purged
      expect(await fakeStorage.getToken(), isNull);
    });

    test('Explicit login persists session securely and sets AuthState.authenticated', () async {
      final fakeStorage = _FakeSecureStorageService(null);
      final fakeRemote = _FakeAuthRemoteDataSource();
      final localDataSource = AuthLocalDataSourceImpl(fakeStorage);
      final repository = AuthRepositoryImpl(fakeRemote, localDataSource);

      final notifier = AuthNotifier(repository);
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.login('user@vajra.ai', 'Secret123!');
      expect(notifier.state, AuthState.authenticated);
      expect(await fakeStorage.getToken(), 'real_jwt_token_123');
    });

    test('Logout clears secure storage, purges session caches, and sets AuthState.unauthenticated', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_profile', '{"id":"user1","name":"Alex"}');
      await prefs.setString('cached_briefing', '{"title":"briefing"}');
      await prefs.setBool('vajra_permissions_setup_completed', true);

      final fakeStorage = _FakeSecureStorageService('user1_jwt_token');
      final fakeRemote = _FakeAuthRemoteDataSource();
      final localDataSource = AuthLocalDataSourceImpl(fakeStorage);
      final repository = AuthRepositoryImpl(fakeRemote, localDataSource);

      final notifier = AuthNotifier(repository);
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.logout();
      expect(notifier.state, AuthState.unauthenticated);
      expect(await fakeStorage.getToken(), isNull);

      // Verify caches are cleaned to ensure complete user isolation
      expect(prefs.getString('cached_user_profile'), isNull);
      expect(prefs.getString('cached_briefing'), isNull);
      expect(prefs.getBool('vajra_permissions_setup_completed'), isNull);
    });
  });
}

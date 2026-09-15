import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vajra_mobile/core/services/secure_storage_service.dart';
import 'package:vajra_mobile/features/authentication/services/auth_repository.dart';

class _MockSecureStorage extends SecureStorageService {
  String? token;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> saveToken(String t) async => token = t;
  @override
  Future<void> deleteToken() async => token = null;
}

class _MockRemoteDataSource implements AuthRemoteDataSource {
  String? loggedInEmail;
  String? loggedOutToken;

  @override
  Future<String> signup(String email, String password, String? fullName) async => 'signed_up_token';

  @override
  Future<String> login(String username, String password) async {
    loggedInEmail = username;
    return 'logged_in_token';
  }

  @override
  Future<String> socialLogin(AuthProviderType provider, String token) async => 'social_jwt';

  @override
  Future<void> logout(String token) async {
    loggedOutToken = token;
  }

  @override
  Future<String> refreshToken(String refreshToken) async => 'new_refresh_token';

  @override
  Future<bool> validateSession(String token) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository Unit Tests', () {
    late _MockSecureStorage storage;
    late _MockRemoteDataSource remote;
    late AuthLocalDataSource local;
    late AuthRepositoryImpl repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = _MockSecureStorage();
      remote = _MockRemoteDataSource();
      local = AuthLocalDataSourceImpl(storage);
      repo = AuthRepositoryImpl(remote, local);
    });

    test('login saves token into local storage on success', () async {
      final res = await repo.login('test@vajra.ai', 'Secret123');
      expect(res.isSuccess, isTrue);
      expect(await storage.getToken(), 'logged_in_token');
      expect(remote.loggedInEmail, 'test@vajra.ai');
    });

    test('signup saves token into local storage on success', () async {
      final res = await repo.signup('new@vajra.ai', 'Secret123', 'New User');
      expect(res.isSuccess, isTrue);
      expect(await storage.getToken(), 'signed_up_token');
    });

    test('guestLogin saves guest token', () async {
      final res = await repo.guestLogin();
      expect(res.isSuccess, isTrue);
      expect(await storage.getToken(), 'social_jwt');
    });

    test('restoreSession returns true when token is valid', () async {
      await storage.saveToken('existing_token');
      final valid = await repo.restoreSession();
      expect(valid, isTrue);
    });

    test('restoreSession returns false when storage is empty', () async {
      final valid = await repo.restoreSession();
      expect(valid, isFalse);
    });

    test('logout calls remote logout and deletes local token', () async {
      await storage.saveToken('token_to_logout');
      await repo.logout();
      expect(remote.loggedOutToken, 'token_to_logout');
      expect(await storage.getToken(), isNull);
    });
  });
}

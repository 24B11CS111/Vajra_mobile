import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vajra_mobile/core/services/secure_storage_service.dart';
import 'package:vajra_mobile/features/authentication/services/auth_repository.dart';
import 'package:vajra_mobile/features/profile/models/user_profile_model.dart';
import 'package:vajra_mobile/features/profile/models/companion_profile_model.dart';
import 'package:vajra_mobile/features/profile/services/profile_repository.dart';

class _MockSecureStorage extends SecureStorageService {
  String? token;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> saveToken(String t) async => token = t;
  @override
  Future<void> deleteToken() async => token = null;
}

class _MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<String> signup(String email, String password, String? fullName) async => 'signup_token';

  @override
  Future<String> login(String username, String password) async => 'auth_token_john';

  @override
  Future<String> socialLogin(AuthProviderType provider, String token) async => 'guest_token_123';

  @override
  Future<void> logout(String token) async {}

  @override
  Future<String> refreshToken(String refreshToken) async => 'refresh_token';

  @override
  Future<bool> validateSession(String token) async => true;
}

class _MockProfileRemoteDataSource implements ProfileRemoteDataSource {
  UserProfileModel? remoteProfile;
  CompanionProfileModel companion = const CompanionProfileModel();

  @override
  Future<UserProfileModel> getUserProfile() async {
    if (remoteProfile != null) return remoteProfile!;
    return const UserProfileModel(id: 'remote_user', name: 'Remote User', email: 'remote@vajra.ai');
  }

  @override
  Future<UserProfileModel> updateUserProfile(String name) async {
    remoteProfile = UserProfileModel(
      id: remoteProfile?.id ?? 'remote_user',
      name: name,
      email: remoteProfile?.email ?? 'remote@vajra.ai',
    );
    return remoteProfile!;
  }

  @override
  Future<CompanionProfileModel> getCompanionProfile() async => companion;

  @override
  Future<void> updateCompanionProfile(CompanionProfileModel profile) async {
    companion = profile;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Identity Isolation Tests', () {
    late _MockSecureStorage storage;
    late _MockAuthRemoteDataSource authRemote;
    late AuthLocalDataSource authLocal;
    late AuthRepositoryImpl authRepo;
    late ProfileLocalDataSourceImpl profileLocal;
    late _MockProfileRemoteDataSource profileRemote;
    late ProfileRepositoryImpl profileRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = _MockSecureStorage();
      authRemote = _MockAuthRemoteDataSource();
      authLocal = AuthLocalDataSourceImpl(storage);
      authRepo = AuthRepositoryImpl(authRemote, authLocal);

      profileLocal = ProfileLocalDataSourceImpl();
      profileRemote = _MockProfileRemoteDataSource();
      profileRepo = ProfileRepositoryImpl(profileRemote, profileLocal);
    });

    test('User A logs in, guestLogin wipes User A and guarantees Guest name and id', () async {
      // 1. Simulate User A logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vajra_current_user_id', 'user_john_123');
      await storage.saveToken('jwt_token_john');

      final johnProfile = const UserProfileModel(
        id: 'user_john_123',
        name: 'John Doe',
        email: 'john@example.com',
      );
      profileRemote.remoteProfile = johnProfile;
      await profileLocal.cacheUserProfile(johnProfile);

      // Verify User A profile is active
      final initialProfileRes = await profileRepo.getUserProfile();
      expect(initialProfileRes.data?.name, 'John Doe');
      expect(initialProfileRes.data?.id, 'user_john_123');

      // 2. Perform guest login
      final guestResult = await authRepo.guestLogin();
      expect(guestResult.isSuccess, isTrue);

      // 3. Verify user ID is now guest_user
      expect(prefs.getString('vajra_current_user_id'), 'guest_user');

      // 4. Verify ProfileRepository returns strictly "Guest" identity
      final guestProfileRes = await profileRepo.getUserProfile();
      expect(guestProfileRes.data?.name, 'Guest');
      expect(guestProfileRes.data?.id, 'guest_user');
      expect(guestProfileRes.data?.email, 'guest@vajra.local');
      expect(guestProfileRes.data?.name, isNot(equals('John Doe')));
    });

    test('Guest logout clears all guest data and storage', () async {
      final prefs = await SharedPreferences.getInstance();

      // Enter guest mode
      await authRepo.guestLogin();
      expect(prefs.getString('vajra_current_user_id'), 'guest_user');
      expect(await storage.getToken(), isNotNull);

      // Logout
      await authRepo.logout();

      // Verify token deleted and user ID cleared
      expect(await storage.getToken(), isNull);
      expect(prefs.getString('vajra_current_user_id'), isNull);
    });

    test('New authenticated user after guest does not see guest data', () async {
      final prefs = await SharedPreferences.getInstance();

      // Guest session
      await authRepo.guestLogin();
      final guestProfileRes = await profileRepo.getUserProfile();
      expect(guestProfileRes.data?.name, 'Guest');

      // Logout guest
      await authRepo.logout();

      // User B logs in
      await authRepo.login('alice@example.com', 'Password123');
      await prefs.setString('vajra_current_user_id', 'user_alice_456');

      final aliceProfile = const UserProfileModel(
        id: 'user_alice_456',
        name: 'Alice Smith',
        email: 'alice@example.com',
      );
      profileRemote.remoteProfile = aliceProfile;
      await profileLocal.cacheUserProfile(aliceProfile);

      final currentProfileRes = await profileRepo.getUserProfile();
      expect(currentProfileRes.data?.name, 'Alice Smith');
      expect(currentProfileRes.data?.id, 'user_alice_456');
      expect(currentProfileRes.data?.name, isNot(equals('Guest')));
    });
  });
}

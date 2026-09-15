import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/network/api_client.dart';
import 'package:vajra_mobile/core/network/api_endpoints.dart';
import 'package:vajra_mobile/core/network/sse_client.dart';
import 'package:vajra_mobile/core/services/secure_storage_service.dart';
import 'package:vajra_mobile/features/companion/models/stream_event.dart';
import 'package:vajra_mobile/features/companion/services/companion_repository.dart';
import 'package:vajra_mobile/features/profile/services/profile_repository.dart';
import 'package:dio/dio.dart';

class _TestSecureStorageService implements SecureStorageService {
  String? _token;
  _TestSecureStorageService(this._token);
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<void> deleteToken() async => _token = null;
}

Future<String> _getAuthToken(Dio dio) async {
  try {
    final loginRes = await dio.post('/auth/login', data: {
      'email': 'user_a@vajra.ai',
      'password': 'Password123!',
    });
    return loginRes.data['access_token'] as String;
  } catch (_) {
    final signupRes = await dio.post('/auth/signup', data: {
      'email': 'user_a@vajra.ai',
      'password': 'Password123!',
      'full_name': 'Alex Vance',
    });
    return signupRes.data['access_token'] as String;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  final testBaseUrl = ApiEndpoints.defaultProductionUrl;

  group('Real AI Backend & Mobile SSE Integration Test', () {
    test('CompanionRepository connects to live backend and receives real AI SSE stream', () async {
      final dio = Dio(BaseOptions(
        baseUrl: testBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
      ));

      final token = await _getAuthToken(dio);

      // 2. Instantiate real SseClient and CompanionRepository with test storage
      final storage = _TestSecureStorageService(token);
      final apiClient = ApiClient(storage);
      apiClient.dio.options.baseUrl = testBaseUrl;

      final sseClient = SseClient(apiClient.dio);
      final repository = CompanionRepository(apiClient, sseClient);

      // 3. Process conversation with real prompt
      final events = <BackendStreamEvent>[];
      final responseBuffer = StringBuffer();

      await for (final event in repository.processConversation('test-session-math', 'What is 2 + 2?')) {
        events.add(event);
        if (event.eventType == EventType.token) {
          final tokenText = event.payload['text'] as String? ?? '';
          responseBuffer.write(tokenText);
        }
      }

      // ignore: avoid_print
      print('Math test response buffer: "${responseBuffer.toString()}"');
      expect(events.isNotEmpty, isTrue);
      expect(responseBuffer.toString().isNotEmpty, isTrue);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Real AI answers quantum mechanics explanation', () async {
      final dio = Dio(BaseOptions(
        baseUrl: testBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
      ));

      final token = await _getAuthToken(dio);

      final storage = _TestSecureStorageService(token);
      final apiClient = ApiClient(storage);
      apiClient.dio.options.baseUrl = testBaseUrl;

      final sseDio = Dio(BaseOptions(
        baseUrl: testBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
      ));
      sseDio.options.headers['Authorization'] = 'Bearer $token';

      final sseClient = SseClient(sseDio);
      final repository = CompanionRepository(apiClient, sseClient);

      final responseBuffer = StringBuffer();
      await for (final event in repository.processConversation('test-session-qm', 'What is quantum mechanics? Answer in one sentence.')) {
        if (event.eventType == EventType.token) {
          responseBuffer.write(event.payload['text'] as String? ?? '');
        }
      }

      expect(responseBuffer.toString().isNotEmpty, isTrue);
      expect(responseBuffer.toString().toLowerCase().contains('physics') || responseBuffer.toString().toLowerCase().contains('quantum') || responseBuffer.toString().toLowerCase().contains('particles'), isTrue);
    });

    test('Profile GET /me and PUT /me works with real backend', () async {
      final dio = Dio(BaseOptions(
        baseUrl: testBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
      ));

      final token = await _getAuthToken(dio);

      final storage = _TestSecureStorageService(token);
      final apiClient = ApiClient(storage);
      apiClient.dio.options.baseUrl = testBaseUrl;

      final remoteDataSource = ProfileRemoteDataSourceImpl(apiClient);
      final profile = await remoteDataSource.getUserProfile();
      expect(profile.email, 'user_a@vajra.ai');

      final updated = await remoteDataSource.updateUserProfile('Alex Vance');
      expect(updated.name, 'Alex Vance');
    });

    test('Memory Purge DELETE /memory/purge succeeds', () async {
      final dio = Dio(BaseOptions(
        baseUrl: testBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
      ));

      final token = await _getAuthToken(dio);

      final purgeRes = await dio.delete(
        '/memory/purge',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      expect(purgeRes.statusCode, 200);
      expect(purgeRes.data['status'], 'ok');
    });
  });
}


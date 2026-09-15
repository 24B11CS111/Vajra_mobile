import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:vajra_mobile/core/network/api_client.dart';
import 'package:vajra_mobile/core/services/secure_storage_service.dart';
import 'package:vajra_mobile/core/network/api_endpoints.dart';
import 'package:vajra_mobile/features/study/services/study_repository.dart';
import 'package:vajra_mobile/features/planner/services/planner_repository.dart';

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

  group('Study & Calendar Feature Integration Tests', () {
    late ApiClient apiClient;
    late StudyRepository studyRepo;
    late PlannerRepository plannerRepo;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(
        baseUrl: testBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
      ));

      final token = await _getAuthToken(dio);

      final storage = _TestSecureStorageService(token);
      apiClient = ApiClient(storage);
      apiClient.dio.options.baseUrl = testBaseUrl;

      studyRepo = StudyRepositoryImpl(apiClient);
      plannerRepo = PlannerRepositoryImpl(apiClient);
    });

    test('Subjects CRUD via StudyRepository', () async {
      final subRes = await studyRepo.createSubject({
        'name': 'Integration Chemistry',
        'description': 'Organic & Inorganic',
        'color': '#10B981',
        'priority': 'high',
      });
      expect(subRes.isSuccess, isTrue);
      expect(subRes.data?.name, 'Integration Chemistry');

      final listRes = await studyRepo.getSubjects();
      expect(listRes.isSuccess, isTrue);
      expect(listRes.data?.any((s) => s.name == 'Integration Chemistry'), isTrue);

      if (subRes.data?.id != null) {
        final delRes = await studyRepo.deleteSubject(subRes.data!.id);
        expect(delRes.isSuccess, isTrue);
      }
    });

    test('Assignments CRUD & Toggle via StudyRepository', () async {
      final assignRes = await studyRepo.createAssignment({
        'title': 'Thermo Problem Set #5',
        'subject_name': 'Thermodynamics',
        'priority': 'high',
      });
      expect(assignRes.isSuccess, isTrue);
      expect(assignRes.data?.title, 'Thermo Problem Set #5');
      expect(assignRes.data?.status, 'NOT_STARTED');

      final assignId = assignRes.data!.id;

      // Toggle status
      final toggleRes = await studyRepo.toggleAssignment(assignId);
      expect(toggleRes.isSuccess, isTrue);
      expect(toggleRes.data?.status, 'COMPLETED');

      // Cleanup
      final delRes = await studyRepo.deleteAssignment(assignId);
      expect(delRes.isSuccess, isTrue);
    });

    test('Calendar Events CRUD via PlannerRepository', () async {
      final now = DateTime.now();
      final eventRes = await plannerRepo.createCalendarEvent({
        'title': 'Group Study Session',
        'event_type': 'study_session',
        'start_time': now.toIso8601String(),
        'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
      });
      expect(eventRes.isSuccess, isTrue);
      expect(eventRes.data?.title, 'Group Study Session');

      final eventId = eventRes.data!.id;

      final eventsList = await plannerRepo.getCalendarEvents(eventType: 'study_session');
      expect(eventsList.isSuccess, isTrue);
      expect(eventsList.data?.any((e) => e.id == eventId), isTrue);

      final delRes = await plannerRepo.deleteCalendarEvent(eventId);
      expect(delRes.isSuccess, isTrue);
    });
  });
}

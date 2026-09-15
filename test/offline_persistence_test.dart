import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vajra_mobile/core/network/api_client.dart';
import 'package:vajra_mobile/core/services/secure_storage_service.dart';
import 'package:vajra_mobile/core/intelligence/sync/sync_queue.dart';
import 'package:vajra_mobile/features/planner/models/planner_model.dart';
import 'package:vajra_mobile/features/planner/services/planner_local_data_source.dart';
import 'package:vajra_mobile/features/planner/services/planner_repository.dart';
import 'package:vajra_mobile/features/study/models/study_models.dart';
import 'package:vajra_mobile/features/study/services/study_local_data_source.dart';
import 'package:vajra_mobile/features/study/services/study_repository.dart';

class _MockSecureStorageService implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'fake_token';
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Persistence - Local Data Sources', () {
    test('PlannerLocalDataSource caches and retrieves tasks', () async {
      final localDS = PlannerLocalDataSourceImpl();
      final sampleTasks = [
        PlannerTask(
          id: 'task_1',
          title: 'Study Distributed Systems',
          category: 'Study',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isCompleted: false,
        ),
      ];

      await localDS.cacheTasks(sampleTasks);
      final cached = await localDS.getCachedTasks();

      expect(cached, isNotNull);
      expect(cached!.length, 1);
      expect(cached.first.title, 'Study Distributed Systems');
    });

    test('StudyLocalDataSource caches and retrieves assignments & subjects', () async {
      final localDS = StudyLocalDataSourceImpl();
      final sampleAssignments = [
        AssignmentModel(
          id: 'assign_1',
          userId: 'user_1',
          title: 'Computer Networks Lab 3',
          subjectName: 'Networks',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          status: 'PENDING',
          priority: 'high',
        ),
      ];
      final sampleSubjects = [
        const SubjectModel(
          id: 'sub_1',
          userId: 'user_1',
          name: 'Computer Networks',
          color: '#8B5CF6',
          priority: 'high',
        ),
      ];

      await localDS.cacheAssignments(sampleAssignments);
      await localDS.cacheSubjects(sampleSubjects);

      final cachedAssign = await localDS.getCachedAssignments();
      final cachedSub = await localDS.getCachedSubjects();

      expect(cachedAssign, isNotNull);
      expect(cachedAssign!.length, 1);
      expect(cachedAssign.first.title, 'Computer Networks Lab 3');

      expect(cachedSub, isNotNull);
      expect(cachedSub!.length, 1);
      expect(cachedSub.first.name, 'Computer Networks');
    });

    test('SyncQueue persists enqueued operations and deduplicates', () async {
      final queue = SyncQueue();
      await queue.clearQueue();

      await queue.enqueue(
        entityId: 'sync_1',
        operation: SyncOperationType.create,
        entityType: 'planner_task',
        payload: {'title': 'Offline Task'},
      );

      // Duplicate enqueue should be updated in-place
      await queue.enqueue(
        entityId: 'sync_1',
        operation: SyncOperationType.update,
        entityType: 'planner_task',
        payload: {'title': 'Offline Task (Edited)'},
      );

      expect(queue.state.pendingOperations.length, 1);
      expect(queue.state.isOnline, true);

      queue.setOnlineStatus(false);
      expect(queue.state.isOnline, false);
    });
  });

  group('Offline-First Repositories (Graceful Degradation)', () {
    test('PlannerRepositoryImpl returns cached tasks when offline without raw error', () async {
      final storage = _MockSecureStorageService();
      final apiClient = ApiClient(storage);
      final localDS = PlannerLocalDataSourceImpl();

      // Seed local cache
      await localDS.cacheTasks([
        PlannerTask(
          id: 'offline_task_1',
          title: 'Offline Cached Task',
          category: 'General',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          isCompleted: false,
        ),
      ]);

      // Point dio to invalid port to simulate total offline
      apiClient.dio.options.baseUrl = 'http://127.0.0.1:1';
      apiClient.dio.options.connectTimeout = const Duration(milliseconds: 100);

      final repo = PlannerRepositoryImpl(apiClient, localDS);
      final res = await repo.getTasks(DateTime.now());

      expect(res.isSuccess, true);
      expect(res.data, isNotNull);
      expect(res.data!.length, 1);
      expect(res.data!.first.title, 'Offline Cached Task');
    });

    test('StudyRepositoryImpl returns cached assignments when offline without raw error', () async {
      final storage = _MockSecureStorageService();
      final apiClient = ApiClient(storage);
      final localDS = StudyLocalDataSourceImpl();

      // Seed local cache
      await localDS.cacheAssignments([
        const AssignmentModel(
          id: 'offline_assign_1',
          userId: 'user_1',
          title: 'Offline Cached Assignment',
          subjectName: 'OS',
          status: 'PENDING',
        ),
      ]);

      apiClient.dio.options.baseUrl = 'http://127.0.0.1:1';
      apiClient.dio.options.connectTimeout = const Duration(milliseconds: 100);

      final repo = StudyRepositoryImpl(apiClient, localDS);
      final res = await repo.getAssignments();

      expect(res.isSuccess, true);
      expect(res.data, isNotNull);
      expect(res.data!.length, 1);
      expect(res.data!.first.title, 'Offline Cached Assignment');
    });
  });
}

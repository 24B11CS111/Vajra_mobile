import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/intelligence/sync/sync_queue.dart';
import '../models/study_models.dart';
import '../models/study_session_model.dart';
import 'study_local_data_source.dart';

abstract class StudyRepository {
  Future<ApiResponse<List<SubjectModel>>> getSubjects();
  Future<ApiResponse<SubjectModel>> createSubject(Map<String, dynamic> data);
  Future<ApiResponse<SubjectModel>> updateSubject(String id, Map<String, dynamic> data);
  Future<ApiResponse<void>> deleteSubject(String id);

  Future<ApiResponse<List<AssignmentModel>>> getAssignments({String? status, String? subjectId});
  Future<ApiResponse<AssignmentModel>> createAssignment(Map<String, dynamic> data);
  Future<ApiResponse<AssignmentModel>> updateAssignment(String id, Map<String, dynamic> data);
  Future<ApiResponse<AssignmentModel>> toggleAssignment(String id);
  Future<ApiResponse<void>> deleteAssignment(String id);

  Future<ApiResponse<List<StudySessionModel>>> getUpcomingSessions();
  Future<ApiResponse<StudySessionModel>> createStudySession(Map<String, dynamic> data);

  StudyLocalDataSource get localDataSource;
}

class StudyRepositoryImpl implements StudyRepository {
  final ApiClient _apiClient;
  final StudyLocalDataSource _localDataSource;
  final SyncQueue? _syncQueue;

  StudyRepositoryImpl(
    this._apiClient, [
    StudyLocalDataSource? localDataSource,
    this._syncQueue,
  ]) : _localDataSource = localDataSource ?? StudyLocalDataSourceImpl();

  @override
  StudyLocalDataSource get localDataSource => _localDataSource;

  // --- SUBJECTS ---
  @override
  Future<ApiResponse<List<SubjectModel>>> getSubjects() async {
    final cached = await _localDataSource.getCachedSubjects();

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.subjects);
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => SubjectModel.fromJson(item as Map<String, dynamic>))
            .toList();

        await _localDataSource.cacheSubjects(list);
        _syncQueue?.setOnlineStatus(true);
        return ApiResponse.success(list);
      }
      return ApiResponse.success(cached ?? const []);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      return ApiResponse.success(cached ?? const []);
    }
  }

  @override
  Future<ApiResponse<SubjectModel>> createSubject(Map<String, dynamic> data) async {
    final localId = data['id']?.toString() ?? 'subj_${DateTime.now().millisecondsSinceEpoch}';
    final localSubject = SubjectModel.fromJson({
      ...data,
      'id': localId,
      'user_id': data['user_id'] ?? 'local_user',
      'name': data['name'] ?? 'New Subject',
    });
    await _localDataSource.saveSubject(localSubject);

    try {
      final response = await _apiClient.dio.post(ApiEndpoints.subjects, data: data);
      final serverSubject = SubjectModel.fromJson(response.data as Map<String, dynamic>);
      if (serverSubject.id != localSubject.id) {
        await _localDataSource.deleteSubject(localSubject.id);
        await _localDataSource.saveSubject(serverSubject);
      }
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(serverSubject);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'subject',
        entityId: localSubject.id,
        operation: SyncOperationType.create,
        payload: data,
      );
      return ApiResponse.success(localSubject);
    }
  }

  @override
  Future<ApiResponse<SubjectModel>> updateSubject(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiEndpoints.subjects}/$id', data: data);
      final updated = SubjectModel.fromJson(response.data as Map<String, dynamic>);
      await _localDataSource.saveSubject(updated);
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(updated);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      return ApiResponse.error("Unable to update subject offline.");
    }
  }

  @override
  Future<ApiResponse<void>> deleteSubject(String id) async {
    await _localDataSource.deleteSubject(id);

    try {
      await _apiClient.dio.delete('${ApiEndpoints.subjects}/$id');
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(null);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'subject',
        entityId: id,
        operation: SyncOperationType.delete,
        payload: {'id': id},
      );
      return ApiResponse.success(null);
    }
  }

  // --- ASSIGNMENTS ---
  @override
  Future<ApiResponse<List<AssignmentModel>>> getAssignments({String? status, String? subjectId}) async {
    final cached = await _localDataSource.getCachedAssignments();

    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (subjectId != null) queryParams['subject_id'] = subjectId;

      final response = await _apiClient.dio.get(ApiEndpoints.assignments, queryParameters: queryParams);
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => AssignmentModel.fromJson(item as Map<String, dynamic>))
            .toList();

        await _localDataSource.cacheAssignments(list);
        _syncQueue?.setOnlineStatus(true);
        return ApiResponse.success(list);
      }
      return ApiResponse.success(cached ?? const []);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      return ApiResponse.success(cached ?? const []);
    }
  }

  @override
  Future<ApiResponse<AssignmentModel>> createAssignment(Map<String, dynamic> data) async {
    final localId = data['id']?.toString() ?? 'assign_${DateTime.now().millisecondsSinceEpoch}';
    final subjectName = (data['subject_name'] ?? data['subjectName'] ?? data['subject'] ?? 'General').toString();

    // Auto-create subject if it does not yet exist locally or remotely
    try {
      final existingSubjects = await getSubjects();
      final hasSubject = existingSubjects.data?.any(
        (s) => s.name.toLowerCase() == subjectName.toLowerCase(),
      ) ?? false;
      if (!hasSubject && subjectName.toLowerCase() != 'general') {
        await createSubject({'name': subjectName, 'color': '#8B5CF6', 'priority': 'medium'});
      }
    } catch (_) {}

    final localAssignment = AssignmentModel.fromJson({
      ...data,
      'id': localId,
      'user_id': data['user_id'] ?? 'local_user',
      'title': data['title'] ?? 'New Assignment',
      'subject_name': subjectName,
    });
    await _localDataSource.saveAssignment(localAssignment);

    try {
      final response = await _apiClient.dio.post(ApiEndpoints.assignments, data: data);
      final serverAssignment = AssignmentModel.fromJson(response.data as Map<String, dynamic>);
      if (serverAssignment.id != localAssignment.id) {
        await _localDataSource.deleteAssignment(localAssignment.id);
        await _localDataSource.saveAssignment(serverAssignment);
      }
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(serverAssignment);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'assignment',
        entityId: localAssignment.id,
        operation: SyncOperationType.create,
        payload: data,
      );
      return ApiResponse.success(localAssignment);
    }
  }

  @override
  Future<ApiResponse<AssignmentModel>> updateAssignment(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiEndpoints.assignments}/$id', data: data);
      final updated = AssignmentModel.fromJson(response.data as Map<String, dynamic>);
      await _localDataSource.saveAssignment(updated);
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(updated);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      return ApiResponse.error("Unable to update assignment offline.");
    }
  }

  @override
  Future<ApiResponse<AssignmentModel>> toggleAssignment(String id) async {
    final cached = await _localDataSource.getCachedAssignments();
    AssignmentModel? toggled;
    if (cached != null) {
      final idx = cached.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        final current = cached[idx];
        final nextStatus = current.status == 'COMPLETED' ? 'PENDING' : 'COMPLETED';
        toggled = current.copyWith(status: nextStatus);
        cached[idx] = toggled;
        await _localDataSource.cacheAssignments(cached);
      }
    }

    try {
      final response = await _apiClient.dio.post('${ApiEndpoints.assignments}/$id/toggle');
      final updated = AssignmentModel.fromJson(response.data as Map<String, dynamic>);
      await _localDataSource.saveAssignment(updated);
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(updated);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      if (toggled != null) {
        await _syncQueue?.enqueue(
          entityType: 'assignment',
          entityId: id,
          operation: SyncOperationType.update,
          payload: {'status': toggled.status},
        );
        return ApiResponse.success(toggled);
      }
      return ApiResponse.error("Unable to toggle assignment.");
    }
  }

  @override
  Future<ApiResponse<void>> deleteAssignment(String id) async {
    await _localDataSource.deleteAssignment(id);

    try {
      await _apiClient.dio.delete('${ApiEndpoints.assignments}/$id');
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(null);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'assignment',
        entityId: id,
        operation: SyncOperationType.delete,
        payload: {'id': id},
      );
      return ApiResponse.success(null);
    }
  }

  // --- STUDY SESSIONS ---
  @override
  Future<ApiResponse<List<StudySessionModel>>> getUpcomingSessions() async {
    final cached = await _localDataSource.getCachedSessions();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.calendarEvents,
        queryParameters: {'event_type': 'study_session'},
      );
      if (response.data is List) {
        final list = (response.data as List).map((item) {
          final json = item as Map<String, dynamic>;
          return StudySessionModel(
            id: json['id']?.toString() ?? '',
            subject: json['title'] ?? 'Study Session',
            topic: json['description'] ?? 'Review Focus',
            scheduledTime: DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now(),
            progress: 0.0,
            durationMinutes: 45,
          );
        }).toList();

        await _localDataSource.cacheSessions(list);
        _syncQueue?.setOnlineStatus(true);
        return ApiResponse.success(list);
      }
      return ApiResponse.success(cached ?? const []);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      return ApiResponse.success(cached ?? const []);
    }
  }

  @override
  Future<ApiResponse<StudySessionModel>> createStudySession(Map<String, dynamic> data) async {
    final localId = data['id']?.toString() ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    final scheduled = DateTime.tryParse(data['scheduled_time']?.toString() ?? data['startTime']?.toString() ?? '') ?? DateTime.now();
    final localSession = StudySessionModel(
      id: localId,
      subject: data['subject']?.toString() ?? 'General Study',
      topic: data['topic']?.toString() ?? data['title']?.toString() ?? 'Study Focus',
      scheduledTime: scheduled,
      progress: 0.0,
      durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 45,
    );
    await _localDataSource.saveSession(localSession);

    try {
      final payload = {
        'title': '${localSession.subject}: ${localSession.topic}',
        'event_type': 'study_session',
        'start_time': scheduled.toIso8601String(),
        'end_time': scheduled.add(Duration(minutes: localSession.durationMinutes)).toIso8601String(),
        'description': 'Scheduled study session for ${localSession.subject}',
      };
      await _apiClient.dio.post(ApiEndpoints.calendarEvents, data: payload);
      _syncQueue?.setOnlineStatus(true);
      return ApiResponse.success(localSession);
    } catch (_) {
      _syncQueue?.setOnlineStatus(false);
      await _syncQueue?.enqueue(
        entityType: 'study_session',
        entityId: localSession.id,
        operation: SyncOperationType.create,
        payload: {
          'subject': localSession.subject,
          'topic': localSession.topic,
          'start_time': scheduled.toIso8601String(),
          'duration': localSession.durationMinutes,
        },
      );
      return ApiResponse.success(localSession);
    }
  }
}

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(studyLocalDataSourceProvider),
    ref.watch(syncQueueProvider.notifier),
  );
});

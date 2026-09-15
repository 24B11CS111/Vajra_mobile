import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_models.dart';
import '../models/study_session_model.dart';
import '../services/study_repository.dart';

// --- SUBJECTS NOTIFIER ---
class SubjectsNotifier extends StateNotifier<AsyncValue<List<SubjectModel>>> {
  final StudyRepository _repository;

  SubjectsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    try {
      final cached = await _repository.localDataSource.getCachedSubjects();
      if (cached != null && cached.isNotEmpty && state.valueOrNull == null) {
        state = AsyncValue.data(cached);
      }

      final response = await _repository.getSubjects();
      if (response.data != null) {
        state = AsyncValue.data(response.data!);
      } else if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (_) {
      final cached = await _repository.localDataSource.getCachedSubjects();
      state = AsyncValue.data(cached ?? []);
    }
  }

  Future<bool> createSubject({
    required String name,
    String? description,
    String color = '#8B5CF6',
    DateTime? examDate,
    String priority = 'medium',
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'color': color,
      'priority': priority,
    };
    if (description != null) data['description'] = description;
    if (examDate != null) data['exam_date'] = examDate.toIso8601String();

    final res = await _repository.createSubject(data);
    if (res.isSuccess) {
      await loadSubjects();
      return true;
    }
    return false;
  }

  Future<bool> deleteSubject(String id) async {
    final res = await _repository.deleteSubject(id);
    if (res.isSuccess) {
      await loadSubjects();
      return true;
    }
    return false;
  }
}

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, AsyncValue<List<SubjectModel>>>((ref) {
  return SubjectsNotifier(ref.watch(studyRepositoryProvider));
});

// --- ASSIGNMENTS NOTIFIER ---
class AssignmentsNotifier extends StateNotifier<AsyncValue<List<AssignmentModel>>> {
  final StudyRepository _repository;

  AssignmentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAssignments();
  }

  Future<void> loadAssignments({String? status, String? subjectId}) async {
    try {
      final cached = await _repository.localDataSource.getCachedAssignments();
      if (cached != null && cached.isNotEmpty && state.valueOrNull == null) {
        state = AsyncValue.data(cached);
      }

      final response = await _repository.getAssignments(status: status, subjectId: subjectId);
      if (response.data != null) {
        state = AsyncValue.data(response.data!);
      } else if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (_) {
      final cached = await _repository.localDataSource.getCachedAssignments();
      state = AsyncValue.data(cached ?? []);
    }
  }

  Future<bool> createAssignment({
    required String title,
    required String subjectName,
    String? subjectId,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String status = 'NOT_STARTED',
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'subject_name': subjectName,
      'priority': priority,
      'status': status,
    };
    if (subjectId != null) data['subject_id'] = subjectId;
    if (description != null) data['description'] = description;
    if (dueDate != null) data['due_date'] = dueDate.toIso8601String();

    final res = await _repository.createAssignment(data);
    if (res.isSuccess) {
      await loadAssignments();
      return true;
    }
    return false;
  }

  Future<bool> toggleAssignment(String id) async {
    final res = await _repository.toggleAssignment(id);
    if (res.isSuccess) {
      await loadAssignments();
      return true;
    }
    return false;
  }

  Future<bool> deleteAssignment(String id) async {
    final res = await _repository.deleteAssignment(id);
    if (res.isSuccess) {
      await loadAssignments();
      return true;
    }
    return false;
  }
}

final assignmentsProvider = StateNotifierProvider<AssignmentsNotifier, AsyncValue<List<AssignmentModel>>>((ref) {
  return AssignmentsNotifier(ref.watch(studyRepositoryProvider));
});

// --- STUDY SESSIONS ---
final studyProvider = FutureProvider<List<StudySessionModel>>((ref) async {
  final repo = ref.watch(studyRepositoryProvider);
  final res = await repo.getUpcomingSessions();
  return res.data ?? [];
});

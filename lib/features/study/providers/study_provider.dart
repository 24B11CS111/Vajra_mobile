import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_session_model.dart';
import '../services/study_repository.dart';

class StudyNotifier extends StateNotifier<AsyncValue<List<StudySessionModel>>> {
  final StudyRepository _repository;

  StudyNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final response = await _repository.getUpcomingSessions();
      if (response.isSuccess && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(response.message ?? 'Failed to load study sessions', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final studyProvider = StateNotifierProvider<StudyNotifier, AsyncValue<List<StudySessionModel>>>((ref) {
  return StudyNotifier(ref.watch(studyRepositoryProvider));
});

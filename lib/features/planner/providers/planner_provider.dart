import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planner_model.dart';
import '../services/planner_repository.dart';

class PlannerNotifier extends StateNotifier<AsyncValue<List<PlannerTask>>> {
  final PlannerRepository _repository;

  PlannerNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final response = await _repository.getTasks(DateTime.now());
      if (response.isSuccess && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(response.message ?? 'Unknown error', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCompletion(String id) async {
    state.whenData((tasks) {
      final newTasks = tasks.map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t).toList();
      state = AsyncValue.data(newTasks);
      _repository.toggleTaskCompletion(id, newTasks.firstWhere((t) => t.id == id).isCompleted);
    });
  }

  void reorderTasks(int oldIndex, int newIndex) {
    state.whenData((tasks) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, item);
      state = AsyncValue.data(List.from(tasks));
    });
  }
}

final plannerProvider = StateNotifierProvider<PlannerNotifier, AsyncValue<List<PlannerTask>>>((ref) {
  return PlannerNotifier(ref.watch(plannerRepositoryProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/memory_model.dart';
import '../services/memory_repository.dart';

final memoryQueryProvider = StateProvider<String>((ref) => '');
final memoryCategoryProvider = StateProvider<String>((ref) => 'All');

class MemoryNotifier extends StateNotifier<AsyncValue<List<MemoryModel>>> {
  final MemoryRepository _repository;

  MemoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadMemories();
  }

  Future<void> _loadMemories({String? category}) async {
    try {
      final response = await _repository.getMemories(category: category);
      if (response.isSuccess && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(response.message ?? 'Unknown error', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refreshMemories({String? category}) {
    state = const AsyncValue.loading();
    _loadMemories(category: category);
  }

  void togglePin(String id) {
    state.whenData((memories) {
      final newMemories = memories.map((m) => m.id == id ? m.copyWith(isPinned: !m.isPinned) : m).toList();
      state = AsyncValue.data(newMemories);
      _repository.syncPinStatus(id, newMemories.firstWhere((m) => m.id == id).isPinned);
    });
  }
  
  Future<void> deleteMemory(String id) async {
    state.whenData((memories) {
      final newMemories = memories.where((m) => m.id != id).toList();
      state = AsyncValue.data(newMemories);
      _repository.deleteMemory(id);
    });
  }

  Future<void> archiveMemory(String id) async {
    state.whenData((memories) {
      final newMemories = memories.where((m) => m.id != id).toList();
      state = AsyncValue.data(newMemories);
      _repository.archiveMemory(id);
    });
  }
}

final memoryProvider = StateNotifierProvider<MemoryNotifier, AsyncValue<List<MemoryModel>>>((ref) {
  return MemoryNotifier(ref.watch(memoryRepositoryProvider));
});

final filteredMemoriesProvider = Provider<List<MemoryModel>>((ref) {
  final query = ref.watch(memoryQueryProvider).toLowerCase();
  final category = ref.watch(memoryCategoryProvider);
  final memories = ref.watch(memoryProvider).value ?? [];
  
  return memories.where((m) {
    final matchesQuery = m.content.toLowerCase().contains(query);
    final matchesCategory = category == 'All' || m.category == category;
    return matchesQuery && matchesCategory;
  }).toList();
});

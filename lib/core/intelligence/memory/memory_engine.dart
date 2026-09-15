import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a summarized or ranked memory retrieved by the MemoryEngine.
class MemoryRecord {
  final String id;
  final String content;
  final double relevanceScore;
  final bool isPinned;
  final DateTime timestamp;

  const MemoryRecord({
    required this.id,
    required this.content,
    required this.relevanceScore,
    required this.isPinned,
    required this.timestamp,
  });
}

/// Represents the state of the MemoryEngine.
class MemoryState {
  final List<MemoryRecord> recentMemories;
  final List<MemoryRecord> searchResults;
  final bool isSearching;
  final String? error;

  const MemoryState({
    this.recentMemories = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.error,
  });

  MemoryState copyWith({
    List<MemoryRecord>? recentMemories,
    List<MemoryRecord>? searchResults,
    bool? isSearching,
    String? error,
  }) {
    return MemoryState(
      recentMemories: recentMemories ?? this.recentMemories,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

/// The MemoryEngine handles semantic storage and retrieval of user memories,
/// ranking them by importance and relevance to the current context.
class MemoryEngine extends StateNotifier<MemoryState> {
  MemoryEngine() : super(const MemoryState());

  List<MemoryRecord> get recentMemories => state.recentMemories;

  /// Stores a new memory.
  Future<void> remember(String content, {double importance = 0.5}) async {
    // In a real implementation, this would save to a vector DB or local repo.
    final newMemory = MemoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      relevanceScore: importance,
      isPinned: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      recentMemories: [newMemory, ...state.recentMemories],
    );
  }

  /// Recalls recent and relevant memories for the given context.
  Future<List<MemoryRecord>> recall(String context) async {
    // Mock recall logic
    return state.recentMemories;
  }

  /// Performs a semantic search for memories.
  Future<void> search(String query) async {
    state = state.copyWith(isSearching: true);
    // Mock search delay
    await Future.delayed(const Duration(milliseconds: 300));
    final results = state.recentMemories.where((m) => m.content.toLowerCase().contains(query.toLowerCase())).toList();
    state = state.copyWith(searchResults: results, isSearching: false);
  }

  /// Archives a specific memory.
  Future<void> archive(String id) async {
    state = state.copyWith(
      recentMemories: state.recentMemories.where((m) => m.id != id).toList(),
      searchResults: state.searchResults.where((m) => m.id != id).toList(),
    );
  }

  /// Deletes a memory permanently.
  Future<void> delete(String id) async {
    state = state.copyWith(
      recentMemories: state.recentMemories.where((m) => m.id != id).toList(),
      searchResults: state.searchResults.where((m) => m.id != id).toList(),
    );
  }

  /// Pins a memory for high availability.
  Future<void> pin(String id, bool isPinned) async {
    final updatedRecent = state.recentMemories.map((m) {
      if (m.id == id) {
        return MemoryRecord(
          id: m.id,
          content: m.content,
          relevanceScore: m.relevanceScore,
          isPinned: isPinned,
          timestamp: m.timestamp,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(recentMemories: updatedRecent);
  }

  /// Summarizes a set of memories into a coherent digest.
  Future<String> summarize(List<String> memoryIds) async {
    return 'Summary of ${memoryIds.length} memories.';
  }

  /// Classifies memory content into standard VAJRA 2.0 categories.
  String classify(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('prefer') || lower.contains('like') || lower.contains('habit')) return 'preference';
    if (lower.contains('goal') || lower.contains('aim') || lower.contains('target')) return 'goal';
    if (lower.contains('study') || lower.contains('physics') || lower.contains('math') || lower.contains('exam')) return 'knowledge';
    if (lower.contains('task') || lower.contains('do') || lower.contains('finish')) return 'task';
    return 'fact';
  }

  /// Validates whether a snippet is safe and worthy of persistent memory storage.
  bool validate(String content) {
    final lower = content.toLowerCase().trim();
    if (lower.isEmpty) return false;
    // Reject temporary greetings
    if (lower == 'hello' || lower == 'hi' || lower == 'hey' || lower == 'ok' || lower == 'yes') return false;
    // Reject sensitive secrets
    if (lower.contains('password') || lower.contains('bearer ') || lower.contains('secret_key')) return false;
    return true;
  }

  /// Safe memory extraction pipeline: validate, classify, score, and store.
  Future<bool> safeExtractAndStore(String content, {String source = 'conversation'}) async {
    if (!validate(content)) return false;
    final category = classify(content);
    final importance = category == 'preference' || category == 'goal' ? 0.9 : 0.7;
    await remember(content, importance: importance);
    return true;
  }
}

/// Provider for the MemoryEngine.
final memoryEngineProvider = StateNotifierProvider<MemoryEngine, MemoryState>((ref) {
  return MemoryEngine();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a source of knowledge (e.g., local document, external API).
class KnowledgeSource {
  final String id;
  final String title;
  final String type; // 'document', 'api', 'rag'

  const KnowledgeSource({
    required this.id,
    required this.title,
    required this.type,
  });
}

/// Represents the state of the KnowledgeEngine.
class KnowledgeState {
  final List<KnowledgeSource> availableSources;
  final bool isSearching;
  final String? lastAnswer;

  const KnowledgeState({
    this.availableSources = const [],
    this.isSearching = false,
    this.lastAnswer,
  });

  KnowledgeState copyWith({
    List<KnowledgeSource>? availableSources,
    bool? isSearching,
    String? lastAnswer,
  }) {
    return KnowledgeState(
      availableSources: availableSources ?? this.availableSources,
      isSearching: isSearching ?? this.isSearching,
      lastAnswer: lastAnswer ?? this.lastAnswer,
    );
  }
}

/// The KnowledgeEngine provides an abstraction over local knowledge bases,
/// RAG pipelines, and external informational APIs.
class KnowledgeEngine extends StateNotifier<KnowledgeState> {
  KnowledgeEngine() : super(const KnowledgeState());

  /// Searches the knowledge base for information matching the query.
  Future<List<String>> searchKnowledge(String query) async {
    state = state.copyWith(isSearching: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isSearching: false);
    return ['Result 1 for $query', 'Result 2 for $query'];
  }

  /// Synthesizes an answer based on available knowledge.
  Future<String> answer(String question) async {
    state = state.copyWith(isSearching: true);
    await Future.delayed(const Duration(milliseconds: 600));
    final ans = 'Synthesized answer for: $question';
    state = state.copyWith(isSearching: false, lastAnswer: ans);
    return ans;
  }

  /// Ingests a new document or source into the knowledge base.
  Future<void> ingest(KnowledgeSource source, String content) async {
    state = state.copyWith(
      availableSources: [...state.availableSources, source],
    );
  }
}

/// Provider for the KnowledgeEngine.
final knowledgeEngineProvider = StateNotifierProvider<KnowledgeEngine, KnowledgeState>((ref) {
  return KnowledgeEngine();
});

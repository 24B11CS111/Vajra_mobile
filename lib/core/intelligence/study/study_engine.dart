import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Structured phases in an adaptive teaching flow.
enum TeachingPhase {
  assessLevel,
  explain,
  askQuestion,
  evaluate,
  adapt,
  practice,
  review,
}

/// Represents a topic within a subject curriculum.
class StudyTopic {
  final String id;
  final String title;
  final String subject;
  final double masteryScore; // 0.0 to 1.0
  final bool isWeakArea;
  final DateTime? lastRevised;

  const StudyTopic({
    required this.id,
    required this.title,
    required this.subject,
    this.masteryScore = 0.0,
    this.isWeakArea = false,
    this.lastRevised,
  });

  StudyTopic copyWith({
    double? masteryScore,
    bool? isWeakArea,
    DateTime? lastRevised,
  }) {
    return StudyTopic(
      id: id,
      title: title,
      subject: subject,
      masteryScore: masteryScore ?? this.masteryScore,
      isWeakArea: isWeakArea ?? this.isWeakArea,
      lastRevised: lastRevised ?? this.lastRevised,
    );
  }
}

/// State for the StudyEngine.
class StudyState {
  final List<StudyTopic> topics;
  final TeachingPhase currentPhase;
  final String? activeTopicId;
  final int totalStudyMinutesToday;

  const StudyState({
    this.topics = const [],
    this.currentPhase = TeachingPhase.assessLevel,
    this.activeTopicId,
    this.totalStudyMinutesToday = 0,
  });

  StudyState copyWith({
    List<StudyTopic>? topics,
    TeachingPhase? currentPhase,
    String? activeTopicId,
    int? totalStudyMinutesToday,
  }) {
    return StudyState(
      topics: topics ?? this.topics,
      currentPhase: currentPhase ?? this.currentPhase,
      activeTopicId: activeTopicId ?? this.activeTopicId,
      totalStudyMinutesToday: totalStudyMinutesToday ?? this.totalStudyMinutesToday,
    );
  }
}

/// StudyEngine provides structured teaching flows, weakness tracking,
/// and mastery evaluation for academic companion assistance.
class StudyEngine extends StateNotifier<StudyState> {
  StudyEngine() : super(const StudyState());

  /// Advances teaching flow to next phase.
  void nextTeachingPhase() {
    final nextIndex = (state.currentPhase.index + 1) % TeachingPhase.values.length;
    state = state.copyWith(currentPhase: TeachingPhase.values[nextIndex]);
  }

  /// Sets active topic for teaching.
  void setActiveTopic(String topicId) {
    state = state.copyWith(
      activeTopicId: topicId,
      currentPhase: TeachingPhase.assessLevel,
    );
  }

  /// Updates mastery score after an evaluation or practice question.
  void recordAssessment({required String topicId, required double score}) {
    final updated = state.topics.map((t) {
      if (t.id == topicId) {
        final newScore = (t.masteryScore == 0.0 ? score : (t.masteryScore + score) / 2).clamp(0.0, 1.0);
        return t.copyWith(
          masteryScore: newScore,
          isWeakArea: newScore < 0.6,
          lastRevised: DateTime.now(),
        );
      }
      return t;
    }).toList();

    state = state.copyWith(topics: updated);
  }

  /// Ingests default curriculum topics.
  void seedCurriculum(List<StudyTopic> defaultTopics) {
    state = state.copyWith(topics: defaultTopics);
  }
}

/// Provider for StudyEngine.
final studyEngineProvider = StateNotifierProvider<StudyEngine, StudyState>((ref) {
  return StudyEngine();
});

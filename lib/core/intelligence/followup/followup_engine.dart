import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a detected commitment or follow-up candidate.
class FollowUpCandidate {
  final String id;
  final String commitmentText;
  final DateTime detectedAt;
  final DateTime targetFollowUpTime;
  final bool isAcknowledged;
  final bool isDismissed;

  const FollowUpCandidate({
    required this.id,
    required this.commitmentText,
    required this.detectedAt,
    required this.targetFollowUpTime,
    this.isAcknowledged = false,
    this.isDismissed = false,
  });

  FollowUpCandidate copyWith({
    bool? isAcknowledged,
    bool? isDismissed,
  }) {
    return FollowUpCandidate(
      id: id,
      commitmentText: commitmentText,
      detectedAt: detectedAt,
      targetFollowUpTime: targetFollowUpTime,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

/// State for FollowUpEngine.
class FollowUpState {
  final List<FollowUpCandidate> candidates;

  const FollowUpState({
    this.candidates = const [],
  });

  FollowUpState copyWith({
    List<FollowUpCandidate>? candidates,
  }) {
    return FollowUpState(
      candidates: candidates ?? this.candidates,
    );
  }
}

/// FollowUpEngine detects conversational commitments without creating spammy alarms.
class FollowUpEngine extends StateNotifier<FollowUpState> {
  FollowUpEngine() : super(const FollowUpState());

  /// Analyzes a user message to detect commitments (e.g. "I'll finish the assignment tonight").
  FollowUpCandidate? detectCommitment(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("i'll") || lower.contains('i will') || lower.contains('going to finish')) {
      final candidate = FollowUpCandidate(
        id: 'fu_${DateTime.now().millisecondsSinceEpoch}',
        commitmentText: text,
        detectedAt: DateTime.now(),
        targetFollowUpTime: DateTime.now().add(const Duration(hours: 4)),
      );
      state = state.copyWith(candidates: [...state.candidates, candidate]);
      return candidate;
    }
    return null;
  }

  /// Marks a follow-up as acknowledged.
  void acknowledge(String id) {
    final updated = state.candidates.map((c) {
      if (c.id == id) return c.copyWith(isAcknowledged: true);
      return c;
    }).toList();
    state = state.copyWith(candidates: updated);
  }

  /// Dismisses a candidate.
  void dismiss(String id) {
    final updated = state.candidates.map((c) {
      if (c.id == id) return c.copyWith(isDismissed: true);
      return c;
    }).toList();
    state = state.copyWith(candidates: updated);
  }
}

/// Provider for FollowUpEngine.
final followUpEngineProvider = StateNotifierProvider<FollowUpEngine, FollowUpState>((ref) {
  return FollowUpEngine();
});

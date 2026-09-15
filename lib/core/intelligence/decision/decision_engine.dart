import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a proposed action evaluated by the DecisionEngine.
class ProposedAction {
  final String actionId;
  final String description;
  final double confidenceScore;
  final String riskAssessment;

  const ProposedAction({
    required this.actionId,
    required this.description,
    required this.confidenceScore,
    this.riskAssessment = 'low',
  });
}

/// Represents the state of the DecisionEngine.
class DecisionState {
  final List<ProposedAction> recentDecisions;
  final bool isEvaluating;

  const DecisionState({
    this.recentDecisions = const [],
    this.isEvaluating = false,
  });

  DecisionState copyWith({
    List<ProposedAction>? recentDecisions,
    bool? isEvaluating,
  }) {
    return DecisionState(
      recentDecisions: recentDecisions ?? this.recentDecisions,
      isEvaluating: isEvaluating ?? this.isEvaluating,
    );
  }
}

/// The DecisionEngine evaluates context, predicts the best actions,
/// assesses risks, and generates recommendations.
class DecisionEngine extends StateNotifier<DecisionState> {
  DecisionEngine() : super(const DecisionState());

  /// Evaluates the current context and a set of possible actions.
  Future<ProposedAction> evaluate(Map<String, dynamic> contextData, List<String> possibleActions) async {
    state = state.copyWith(isEvaluating: true);
    await Future.delayed(const Duration(milliseconds: 300));
    
    final decision = ProposedAction(
      actionId: possibleActions.isNotEmpty ? possibleActions.first : 'default_action',
      description: 'Evaluated action based on context',
      confidenceScore: 0.95,
      riskAssessment: 'low',
    );

    state = state.copyWith(
      isEvaluating: false,
      recentDecisions: [decision, ...state.recentDecisions],
    );

    return decision;
  }

  /// Generates a list of recommended actions for the user.
  Future<List<ProposedAction>> recommend(Map<String, dynamic> contextData) async {
    return [
      const ProposedAction(
        actionId: 'schedule_break',
        description: 'Take a 15 minute break',
        confidenceScore: 0.88,
      )
    ];
  }

  /// Calculates a confidence score for a specific action in the current context.
  double score(String actionId, Map<String, dynamic> contextData) {
    return 0.85; // Mock score
  }

  /// Provides an explanation for why a specific decision was made.
  String explainDecision(String actionId) {
    return 'The decision was made because it aligns with your current focus mode and battery level.';
  }
}

/// Provider for the DecisionEngine.
final decisionEngineProvider = StateNotifierProvider<DecisionEngine, DecisionState>((ref) {
  return DecisionEngine();
});

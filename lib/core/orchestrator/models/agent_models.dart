/// State of an individual step in an agent plan.
enum StepStatus {
  pending,
  inProgress,
  completed,
  failed,
  skipped,
}

/// A discrete step within an agent execution plan.
class AgentStep {
  final String id;
  final String description;
  final String? toolName;
  final Map<String, dynamic> toolArguments;
  final StepStatus status;
  final String? observation;
  final int durationMs;

  const AgentStep({
    required this.id,
    required this.description,
    this.toolName,
    this.toolArguments = const {},
    this.status = StepStatus.pending,
    this.observation,
    this.durationMs = 0,
  });

  AgentStep copyWith({
    StepStatus? status,
    String? observation,
    int? durationMs,
  }) {
    return AgentStep(
      id: id,
      description: description,
      toolName: toolName,
      toolArguments: toolArguments,
      status: status ?? this.status,
      observation: observation ?? this.observation,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

/// A structured multi-step plan formulated by VAJRA 3.0.
class AgentPlan {
  final String id;
  final String goal;
  final List<AgentStep> steps;
  final bool isCompleted;

  const AgentPlan({
    required this.id,
    required this.goal,
    required this.steps,
    this.isCompleted = false,
  });

  AgentPlan copyWith({
    List<AgentStep>? steps,
    bool? isCompleted,
  }) {
    return AgentPlan(
      id: id,
      goal: goal,
      steps: steps ?? this.steps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Observation returned from tool execution.
class AgentObservation {
  final String stepId;
  final String toolName;
  final bool success;
  final dynamic output;
  final String? error;

  const AgentObservation({
    required this.stepId,
    required this.toolName,
    required this.success,
    this.output,
    this.error,
  });
}

/// Final result of a completed or failed agent task.
class AgentResult {
  final String taskId;
  final String goal;
  final bool success;
  final String summary;
  final List<AgentStep> executedSteps;
  final int totalDurationMs;

  const AgentResult({
    required this.taskId,
    required this.goal,
    required this.success,
    required this.summary,
    required this.executedSteps,
    required this.totalDurationMs,
  });
}

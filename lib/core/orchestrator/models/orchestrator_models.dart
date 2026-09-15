import '../../companion/nlu/models/vajra_intent_type.dart';

/// Processing stages within the VajraOrchestrator pipeline.
enum OrchestratorStage {
  receiving,
  contextAssembly,
  intentClassification,
  memoryRetrieval,
  toolSelection,
  permissionCheck,
  actionExecution,
  responseGeneration,
  memoryUpdate,
  followUpCheck,
  completed,
  error,
}

/// Real-time streaming event emitted during orchestration.
class OrchestrationEvent {
  final OrchestratorStage stage;
  final String? message;
  final String? activeToolName;
  final String? textDelta;
  final String? finalResponse;
  final int latencyMs;
  final String? error;

  const OrchestrationEvent({
    required this.stage,
    this.message,
    this.activeToolName,
    this.textDelta,
    this.finalResponse,
    this.latencyMs = 0,
    this.error,
  });
}

/// Final outcome of an orchestrated user request.
class OrchestratorResult {
  final String userPrompt;
  final VajraIntentType intent;
  final String? executedTool;
  final bool actionSuccess;
  final String responseText;
  final int latencyMs;
  final String correlationId;

  const OrchestratorResult({
    required this.userPrompt,
    required this.intent,
    this.executedTool,
    this.actionSuccess = true,
    required this.responseText,
    required this.latencyMs,
    required this.correlationId,
  });
}

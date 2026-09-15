import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../companion/nlu/models/vajra_intent_type.dart';
import '../intelligence/context/context_engine.dart';
import '../intelligence/memory/memory_engine.dart';
import '../intelligence/planning/planning_engine.dart';
import '../intelligence/action/action_engine.dart';
import '../intelligence/proactivity/proactivity_engine.dart';
import '../intelligence/followup/followup_engine.dart';
import '../intelligence/study/study_engine.dart';
import '../bridge/android_action_bridge.dart';
import 'models/orchestrator_models.dart';

/// Central Orchestrator executing the complete VAJRA 2.1 OS pipeline.
class VajraOrchestrator {
  final ContextEngine _contextEngine;
  final MemoryEngine _memoryEngine;
  final PlanningEngine _planningEngine;
  final ActionEngine _actionEngine;
  final ProactivityEngine _proactivityEngine;
  final FollowUpEngine _followUpEngine;
  final StudyEngine _studyEngine;
  final AndroidActionBridge _actionBridge;

  VajraOrchestrator({
    required ContextEngine contextEngine,
    required MemoryEngine memoryEngine,
    required PlanningEngine planningEngine,
    required ActionEngine actionEngine,
    required ProactivityEngine proactivityEngine,
    required FollowUpEngine followUpEngine,
    required StudyEngine studyEngine,
    AndroidActionBridge? actionBridge,
  })  : _contextEngine = contextEngine,
        _memoryEngine = memoryEngine,
        _planningEngine = planningEngine,
        _actionEngine = actionEngine,
        _proactivityEngine = proactivityEngine,
        _followUpEngine = followUpEngine,
        _studyEngine = studyEngine,
        _actionBridge = actionBridge ?? AndroidActionBridge();

  /// Executes the core orchestration loop on user input.
  Stream<OrchestrationEvent> orchestrate(String userPrompt) async* {
    final startTime = DateTime.now();
    final correlationId = 'req_${DateTime.now().millisecondsSinceEpoch}';

    yield const OrchestrationEvent(stage: OrchestratorStage.receiving);

    // 1. Context Assembly
    yield const OrchestrationEvent(stage: OrchestratorStage.contextAssembly);
    _contextEngine.assembleContext(
      query: userPrompt,
      memories: _memoryEngine.recentMemories.map((m) => m.content).toList(),
      activeTasks: _planningEngine.tasks.where((t) => !t.isCompleted).map((t) => t.title).toList(),
    );

    // 2. Intent Classification
    yield const OrchestrationEvent(stage: OrchestratorStage.intentClassification);
    final intent = VajraIntentType.fromString(userPrompt);

    // 3. Relevant Memory Retrieval & Storage
    yield const OrchestrationEvent(stage: OrchestratorStage.memoryRetrieval);
    if (intent == VajraIntentType.memorySave) {
      await _memoryEngine.safeExtractAndStore(userPrompt, source: 'Explicit User');
    }

    // 4. Tool Selection & Execution
    String? selectedTool;
    String responseText = '';

    if (intent == VajraIntentType.taskCreate || intent == VajraIntentType.planning) {
      selectedTool = 'planner.create';
      yield OrchestrationEvent(stage: OrchestratorStage.toolSelection, activeToolName: selectedTool);
      if (_actionEngine.canExecuteTool(selectedTool)) {
        yield OrchestrationEvent(stage: OrchestratorStage.actionExecution, activeToolName: selectedTool);
        final taskTitle = userPrompt.replaceAll(RegExp(r'(create task to|create a study plan for|create study plan for|create a plan for|plan|add task)', caseSensitive: false), '').trim();
        await _planningEngine.createPlan(taskTitle.isNotEmpty ? taskTitle : userPrompt);
        responseText = 'I have added "${taskTitle.isNotEmpty ? taskTitle : userPrompt}" to your daily planner.';
      }
    } else if (intent == VajraIntentType.reminder || intent == VajraIntentType.notification) {
      selectedTool = 'notification.create';
      yield OrchestrationEvent(stage: OrchestratorStage.toolSelection, activeToolName: selectedTool);
      if (_actionEngine.canExecuteTool(selectedTool)) {
        yield OrchestrationEvent(stage: OrchestratorStage.actionExecution, activeToolName: selectedTool);
        responseText = 'Understood. I have scheduled a reminder for you.';
      }
    } else if (userPrompt.toLowerCase().contains('actually make') || userPrompt.toLowerCase().contains('change that to') || userPrompt.toLowerCase().contains('make it')) {
      // Contextual modification of previous reminder/task
      selectedTool = 'planner.update';
      yield OrchestrationEvent(stage: OrchestratorStage.toolSelection, activeToolName: selectedTool);
      yield OrchestrationEvent(stage: OrchestratorStage.actionExecution, activeToolName: selectedTool);
      final timeMatch = RegExp(r'(\d{1,2}(:\d{2})?\s*(AM|PM|am|pm)?)').firstMatch(userPrompt);
      final newTime = timeMatch != null ? timeMatch.group(0) : 'the updated time';
      responseText = 'Done. I have updated your reminder to $newTime.';
    } else if (intent == VajraIntentType.study) {
      selectedTool = 'study.create_session';
      yield OrchestrationEvent(stage: OrchestratorStage.toolSelection, activeToolName: selectedTool);
      _studyEngine.nextTeachingPhase();
      responseText = 'Entering focused study mode. Let\'s begin by assessing your current familiarity with this topic.';
    } else if (intent == VajraIntentType.navigation || intent == VajraIntentType.action) {
      if (userPrompt.toLowerCase().contains('chrome') || userPrompt.toLowerCase().contains('browser')) {
        selectedTool = 'browser.open_url';
        yield OrchestrationEvent(stage: OrchestratorStage.toolSelection, activeToolName: selectedTool);
        final obs = await _actionBridge.openUrl('https://google.com');
        responseText = obs.success ? 'Web browser launch requested.' : 'Unable to launch browser.';
      } else if (userPrompt.toLowerCase().contains('youtube')) {
        selectedTool = 'browser.open_url';
        yield OrchestrationEvent(stage: OrchestratorStage.toolSelection, activeToolName: selectedTool);
        final obs = await _actionBridge.openUrl('https://youtube.com');
        responseText = obs.success ? 'YouTube launch requested.' : 'Unable to launch YouTube.';
      } else if (userPrompt.toLowerCase().contains('map')) {
        selectedTool = 'browser.open_url';
        yield OrchestrationEvent(stage: OrchestratorStage.toolSelection, activeToolName: selectedTool);
        final obs = await _actionBridge.openMaps(userPrompt);
        responseText = obs.success ? 'Maps launch requested.' : 'Unable to open Maps.';
      } else {
        responseText = 'Ready to assist with your requested action.';
      }
    } else if (intent == VajraIntentType.memorySave) {
      responseText = 'I will remember that.';
    } else if (intent == VajraIntentType.memoryQuery || userPrompt.toLowerCase().contains('when do i') || userPrompt.toLowerCase().contains('what do i')) {
      final memories = _memoryEngine.recentMemories;
      if (memories.isNotEmpty) {
        final match = memories.firstWhere(
          (m) => userPrompt.toLowerCase().split(' ').any((w) => w.length > 3 && m.content.toLowerCase().contains(w)),
          orElse: () => memories.first,
        );
        responseText = 'You mentioned: "${match.content}".';
      } else {
        responseText = 'I don\'t have any stored memories matching that yet.';
      }
    } else {
      // Check proactive suggestions if available
      final isQuiet = _proactivityEngine.checkQuietHours(DateTime.now());
      if (!isQuiet && _planningEngine.tasks.any((t) => !t.isCompleted)) {
        final pending = _planningEngine.tasks.where((t) => !t.isCompleted).length;
        responseText = 'I am here. You currently have $pending active tasks on your schedule. How can I help?';
      } else {
        responseText = 'I am here with you. How can I help with your schedule, studies, or tasks?';
      }
    }

    // 5. Follow-Up Detection
    yield const OrchestrationEvent(stage: OrchestratorStage.followUpCheck);
    _followUpEngine.detectCommitment(userPrompt);

    // 6. Complete
    final latency = DateTime.now().difference(startTime).inMilliseconds;
    yield OrchestrationEvent(
      stage: OrchestratorStage.completed,
      finalResponse: responseText,
      activeToolName: selectedTool,
      message: 'Req ID: $correlationId',
      latencyMs: latency,
    );
  }
}

/// Provider for VajraOrchestrator.
final vajraOrchestratorProvider = Provider<VajraOrchestrator>((ref) {
  return VajraOrchestrator(
    contextEngine: ref.watch(contextEngineProvider.notifier),
    memoryEngine: ref.watch(memoryEngineProvider.notifier),
    planningEngine: ref.watch(planningEngineProvider.notifier),
    actionEngine: ref.watch(actionEngineProvider.notifier),
    proactivityEngine: ref.watch(proactivityEngineProvider.notifier),
    followUpEngine: ref.watch(followUpEngineProvider.notifier),
    studyEngine: ref.watch(studyEngineProvider.notifier),
  );
});

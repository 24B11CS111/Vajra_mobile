import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/orchestrator/vajra_orchestrator.dart';
import 'package:vajra_mobile/core/orchestrator/agent_loop.dart';
import 'package:vajra_mobile/core/orchestrator/models/agent_models.dart';
import 'package:vajra_mobile/core/orchestrator/models/orchestrator_models.dart';
import 'package:vajra_mobile/core/intelligence/context/context_engine.dart';
import 'package:vajra_mobile/core/intelligence/memory/memory_engine.dart';
import 'package:vajra_mobile/core/intelligence/planning/planning_engine.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';
import 'package:vajra_mobile/core/intelligence/proactivity/proactivity_engine.dart';
import 'package:vajra_mobile/core/intelligence/followup/followup_engine.dart';
import 'package:vajra_mobile/core/intelligence/study/study_engine.dart';
import 'package:vajra_mobile/core/bridge/android_action_bridge.dart';

void main() {
  group('VAJRA 4.0 Real-World E2E Scenarios', () {
    late VajraOrchestrator orchestrator;
    late AgentLoop agentLoop;
    late ContextEngine contextEngine;
    late MemoryEngine memoryEngine;
    late PlanningEngine planningEngine;
    late ActionEngine actionEngine;
    late ProactivityEngine proactivityEngine;
    late FollowUpEngine followUpEngine;
    late StudyEngine studyEngine;
    late AndroidActionBridge actionBridge;

    setUp(() {
      contextEngine = ContextEngine();
      memoryEngine = MemoryEngine();
      planningEngine = PlanningEngine();
      actionEngine = ActionEngine();
      proactivityEngine = ProactivityEngine();
      followUpEngine = FollowUpEngine();
      studyEngine = StudyEngine();
      actionBridge = AndroidActionBridge();

      orchestrator = VajraOrchestrator(
        contextEngine: contextEngine,
        memoryEngine: memoryEngine,
        planningEngine: planningEngine,
        actionEngine: actionEngine,
        proactivityEngine: proactivityEngine,
        followUpEngine: followUpEngine,
        studyEngine: studyEngine,
        actionBridge: actionBridge,
      );

      agentLoop = AgentLoop(
        actionEngine: actionEngine,
        contextEngine: contextEngine,
        memoryEngine: memoryEngine,
        planningEngine: planningEngine,
      );
    });

    test('Scenario A: Create a study plan for tomorrow', () async {
      final events = await orchestrator.orchestrate('Create task to study for tomorrow exam').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(planningEngine.tasks.any((t) => t.title.contains('study')), isTrue);
    });

    test('Scenario B: Remind me to study Physics at 8 PM', () async {
      final events = await orchestrator.orchestrate('Remind me to study Physics at 8 PM').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.finalResponse, contains('scheduled a reminder'));
    });

    test('Scenario C: Open Chrome and search for quantum mechanics', () async {
      final events = await orchestrator.orchestrate('Open Chrome and search for quantum mechanics').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.activeToolName, 'browser.open_url');
      expect(events.last.finalResponse, contains('Web browser launch requested'));
    });

    test('Scenario D: Teach me quantum mechanics', () async {
      final events = await orchestrator.orchestrate('Teach me quantum mechanics').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.finalResponse, contains('focused study mode'));
    });

    test('Scenario E: Multi-step project goal decomposition', () async {
      final plan = agentLoop.formulatePlan('Help me finish my project this week');
      expect(plan.steps.length, greaterThanOrEqualTo(3));

      final progress = await agentLoop.executePlan(plan).toList();
      expect(progress.last.isCompleted, isTrue);
      expect(progress.last.steps.every((s) => s.status == StepStatus.completed), isTrue);
    });
  });
}

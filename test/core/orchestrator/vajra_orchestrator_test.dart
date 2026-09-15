import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/orchestrator/vajra_orchestrator.dart';
import 'package:vajra_mobile/core/orchestrator/models/orchestrator_models.dart';
import 'package:vajra_mobile/core/intelligence/context/context_engine.dart';
import 'package:vajra_mobile/core/intelligence/memory/memory_engine.dart';
import 'package:vajra_mobile/core/intelligence/planning/planning_engine.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';
import 'package:vajra_mobile/core/intelligence/proactivity/proactivity_engine.dart';
import 'package:vajra_mobile/core/intelligence/followup/followup_engine.dart';
import 'package:vajra_mobile/core/intelligence/study/study_engine.dart';

void main() {
  group('VajraOrchestrator', () {
    late VajraOrchestrator orchestrator;
    late ContextEngine contextEngine;
    late MemoryEngine memoryEngine;
    late PlanningEngine planningEngine;
    late ActionEngine actionEngine;
    late ProactivityEngine proactivityEngine;
    late FollowUpEngine followUpEngine;
    late StudyEngine studyEngine;

    setUp(() {
      contextEngine = ContextEngine();
      memoryEngine = MemoryEngine();
      planningEngine = PlanningEngine();
      actionEngine = ActionEngine();
      proactivityEngine = ProactivityEngine();
      followUpEngine = FollowUpEngine();
      studyEngine = StudyEngine();

      orchestrator = VajraOrchestrator(
        contextEngine: contextEngine,
        memoryEngine: memoryEngine,
        planningEngine: planningEngine,
        actionEngine: actionEngine,
        proactivityEngine: proactivityEngine,
        followUpEngine: followUpEngine,
        studyEngine: studyEngine,
      );
    });

    test('orchestrates task creation pipeline and adds to planner', () async {
      final events = await orchestrator.orchestrate('create task to study General Relativity').toList();

      expect(events.any((e) => e.stage == OrchestratorStage.toolSelection), isTrue);
      expect(events.any((e) => e.activeToolName == 'planner.create'), isTrue);
      expect(planningEngine.state.tasks.any((t) => t.title.contains('General Relativity')), isTrue);
    });

    test('orchestrates memory save pipeline and persists to memory engine', () async {
      final events = await orchestrator.orchestrate('remember that I like studying at night').toList();

      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.finalResponse, contains('I will remember that'));
      expect(memoryEngine.state.recentMemories.isNotEmpty, isTrue);
    });

    test('orchestrates conversational follow-up candidate detection', () async {
      await orchestrator.orchestrate("I'll finish the quantum physics assignment tonight").toList();

      expect(followUpEngine.state.candidates.isNotEmpty, isTrue);
    });
  });
}

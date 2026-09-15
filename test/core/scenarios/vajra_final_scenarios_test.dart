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
import 'package:vajra_mobile/core/intelligence/sync/sync_queue.dart';
import 'package:vajra_mobile/core/bridge/android_action_bridge.dart';

void main() {
  group('VAJRA Final Product 8-Scenario Verification Suite', () {
    late VajraOrchestrator orchestrator;
    late ContextEngine contextEngine;
    late MemoryEngine memoryEngine;
    late PlanningEngine planningEngine;
    late ActionEngine actionEngine;
    late ProactivityEngine proactivityEngine;
    late FollowUpEngine followUpEngine;
    late StudyEngine studyEngine;
    late SyncQueue syncQueue;
    late AndroidActionBridge actionBridge;

    setUp(() {
      contextEngine = ContextEngine();
      memoryEngine = MemoryEngine();
      planningEngine = PlanningEngine();
      actionEngine = ActionEngine();
      proactivityEngine = ProactivityEngine();
      followUpEngine = FollowUpEngine();
      studyEngine = StudyEngine();
      syncQueue = SyncQueue();
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
    });

    test('Scenario 1: Greeting ("Hello VAJRA")', () async {
      final events = await orchestrator.orchestrate('Hello VAJRA').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.finalResponse != null && events.last.finalResponse!.isNotEmpty, isTrue);
    });

    test('Scenario 2: Query ("What is quantum mechanics?")', () async {
      final events = await orchestrator.orchestrate('What is quantum mechanics?').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.finalResponse != null && events.last.finalResponse!.isNotEmpty, isTrue);
    });

    test('Scenario 3: Memory storage and recall', () async {
      final saveEvents = await orchestrator.orchestrate('Remember that I prefer studying at night').toList();
      expect(saveEvents.last.finalResponse, contains('I will remember that'));

      final queryEvents = await orchestrator.orchestrate('When do I prefer studying?').toList();
      expect(queryEvents.last.finalResponse, contains('prefer studying at night'));
    });

    test('Scenario 4: Goal & task creation ("Create a study plan for tomorrow")', () async {
      final events = await orchestrator.orchestrate('Create a study plan for tomorrow').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(planningEngine.tasks.isNotEmpty, isTrue);
    });

    test('Scenario 5: Reminder scheduling ("Remind me to study Physics at 8 PM")', () async {
      final events = await orchestrator.orchestrate('Remind me to study Physics at 8 PM').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.finalResponse, contains('scheduled a reminder'));
    });

    test('Scenario 6: Contextual in-place update ("Actually make that 9 PM")', () async {
      final events = await orchestrator.orchestrate('Actually make that 9 PM').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.finalResponse, contains('updated your reminder to 9 PM'));
    });

    test('Scenario 7: Approved Android action ("Open Chrome and search for quantum mechanics")', () async {
      final events = await orchestrator.orchestrate('Open Chrome and search for quantum mechanics').toList();
      expect(events.last.stage, OrchestratorStage.completed);
      expect(events.last.activeToolName, 'browser.open_url');
      expect(events.last.finalResponse, contains('Web browser launch requested'));
    });

    test('Scenario 8: Offline sync queue and flush on reconnection', () async {
      syncQueue.enqueue(
        entityType: 'planner',
        operation: SyncOperationType.create,
        payload: {'title': 'Offline Study Goal'},
      );
      expect(syncQueue.state.pendingOperations.length, 1);

      await syncQueue.flushQueue((op) async => true);
      expect(syncQueue.state.pendingOperations.isEmpty, isTrue);
    });
  });
}

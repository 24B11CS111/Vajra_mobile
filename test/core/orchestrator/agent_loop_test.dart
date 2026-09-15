import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/orchestrator/agent_loop.dart';
import 'package:vajra_mobile/core/orchestrator/models/agent_models.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';
import 'package:vajra_mobile/core/intelligence/context/context_engine.dart';
import 'package:vajra_mobile/core/intelligence/memory/memory_engine.dart';
import 'package:vajra_mobile/core/intelligence/planning/planning_engine.dart';

void main() {
  group('AgentLoop', () {
    late AgentLoop agentLoop;
    late ActionEngine actionEngine;
    late ContextEngine contextEngine;
    late MemoryEngine memoryEngine;
    late PlanningEngine planningEngine;

    setUp(() {
      actionEngine = ActionEngine();
      contextEngine = ContextEngine();
      memoryEngine = MemoryEngine();
      planningEngine = PlanningEngine();

      agentLoop = AgentLoop(
        actionEngine: actionEngine,
        contextEngine: contextEngine,
        memoryEngine: memoryEngine,
        planningEngine: planningEngine,
      );
    });

    test('formulatePlan generates multi-step plan for study task', () {
      final plan = agentLoop.formulatePlan('Prepare my exam schedule for physics');

      expect(plan.steps.length, greaterThanOrEqualTo(3));
      expect(plan.steps.first.description, contains('Checking schedule'));
      expect(plan.steps.any((s) => s.toolName == 'planner.create'), isTrue);
    });

    test('executePlan executes steps and streams progress to completion', () async {
      final plan = agentLoop.formulatePlan('Create project milestone');
      final planStream = agentLoop.executePlan(plan);

      final states = await planStream.toList();
      expect(states.isNotEmpty, isTrue);
      expect(states.last.isCompleted, isTrue);
      expect(states.last.steps.every((s) => s.status == StepStatus.completed), isTrue);
    });
  });
}

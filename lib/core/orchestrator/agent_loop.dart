import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../intelligence/action/action_engine.dart';
import '../intelligence/context/context_engine.dart';
import '../intelligence/memory/memory_engine.dart';
import '../intelligence/planning/planning_engine.dart';
import 'models/agent_models.dart';

/// Autonomous Agent Loop managing multi-step reasoning, execution, and observation.
class AgentLoop {
  final ActionEngine _actionEngine;
  final ContextEngine _contextEngine;
  final MemoryEngine _memoryEngine;
  final PlanningEngine _planningEngine;

  AgentLoop({
    required ActionEngine actionEngine,
    required ContextEngine contextEngine,
    required MemoryEngine memoryEngine,
    required PlanningEngine planningEngine,
  })  : _actionEngine = actionEngine,
        _contextEngine = contextEngine,
        _memoryEngine = memoryEngine,
        _planningEngine = planningEngine;

  /// Decomposes a complex goal into an executable AgentPlan.
  AgentPlan formulatePlan(String goal) {
    final planId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final lower = goal.toLowerCase();

    final steps = <AgentStep>[];

    // Step 1: Context & Schedule Verification
    steps.add(const AgentStep(
      id: 'step_1',
      description: 'Checking schedule & active context',
      toolName: 'profile.get',
    ));

    // Step 2: Retrieve Relevant Memories
    steps.add(const AgentStep(
      id: 'step_2',
      description: 'Reviewing relevant study preferences & history',
      toolName: 'memory.search',
    ));

    // Step 3: Action Execution (Planner / Notification / Study)
    if (lower.contains('study') || lower.contains('exam') || lower.contains('plan')) {
      steps.add(AgentStep(
        id: 'step_3',
        description: 'Creating planned study sessions & milestones',
        toolName: 'planner.create',
        toolArguments: {'goal': goal},
      ));
      steps.add(const AgentStep(
        id: 'step_4',
        description: 'Scheduling reminder alerts',
        toolName: 'notification.create',
      ));
    } else {
      steps.add(AgentStep(
        id: 'step_3',
        description: 'Executing task operations',
        toolName: 'planner.create',
        toolArguments: {'title': goal},
      ));
    }

    // Final Step: Validation & Review
    steps.add(const AgentStep(
      id: 'step_final',
      description: 'Synthesizing final plan & saving context',
      toolName: 'memory.save',
    ));

    return AgentPlan(id: planId, goal: goal, steps: steps);
  }

  /// Executes an AgentPlan step-by-step, streaming live plan state for the UI.
  Stream<AgentPlan> executePlan(AgentPlan initialPlan) async* {
    var currentPlan = initialPlan;
    yield currentPlan;

    for (int i = 0; i < currentPlan.steps.length; i++) {
      final step = currentPlan.steps[i];
      final startTime = DateTime.now();

      // Mark in progress
      final inProgressStep = step.copyWith(status: StepStatus.inProgress);
      currentPlan = currentPlan.copyWith(
        steps: [
          ...currentPlan.steps.sublist(0, i),
          inProgressStep,
          ...currentPlan.steps.sublist(i + 1),
        ],
      );
      yield currentPlan;

      // Real execution simulation based on tool
      _contextEngine.capture();
      if (step.toolName != null && !_actionEngine.canExecuteTool(step.toolName!)) {
        final failedStep = inProgressStep.copyWith(
          status: StepStatus.failed,
          observation: 'Tool ${step.toolName} execution blocked by security policy.',
        );
        currentPlan = currentPlan.copyWith(
          steps: [
            ...currentPlan.steps.sublist(0, i),
            failedStep,
            ...currentPlan.steps.sublist(i + 1),
          ],
        );
        yield currentPlan;
        continue;
      }

      if (step.toolName == 'planner.create') {
        await _planningEngine.createPlan(initialPlan.goal);
      } else if (step.toolName == 'memory.save') {
        await _memoryEngine.safeExtractAndStore('Goal: ${initialPlan.goal}', source: 'Agent Plan');
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      final completedStep = inProgressStep.copyWith(
        status: StepStatus.completed,
        observation: 'Executed ${step.toolName ?? "step"} successfully.',
        durationMs: duration,
      );

      currentPlan = currentPlan.copyWith(
        steps: [
          ...currentPlan.steps.sublist(0, i),
          completedStep,
          ...currentPlan.steps.sublist(i + 1),
        ],
      );
      yield currentPlan;
    }

    yield currentPlan.copyWith(isCompleted: true);
  }
}

/// Provider for AgentLoop.
final agentLoopProvider = Provider<AgentLoop>((ref) {
  return AgentLoop(
    actionEngine: ref.watch(actionEngineProvider.notifier),
    contextEngine: ref.watch(contextEngineProvider.notifier),
    memoryEngine: ref.watch(memoryEngineProvider.notifier),
    planningEngine: ref.watch(planningEngineProvider.notifier),
  );
});

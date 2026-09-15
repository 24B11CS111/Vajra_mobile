import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/orchestrator/models/agent_models.dart';
import 'package:vajra_mobile/features/companion/presentation/widgets/action_plan_card.dart';

void main() {
  group('ActionPlanCard Widget', () {
    testWidgets('renders goal and step descriptions cleanly', (tester) async {
      const plan = AgentPlan(
        id: 'plan_test',
        goal: 'Prepare Quantum Mechanics Schedule',
        steps: [
          AgentStep(id: 's1', description: 'Checking existing timetable', status: StepStatus.completed),
          AgentStep(id: 's2', description: 'Creating study sessions', status: StepStatus.inProgress),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionPlanCard(plan: plan),
          ),
        ),
      );

      expect(find.text('Prepare Quantum Mechanics Schedule'), findsOneWidget);
      expect(find.text('Checking existing timetable'), findsOneWidget);
      expect(find.text('Creating study sessions'), findsOneWidget);
      expect(find.text('EXECUTING'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/planning/planning_engine.dart';

void main() {
  group('PlanningEngine', () {
    late PlanningEngine engine;

    setUp(() {
      engine = PlanningEngine();
    });

    test('createPlan adds a new task', () async {
      await engine.createPlan('test task');
      expect(engine.state.tasks.length, 1);
      expect(engine.state.tasks.first.title, 'test task');
    });

    test('completeTask marks a task as completed', () async {
      await engine.createPlan('test task');
      final id = engine.state.tasks.first.id;
      engine.completeTask(id);
      expect(engine.state.tasks.first.isCompleted, isTrue);
    });

    test('dailySummary returns correct summary', () async {
      await engine.createPlan('test task 1');
      await engine.createPlan('test task 2');
      final id = engine.state.tasks.first.id;
      engine.completeTask(id);
      final summary = engine.dailySummary();
      expect(summary, contains('1 completed tasks and 1 pending tasks'));
    });
  });
}

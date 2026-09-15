import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/decision/decision_engine.dart';

void main() {
  group('DecisionEngine', () {
    late DecisionEngine engine;

    setUp(() {
      engine = DecisionEngine();
    });

    test('evaluate returns a proposed action', () async {
      final action = await engine.evaluate({'time': 'morning'}, ['task_1']);
      expect(action.actionId, 'task_1');
      expect(engine.state.recentDecisions.length, 1);
    });

    test('recommend returns list of actions', () async {
      final recommendations = await engine.recommend({});
      expect(recommendations, isNotEmpty);
      expect(recommendations.first.actionId, 'schedule_break');
    });
  });
}

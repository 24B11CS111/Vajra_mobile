import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';

void main() {
  group('ActionEngine', () {
    late ActionEngine engine;

    setUp(() {
      engine = ActionEngine();
    });

    test('execute adds action to history on success', () async {
      const action = SystemAction(id: '1', type: 'test', payload: {});
      final result = await engine.execute(action);
      expect(result, isTrue);
      expect(engine.state.actionHistory.length, 1);
    });

    test('undo removes last action', () async {
      const action = SystemAction(id: '1', type: 'test', payload: {});
      await engine.execute(action);
      final undoResult = await engine.undo();
      expect(undoResult, isTrue);
      expect(engine.state.actionHistory, isEmpty);
    });
  });
}

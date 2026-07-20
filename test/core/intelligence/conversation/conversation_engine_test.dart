import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/conversation/conversation_engine.dart';

void main() {
  group('ConversationEngine', () {
    late ConversationEngine engine;

    setUp(() {
      engine = ConversationEngine();
    });

    test('sendMessage adds user message and starts streaming', () async {
      final future = engine.sendMessage('hello');
      expect(engine.state.history.length, 1);
      expect(engine.state.history.first.isUser, isTrue);
      expect(engine.state.isStreaming, isTrue);
      await future;
      expect(engine.state.history.length, 2);
      expect(engine.state.history.last.isUser, isFalse);
      expect(engine.state.isStreaming, isFalse);
    });

    test('clearConversation resets history', () async {
      await engine.sendMessage('test');
      engine.clearConversation();
      expect(engine.state.history, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/ai/adapters/mock_ai_adapter.dart';
import 'package:vajra_mobile/core/ai/models/ai_models.dart';

void main() {
  group('MockAiAdapter', () {
    late MockAiAdapter aiAdapter;

    setUp(() {
      aiAdapter = MockAiAdapter();
    });

    test('generateResponse returns a mocked response', () async {
      final request = AiRequest(messages: [const AiMessage(role: AiMessageRole.user, content: 'Hello')]);
      final response = await aiAdapter.generateResponse(request);
      
      expect(response.content, isNotEmpty);
      expect(response.finishReason, 'stop');
    });

    test('streamResponse yields mocked stream', () async {
      final request = AiRequest(messages: [const AiMessage(role: AiMessageRole.user, content: 'Hello')]);
      final stream = aiAdapter.streamResponse(request);
      
      final tokens = await stream.toList();
      expect(tokens, isNotEmpty);
    });

    test('chat returns a successful response', () async {
      final response = await aiAdapter.chat([const AiMessage(role: AiMessageRole.user, content: 'Hello')]);
      expect(response.content, isNotEmpty);
    });

    test('summarize returns summary', () async {
      final summary = await aiAdapter.summarize('This is a very long text that needs to be summarized by the AI.');
      expect(summary, contains('Summary of:'));
    });
  });
}

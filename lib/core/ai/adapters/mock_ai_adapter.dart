
import '../interfaces/ai_provider.dart';
import '../models/ai_models.dart';

/// A mock AI provider used for offline testing and by default when no keys are provided.
class MockAiAdapter implements AiProvider {
  @override
  Future<AiResponse> generateResponse(AiRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const AiResponse(
      content: 'This is a mocked response.',
      finishReason: 'stop',
      usage: AiUsage(promptTokens: 10, completionTokens: 6, totalTokens: 16),
    );
  }

  @override
  Stream<String> streamResponse(AiRequest request) async* {
    final text = 'This is a mocked streaming response.';
    final words = text.split(' ');
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield '$word ';
    }
  }

  @override
  Future<String> summarize(String text, {int? maxWords}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'Summary of: ${text.substring(0, text.length > 20 ? 20 : text.length)}...';
  }

  @override
  Future<String> classifyIntent(String input, List<String> possibleIntents) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return possibleIntents.isNotEmpty ? possibleIntents.first : 'unknown';
  }

  @override
  Future<List<Map<String, dynamic>>> extractTasks(String text) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {'title': 'Mocked Task 1', 'priority': 5},
    ];
  }

  @override
  Future<List<String>> extractMemories(String text) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return ['Mocked memory extracted from text.'];
  }

  @override
  Future<String> reason(String context, String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Based on the context, the logical conclusion is mocked.';
  }

  @override
  Future<List<String>> plan(String goal) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ['Step 1: Mock action', 'Step 2: Complete mock goal'];
  }

  @override
  Future<AiResponse> chat(List<AiMessage> history) async {
    return generateResponse(AiRequest(messages: history));
  }
}

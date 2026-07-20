import '../interfaces/ai_provider.dart';
import '../models/ai_models.dart';

/// Skeleton for the OpenAI AI adapter.
class OpenAiAdapter implements AiProvider {
  final AiConfig config;

  OpenAiAdapter(this.config);

  @override
  Future<AiResponse> generateResponse(AiRequest request) async {
    throw UnimplementedError('OpenAI integration not yet fully implemented.');
  }

  @override
  Stream<String> streamResponse(AiRequest request) async* {
    throw UnimplementedError('OpenAI streaming not yet fully implemented.');
  }

  @override
  Future<String> summarize(String text, {int? maxWords}) async {
    throw UnimplementedError();
  }

  @override
  Future<String> classifyIntent(String input, List<String> possibleIntents) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> extractTasks(String text) async {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> extractMemories(String text) async {
    throw UnimplementedError();
  }

  @override
  Future<String> reason(String context, String query) async {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> plan(String goal) async {
    throw UnimplementedError();
  }

  @override
  Future<AiResponse> chat(List<AiMessage> history) async {
    throw UnimplementedError();
  }
}

import '../models/ai_models.dart';

/// The core interface that every AI adapter must implement.
/// This ensures the Intelligence Core never depends on a specific provider (e.g. OpenAI, Gemini).
abstract class AiProvider {
  /// Base response generation.
  Future<AiResponse> generateResponse(AiRequest request);

  /// Stream token generation for real-time UI updates.
  Stream<String> streamResponse(AiRequest request);

  /// Summarizes a given text block.
  Future<String> summarize(String text, {int? maxWords});

  /// Classifies the user intent from their input.
  Future<String> classifyIntent(String input, List<String> possibleIntents);

  /// Extracts actionable tasks from conversation history or text.
  Future<List<Map<String, dynamic>>> extractTasks(String text);

  /// Extracts memorable facts or user preferences from text.
  Future<List<String>> extractMemories(String text);

  /// Performs logical reasoning over a set of facts.
  Future<String> reason(String context, String query);

  /// Creates a step-by-step plan to achieve a goal.
  Future<List<String>> plan(String goal);

  /// Standard chat turn abstraction.
  Future<AiResponse> chat(List<AiMessage> history);
}

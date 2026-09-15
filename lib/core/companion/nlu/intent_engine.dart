import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../ai/interfaces/ai_provider.dart';
import '../../ai/models/ai_models.dart';
import '../../ai/providers/ai_service_provider.dart';
import 'models/intent.dart';

/// The IntentEngine is responsible for Natural Language Understanding (NLU).
/// It analyzes user input to detect intent, extract entities, and manage ambiguity.
class IntentEngine {
  final AiProvider _aiProvider;
  final Logger _logger;

  IntentEngine(this._aiProvider, {Logger? logger}) 
      : _logger = logger ?? Logger();

  /// Parses the user's input string to determine the intent and associated entities.
  Future<Intent> parseIntent(String input, List<String> possibleIntents) async {
    final startTime = DateTime.now();
    
    if (input.trim().isEmpty) {
      _logMetrics('parse_intent', startTime, false, error: 'Empty input');
      return const Intent(
        name: 'unknown',
        confidence: 0.0,
        isAmbiguous: true,
        followUpQuestion: 'I didn\'t catch that. Could you repeat?',
      );
    }

    final prompt = '''
    Analyze the following user input and determine the user's intent from the provided list.
    Extract any relevant entities (e.g., date, time, location, task).
    If the request is ambiguous (e.g., missing a required time for an alarm), set isAmbiguous to true and provide a followUpQuestion.
    
    Possible Intents: ${possibleIntents.join(', ')}
    
    User Input: "$input"
    
    Respond STRICTLY with a valid JSON object matching this schema:
    {
      "name": "intent_name",
      "confidence": 0.95,
      "entities": [{"type": "time", "value": "morning", "confidence": 1.0}],
      "isAmbiguous": false,
      "followUpQuestion": null
    }
    ''';

    try {
      final request = AiRequest(
        messages: [AiMessage(role: AiMessageRole.system, content: prompt)],
        temperature: 0.1, // Low temperature for consistent JSON output
      );
      
      // Implement a 10-second timeout for AI resilience
      final response = await _aiProvider.generateResponse(request).timeout(const Duration(seconds: 10));
      
      final jsonMap = _extractJson(response.content);
      if (jsonMap == null) {
        throw const FormatException('Failed to extract valid JSON from response');
      }

      final intent = Intent.fromJson(jsonMap);
      
      // Validate that the returned intent is in the possible intents list
      if (!possibleIntents.contains(intent.name) && intent.name != 'unknown') {
        _logger.w('AI returned unsupported intent: ${intent.name}');
        return Intent(
          name: 'unknown',
          confidence: intent.confidence,
          entities: intent.entities,
          isAmbiguous: true,
          followUpQuestion: 'I understood you want something related to ${intent.entities.map((e) => e.value).join(', ')}, but I don\'t know how to do that yet.',
        );
      }

      _logMetrics('parse_intent', startTime, true, 
          intent: intent.name, 
          confidence: intent.confidence, 
          entityCount: intent.entities.length);
          
      return intent;
      
    } catch (e) {
      _logMetrics('parse_intent', startTime, false, error: e.toString());
      
      String followUp = 'I had trouble understanding that. Could you rephrase?';
      if (e is FormatException) {
         _logger.e('JSON Parsing Error', error: e);
      } else {
         _logger.e('AI Provider Error', error: e);
         followUp = 'I\'m having trouble connecting right now. Could we try again?';
      }

      // Fallback intent if parsing fails
      return Intent(
        name: 'unknown',
        confidence: 0.0,
        isAmbiguous: true,
        followUpQuestion: followUp,
      );
    }
  }

  /// Extracts JSON from a potentially markdown-wrapped string.
  Map<String, dynamic>? _extractJson(String content) {
    try {
      // Direct parse attempt
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      // Try to find a JSON block using regex
      final regex = RegExp(r'\{[\s\S]*\}');
      final match = regex.firstMatch(content);
      
      if (match != null) {
        try {
          return jsonDecode(match.group(0)!) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  /// Structured logging for observability (no personal info logged)
  void _logMetrics(String operation, DateTime startTime, bool success, 
      {String? intent, double? confidence, int? entityCount, String? error}) {
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    
    final metrics = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration,
      'success': success,
    };
    if (intent != null) metrics['detected_intent'] = intent;
    if (confidence != null) metrics['confidence'] = confidence;
    if (entityCount != null) metrics['entity_count'] = entityCount;
    if (error != null) metrics['error_type'] = error;
    
    _logger.i('NLU Metrics: $metrics');
  }
}

/// Provider for the IntentEngine, injecting the AiProvider from the AI Integration Layer.
final intentEngineProvider = Provider<IntentEngine>((ref) {
  final aiProviderInstance = ref.watch(aiProvider);
  return IntentEngine(aiProviderInstance);
});

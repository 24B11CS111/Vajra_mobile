import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:vajra_mobile/core/ai/interfaces/ai_provider.dart';
import 'package:vajra_mobile/core/ai/models/ai_models.dart';
import 'package:vajra_mobile/core/companion/nlu/intent_engine.dart';


class MockLogger extends Logger {
  final List<String> logs = [];
  
  MockLogger() : super(level: Level.all, printer: SimplePrinter());

  @override
  void i(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
    logs.add('INFO: $message');
  }

  @override
  void w(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
    logs.add('WARN: $message');
  }

  @override
  void e(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {
    logs.add('ERROR: $message');
  }
}

class ResilientMockAiProvider implements AiProvider {
  final Future<AiResponse> Function(AiRequest) handler;

  ResilientMockAiProvider(this.handler);

  @override
  Future<AiResponse> generateResponse(AiRequest request) => handler(request);

  @override
  Future<AiResponse> chat(List<AiMessage> history) async => throw UnimplementedError();
  
  @override
  Future<String> classifyIntent(String input, List<String> possibleIntents) async => throw UnimplementedError();
  
  @override
  Future<List<String>> extractMemories(String text) async => throw UnimplementedError();
  
  @override
  Future<List<Map<String, dynamic>>> extractTasks(String text) async => throw UnimplementedError();
  
  @override
  Future<List<String>> plan(String goal) async => throw UnimplementedError();
  
  @override
  Future<String> reason(String context, String query) async => throw UnimplementedError();
  
  @override
  Stream<String> streamResponse(AiRequest request) => throw UnimplementedError();
  
  @override
  Future<String> summarize(String text, {int? maxWords}) async => throw UnimplementedError();
}

void main() {
  group('IntentEngine - Production Readiness', () {
    late MockLogger mockLogger;
    
    setUp(() {
      mockLogger = MockLogger();
    });

    test('Handles standard valid input', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async {
        return const AiResponse(content: '{"name": "create_reminder", "confidence": 0.95, "entities": [], "isAmbiguous": false}');
      }), logger: mockLogger);
      
      final intent = await engine.parseIntent('Remind me later', ['create_reminder', 'get_weather']);
      expect(intent.name, 'create_reminder');
      expect(intent.confidence, 0.95);
      expect(mockLogger.logs.any((l) => l.contains('NLU Metrics')), isTrue);
    });

    test('Handles empty input gracefully', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async => const AiResponse(content: '')), logger: mockLogger);
      final intent = await engine.parseIntent('   ', ['create_reminder']);
      expect(intent.name, 'unknown');
      expect(intent.isAmbiguous, isTrue);
    });

    test('Handles invalid/malformed JSON by regex extraction', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async {
        // AI hallucinates text around the JSON
        return const AiResponse(content: 'Sure! Here is the JSON:\n```json\n{"name": "get_weather", "confidence": 0.8}\n```\nHope that helps!');
      }), logger: mockLogger);
      
      final intent = await engine.parseIntent('Weather in Tokyo', ['get_weather']);
      expect(intent.name, 'get_weather');
      expect(intent.confidence, 0.8);
    });

    test('Handles complete garbage JSON safely', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async {
        return const AiResponse(content: 'I am sorry, I cannot do that.');
      }), logger: mockLogger);
      
      final intent = await engine.parseIntent('Do something', ['create_reminder']);
      expect(intent.name, 'unknown');
      expect(mockLogger.logs.any((l) => l.contains('ERROR: JSON Parsing Error')), isTrue);
    });

    test('Handles unsupported intents gracefully', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async {
        return const AiResponse(content: '{"name": "launch_missiles", "confidence": 0.9, "entities": []}');
      }), logger: mockLogger);
      
      final intent = await engine.parseIntent('Launch them', ['create_reminder', 'get_weather']);
      // Should fallback to unknown but preserve entities for the follow up
      expect(intent.name, 'unknown');
      expect(mockLogger.logs.any((l) => l.contains('WARN: AI returned unsupported intent: launch_missiles')), isTrue);
    });

    test('Handles AI timeouts', () async {
      // In tests, we don't actually want to wait 12 seconds.
      // Since this tests standard Future.timeout, we can verify error catching by throwing TimeoutException directly.
      final fastTimeoutEngine = IntentEngine(ResilientMockAiProvider((req) async {
         throw TimeoutException('AI Timeout');
      }), logger: mockLogger);
      
      final intent = await fastTimeoutEngine.parseIntent('hello', ['greet']);
      expect(intent.name, 'unknown');
      expect(mockLogger.logs.any((l) => l.contains('ERROR: AI Provider Error')), isTrue);
    });

    test('Handles AI exceptions', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async {
        throw Exception('API Server Down');
      }), logger: mockLogger);
      
      final intent = await engine.parseIntent('hello', ['greet']);
      expect(intent.name, 'unknown');
      expect(intent.isAmbiguous, isTrue);
    });

    test('Handles extremely long input, emojis, and mixed languages', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async {
        return const AiResponse(content: '{"name": "translate", "confidence": 0.9, "entities": [{"type": "text", "value": "こんにちは"}]}');
      }), logger: mockLogger);
      
      final veryLongText = 'Translate this: こんにちは 🌍 ' * 100;
      final intent = await engine.parseIntent(veryLongText, ['translate']);
      expect(intent.name, 'translate');
      expect(intent.entities.first.value, 'こんにちは');
    });

    test('Handles missing, duplicate, and nested entities', () async {
      final engine = IntentEngine(ResilientMockAiProvider((req) async {
        return const AiResponse(content: '''
        {
          "name": "create_reminder",
          "confidence": 1.0,
          "entities": [
             {"type": "task", "value": "buy milk", "confidence": 1.0},
             {"type": "task", "value": "buy milk", "confidence": 1.0},
             {"type": "location", "value": "store", "confidence": 0.5}
          ]
        }
        ''');
      }), logger: mockLogger);
      
      final intent = await engine.parseIntent('remind me to buy milk at the store and buy milk', ['create_reminder']);
      expect(intent.entities.length, 3);
      expect(intent.entities[0].type, 'task');
      expect(intent.entities[2].type, 'location');
    });
  });
}

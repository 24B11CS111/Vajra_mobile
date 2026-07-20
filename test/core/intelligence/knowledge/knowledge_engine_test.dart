import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/knowledge/knowledge_engine.dart';

void main() {
  group('KnowledgeEngine', () {
    late KnowledgeEngine engine;

    setUp(() {
      engine = KnowledgeEngine();
    });

    test('searchKnowledge returns results', () async {
      final results = await engine.searchKnowledge('test query');
      expect(results, isNotEmpty);
      expect(results.length, 2);
    });

    test('answer synthesizes response', () async {
      final response = await engine.answer('test question');
      expect(response, contains('test question'));
      expect(engine.state.lastAnswer, response);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/ai/prompts/prompt_builder.dart';

void main() {
  group('PromptBuilder', () {
    test('buildSystemIdentity returns identity string', () {
      final identity = PromptBuilder.buildSystemIdentity();
      expect(identity, contains('VAJRA'));
    });

    test('buildConversationPrompt includes context', () {
      final context = {
        'currentTime': '10:00 AM',
        'currentScreen': 'home',
        'userMode': 'study'
      };
      final prompt = PromptBuilder.buildConversationPrompt(context);
      
      expect(prompt, contains('10:00 AM'));
      expect(prompt, contains('home'));
      expect(prompt, contains('study'));
    });

    test('buildKnowledgeSynthesisPrompt includes facts', () {
      final facts = ['Fact A', 'Fact B'];
      final prompt = PromptBuilder.buildKnowledgeSynthesisPrompt(facts);
      
      expect(prompt, contains('Fact A'));
      expect(prompt, contains('Fact B'));
    });
  });
}

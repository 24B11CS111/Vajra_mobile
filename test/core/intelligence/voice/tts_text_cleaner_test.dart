import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/voice/tts_text_cleaner.dart';

void main() {
  group('TtsTextCleaner Unit Tests', () {
    test('1. Cleans prompt spec example: headers and bullets to natural speech', () {
      const input = "### Today's plan\n\n- Study mathematics\n- Finish project";
      final result = TtsTextCleaner.clean(input);
      expect(result, "Today's plan. Study mathematics. Finish project.");
    });

    test('2. Strips Markdown bold, italics, and strikethrough', () {
      const input = 'This is **bold**, this is *italic*, and this is ~~struck~~.';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'This is bold, this is italic, and this is struck.');
    });

    test('3. Strips fenced code blocks completely', () {
      const input = 'Here is the solution:\n```python\nprint("hello world")\n```\nIt works.';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Here is the solution: It works.');
    });

    test('4. Preserves inline code text without backticks', () {
      const input = 'Run `flutter analyze` to check for errors.';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Run flutter analyze to check for errors.');
    });

    test('5. Strips Markdown links keeping link text', () {
      const input = 'Check out [VAJRA Documentation](https://example.com/docs) for details.';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Check out VAJRA Documentation for details.');
    });

    test('6. Strips images completely', () {
      const input = 'Here is the avatar: ![Avatar](https://example.com/avatar.png) Ready.';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Here is the avatar: Ready.');
    });

    test('7. Strips technical tool and action JSON payloads', () {
      const input = 'Execution finished. {"tool": "calendar", "action": "createEvent", "status": "ok"} The event is saved.';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Execution finished. The event is saved.');
    });

    test('8. Strips numbered lists and adds pauses', () {
      const input = "Steps:\n1. Open settings\n2. Grant permission\n3. Return to app";
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Steps: Open settings. Grant permission. Return to app.');
    });

    test('9. Strips HTML tags', () {
      const input = 'Welcome to <b>VAJRA</b> companion!';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Welcome to VAJRA companion!');
    });

    test('10. Handles empty and whitespace strings gracefully', () {
      expect(TtsTextCleaner.clean(''), '');
      expect(TtsTextCleaner.clean('   \n\t  '), '');
    });

    test('11. Removes blockquote markers', () {
      const input = '> Keep focus and achieve your goals today.';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Keep focus and achieve your goals today.');
    });

    test('12. Removes streaming cursor block artifact', () {
      const input = 'Thinking of what to say ▌';
      final result = TtsTextCleaner.clean(input);
      expect(result, 'Thinking of what to say');
    });
  });
}

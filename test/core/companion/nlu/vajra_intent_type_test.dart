import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/companion/nlu/models/vajra_intent_type.dart';
import 'package:vajra_mobile/core/companion/nlu/models/intent.dart';

void main() {
  group('VajraIntentType and Intent Models', () {
    test('fromString accurately maps strings to enum', () {
      expect(VajraIntentType.fromString('memory_save'), VajraIntentType.memorySave);
      expect(VajraIntentType.fromString('remember_this'), VajraIntentType.memorySave);
      expect(VajraIntentType.fromString('study_exam'), VajraIntentType.study);
      expect(VajraIntentType.fromString('planning'), VajraIntentType.planning);
      expect(VajraIntentType.fromString('reminder'), VajraIntentType.reminder);
      expect(VajraIntentType.fromString('profile_update'), VajraIntentType.profileUpdate);
    });

    test('Intent model provides typed VajraIntentType getter', () {
      const intent = Intent(name: 'task_create', confidence: 0.95);
      expect(intent.type, VajraIntentType.taskCreate);
    });
  });
}

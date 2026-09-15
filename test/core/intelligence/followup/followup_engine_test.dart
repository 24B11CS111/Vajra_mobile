import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/followup/followup_engine.dart';

void main() {
  group('FollowUpEngine', () {
    late FollowUpEngine engine;

    setUp(() {
      engine = FollowUpEngine();
    });

    test('detects conversational commitment', () {
      final candidate = engine.detectCommitment("I'll finish the assignment tonight");
      expect(candidate, isNotNull);
      expect(engine.state.candidates.length, 1);
      expect(candidate!.commitmentText, contains('finish the assignment'));
    });

    test('acknowledges and dismisses candidate', () {
      final candidate = engine.detectCommitment("I will review notes tomorrow")!;
      engine.acknowledge(candidate.id);
      expect(engine.state.candidates.first.isAcknowledged, isTrue);

      engine.dismiss(candidate.id);
      expect(engine.state.candidates.first.isDismissed, isTrue);
    });
  });
}

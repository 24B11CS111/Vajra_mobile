import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/proactivity/proactivity_engine.dart';

void main() {
  group('ProactivityEngine', () {
    late ProactivityEngine engine;

    setUp(() {
      engine = ProactivityEngine();
    });

    test('correctly identifies quiet hours', () {
      final nightTime = DateTime(2026, 8, 23, 23, 30);
      final dayTime = DateTime(2026, 8, 23, 14, 0);

      expect(engine.checkQuietHours(nightTime), isTrue);
      expect(engine.checkQuietHours(dayTime), isFalse);
    });

    test('generates morning and evening briefings', () {
      final morning = engine.generateMorningBriefing(pendingTasksCount: 4, upcomingExam: 'Physics Midterm');
      expect(morning.type, ProactivityType.briefing);
      expect(morning.message, contains('4 priorities'));

      final evening = engine.generateEveningBriefing(completedTasksCount: 3, remainingTasksCount: 1);
      expect(evening.type, ProactivityType.briefing);
      expect(evening.message, contains('finished 3 tasks'));
    });
  });
}

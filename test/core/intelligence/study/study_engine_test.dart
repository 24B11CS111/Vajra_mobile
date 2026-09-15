import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/study/study_engine.dart';

void main() {
  group('StudyEngine', () {
    late StudyEngine engine;

    setUp(() {
      engine = StudyEngine();
      engine.seedCurriculum([
        const StudyTopic(id: 'qm_1', title: 'Wave-Particle Duality', subject: 'Quantum Mechanics'),
        const StudyTopic(id: 'qm_2', title: 'Schrödinger Equation', subject: 'Quantum Mechanics'),
      ]);
    });

    test('advances teaching flow properly', () {
      expect(engine.state.currentPhase, TeachingPhase.assessLevel);
      engine.nextTeachingPhase();
      expect(engine.state.currentPhase, TeachingPhase.explain);
    });

    test('records assessment score and updates mastery', () {
      engine.recordAssessment(topicId: 'qm_1', score: 0.9);
      final topic = engine.state.topics.firstWhere((t) => t.id == 'qm_1');
      expect(topic.masteryScore, greaterThan(0.0));
      expect(topic.isWeakArea, isFalse);
    });
  });
}

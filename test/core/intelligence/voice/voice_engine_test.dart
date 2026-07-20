import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/voice/voice_engine.dart';

void main() {
  group('VoiceEngine', () {
    late VoiceEngine engine;

    setUp(() {
      engine = VoiceEngine();
    });

    test('startListening changes state to listening', () async {
      await engine.startListening();
      expect(engine.state.currentState, VoiceState.listening);
    });

    test('stopListening changes state to thinking', () async {
      await engine.startListening();
      await engine.stopListening();
      expect(engine.state.currentState, VoiceState.thinking);
    });

    test('speak changes state to speaking and back to idle', () async {
      final future = engine.speak('test');
      expect(engine.state.currentState, VoiceState.speaking);
      await future;
      expect(engine.state.currentState, VoiceState.idle);
    });

    test('interrupt changes state to interrupted', () {
      engine.interrupt();
      expect(engine.state.currentState, VoiceState.interrupted);
    });
  });
}

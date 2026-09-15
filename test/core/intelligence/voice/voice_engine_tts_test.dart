import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/integrations/device_permission_service.dart';
import 'package:vajra_mobile/core/intelligence/voice/voice_engine.dart';

class _MockPermissionService extends DevicePermissionService {
  @override
  Future<DevicePermissionState> checkStatus(DevicePermissionType type) async =>
      DevicePermissionState.granted;
}

class _MockVoiceService extends VoiceService {
  final StreamController<VoicePlatformEvent> _eventController =
      StreamController<VoicePlatformEvent>.broadcast();

  @override
  Stream<VoicePlatformEvent> get events => _eventController.stream;

  @override
  Future<VoiceAvailability> checkAvailability() async =>
      const VoiceAvailability(available: true, onDeviceAvailable: true);

  void dispose() {
    _eventController.close();
  }
}

class _MockTtsService extends TtsService {
  final StreamController<TtsPlatformEvent> _ttsEventController =
      StreamController<TtsPlatformEvent>.broadcast();
  int speakCount = 0;
  int stopCount = 0;
  String? lastSpokenText;
  bool shouldFailSpeak = false;

  @override
  Stream<TtsPlatformEvent> get events => _ttsEventController.stream;

  @override
  Future<TtsAvailability> initialize() async =>
      const TtsAvailability(available: true, isSpeaking: false);

  @override
  Future<TtsAvailability> checkAvailability() async =>
      const TtsAvailability(available: true, isSpeaking: false);

  @override
  Future<bool> speak(String text, {String? utteranceId}) async {
    if (shouldFailSpeak) return false;
    speakCount++;
    lastSpokenText = text;
    return true;
  }

  @override
  Future<bool> stop() async {
    stopCount++;
    return true;
  }

  @override
  Future<Map<String, dynamic>> testDiagnosticSpeak() async => {
    'success': true,
    'engine': 'mock_engine',
    'streamVolume': 15,
  };

  void emit(TtsPlatformEvent event) {
    _ttsEventController.add(event);
  }

  void dispose() {
    _ttsEventController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceEngine TTS Integration Tests', () {
    late _MockPermissionService permissionService;
    late _MockVoiceService voiceService;
    late _MockTtsService ttsService;
    late VoiceEngine engine;

    setUp(() {
      permissionService = _MockPermissionService();
      voiceService = _MockVoiceService();
      ttsService = _MockTtsService();
      engine = VoiceEngine(permissionService, voiceService, ttsService);
    });

    tearDown(() {
      engine.dispose();
      voiceService.dispose();
      ttsService.dispose();
    });

    test('1. speak() cleans Markdown and starts speaking state', () async {
      const input = "### Today's Schedule\n- Meeting with team\n- Study flutter";
      final future = engine.speak(input);

      expect(engine.state.status, VoiceState.speaking);
      expect(engine.state.isSpeaking, isTrue);
      await future;

      expect(ttsService.speakCount, 1);
      expect(ttsService.lastSpokenText, "Today's Schedule. Meeting with team. Study flutter.");
    });

    test('2. speak() filters code blocks before sending to TTS', () async {
      const input = "Here is the code: ```python\nprint('hello')\n``` Done.";
      await engine.speak(input);

      expect(ttsService.lastSpokenText, "Here is the code: Done.");
    });

    test('3. speak() with empty text returns false and does not enter speaking', () async {
      final success = await engine.speak('   ');
      expect(success, isFalse);
      expect(engine.state.status, VoiceState.idle);
      expect(ttsService.speakCount, 0);
    });

    test('4. repeated speak() halts prior speech and speaks new response without overlap', () async {
      await engine.speak('First response');
      expect(ttsService.speakCount, 1);
      expect(engine.state.isSpeaking, isTrue);

      await engine.speak('Second response');
      expect(ttsService.speakCount, 2);
      expect(ttsService.lastSpokenText, 'Second response');
      expect(engine.state.isSpeaking, isTrue);
    });

    test('5. TtsDoneEvent resets speaking state to idle', () async {
      await engine.speak('Hello');
      expect(engine.state.isSpeaking, isTrue);

      ttsService.emit(const TtsDoneEvent(utteranceId: '123'));
      await pumpEventQueue();

      expect(engine.state.status, VoiceState.idle);
      expect(engine.state.isIdle, isTrue);
    });

    test('6. stopSpeech() halts native speech and resets to idle', () async {
      await engine.speak('Long response speaking...');
      expect(engine.state.isSpeaking, isTrue);

      await engine.stopSpeech();
      expect(ttsService.stopCount, 1);
      expect(engine.state.status, VoiceState.idle);
      expect(engine.state.isSpeaking, isFalse);
    });

    test('7. interrupt() while speaking immediately stops speech and resets to idle', () async {
      await engine.speak('Speaking when interrupted');
      expect(engine.state.isSpeaking, isTrue);

      engine.interrupt();
      expect(engine.state.status, VoiceState.idle);
      expect(engine.state.isIdle, isTrue);
    });

    test('8. TTS error transitions state cleanly to error and recovers to idle', () async {
      ttsService.shouldFailSpeak = true;

      final success = await engine.speak('Failing speech');
      expect(success, isFalse);
      expect(engine.state.status, VoiceState.error);
      expect(engine.state.errorMessage, "Voice output isn't available right now.");

      // Verify clean automatic recovery to idle
      await Future.delayed(const Duration(milliseconds: 700));
      expect(engine.state.status, VoiceState.idle);
    });

    test('9. TtsErrorEvent transitions to idle without breaking engine', () async {
      await engine.speak('Will error on device');
      expect(engine.state.isSpeaking, isTrue);

      ttsService.emit(const TtsErrorEvent(
        utteranceId: '1',
        errorCode: 'engine_crash',
        message: 'Engine stopped',
      ));
      await pumpEventQueue();

      expect(engine.state.status, VoiceState.idle);
    });

    test('10. runTtsDiagnostic() invokes testDiagnosticSpeak', () async {
      final res = await engine.runTtsDiagnostic();
      expect(res['success'], isTrue);
      expect(res['engine'], 'mock_engine');
      expect(res['streamVolume'], 15);
    });
  });
}

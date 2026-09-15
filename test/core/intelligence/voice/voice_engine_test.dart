import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/integrations/device_permission_service.dart';
import 'package:vajra_mobile/core/intelligence/voice/voice_engine.dart';

class _MockPermissionService extends DevicePermissionService {
  DevicePermissionState mockState;
  bool requestCalled = false;

  _MockPermissionService({this.mockState = DevicePermissionState.granted});

  @override
  Future<DevicePermissionState> checkStatus(DevicePermissionType type) async => mockState;

  @override
  Future<DevicePermissionState> request(DevicePermissionType type) async {
    requestCalled = true;
    return mockState;
  }

  @override
  Future<bool> openSettings() async => true;
}

class _MockVoiceService extends VoiceService {
  final StreamController<VoicePlatformEvent> _eventController = StreamController<VoicePlatformEvent>.broadcast();
  bool isAvailableMock = true;
  bool isOnDeviceMock = true;
  bool startListeningCalled = false;
  bool stopListeningCalled = false;
  bool cancelListeningCalled = false;
  bool openSettingsCalled = false;

  _MockVoiceService();

  @override
  Stream<VoicePlatformEvent> get events => _eventController.stream;

  @override
  Future<VoiceAvailability> checkAvailability() async {
    return VoiceAvailability(available: isAvailableMock, onDeviceAvailable: isOnDeviceMock);
  }

  @override
  Future<bool> startListening({String? locale}) async {
    startListeningCalled = true;
    return true;
  }

  @override
  Future<bool> stopListening() async {
    stopListeningCalled = true;
    return true;
  }

  @override
  Future<bool> cancelListening() async {
    cancelListeningCalled = true;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalled = true;
    return true;
  }

  void emit(VoicePlatformEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}

class _MockTtsService extends TtsService {
  final StreamController<TtsPlatformEvent> _ttsEventController = StreamController<TtsPlatformEvent>.broadcast();
  bool speakCalled = false;
  bool stopCalled = false;
  String? lastSpokenText;

  @override
  Stream<TtsPlatformEvent> get events => _ttsEventController.stream;

  @override
  Future<TtsAvailability> initialize() async => const TtsAvailability(available: true, isSpeaking: false);

  @override
  Future<TtsAvailability> checkAvailability() async => const TtsAvailability(available: true, isSpeaking: false);

  @override
  Future<bool> speak(String text, {String? utteranceId}) async {
    speakCalled = true;
    lastSpokenText = text;
    return true;
  }

  @override
  Future<bool> stop() async {
    stopCalled = true;
    return true;
  }

  void emit(TtsPlatformEvent event) {
    _ttsEventController.add(event);
  }

  void dispose() {
    _ttsEventController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceEngine Unit Tests', () {
    late _MockPermissionService permissionService;
    late _MockVoiceService voiceService;
    late _MockTtsService ttsService;
    late VoiceEngine engine;

    setUp(() {
      permissionService = _MockPermissionService(mockState: DevicePermissionState.granted);
      voiceService = _MockVoiceService();
      ttsService = _MockTtsService();
      engine = VoiceEngine(permissionService, voiceService, ttsService);
    });

    tearDown(() {
      engine.dispose();
      voiceService.dispose();
      ttsService.dispose();
    });

    test('1. Initial state is idle', () {
      expect(engine.state.status, VoiceState.idle);
      expect(engine.state.isIdle, isTrue);
      expect(engine.state.partialTranscript, isEmpty);
      expect(engine.state.finalTranscript, isEmpty);
      expect(engine.state.errorMessage, isNull);
      expect(engine.state.isPermissionDenied, isFalse);
    });

    test('2. Permission flow: denied transitions to error with friendly message', () async {
      permissionService.mockState = DevicePermissionState.denied;

      await engine.startListening();

      expect(permissionService.requestCalled, isTrue);
      expect(engine.state.status, VoiceState.error);
      expect(engine.state.isPermissionDenied, isTrue);
      expect(engine.state.errorMessage, contains('Microphone permission denied'));
    });

    test('3. Permission flow: permanently denied flags isPermanentlyDenied', () async {
      permissionService.mockState = DevicePermissionState.permanentlyDenied;

      await engine.startListening();

      expect(engine.state.status, VoiceState.error);
      expect(engine.state.isPermanentlyDenied, isTrue);
    });

    test('4. Listening state: startListening with granted permission enters listening', () async {
      await engine.startListening();

      expect(engine.state.status, VoiceState.listening);
      expect(engine.state.isListening, isTrue);
      expect(voiceService.startListeningCalled, isTrue);
      expect(engine.state.isOnDevice, isTrue);
    });

    test('5. Stop listening transitions to processing', () async {
      await engine.startListening();
      await engine.stopListening();

      expect(engine.state.status, VoiceState.processing);
      expect(engine.state.isProcessing, isTrue);
      expect(voiceService.stopListeningCalled, isTrue);
    });

    test('6. Cancel listening resets to idle', () async {
      await engine.startListening();
      await engine.cancelListening();

      expect(engine.state.status, VoiceState.idle);
      expect(engine.state.isIdle, isTrue);
      expect(voiceService.cancelListeningCalled, isTrue);
    });

    test('7. Partial transcription updates state live', () async {
      await engine.startListening();

      voiceService.emit(const VoicePartialResultEvent('Schedule a meet'));
      await pumpEventQueue();

      expect(engine.state.partialTranscript, 'Schedule a meet');
      expect(engine.state.currentTranscript, 'Schedule a meet');
    });

    test('8. Final transcription sets finalTranscript and enters processing', () async {
      await engine.startListening();

      voiceService.emit(const VoiceFinalResultEvent('Schedule a meeting tomorrow at 4 PM'));
      await pumpEventQueue();

      expect(engine.state.finalTranscript, 'Schedule a meeting tomorrow at 4 PM');
      expect(engine.state.status, VoiceState.processing);
    });

    test('9. RMS audio soundLevel updates dynamically', () async {
      await engine.startListening();

      voiceService.emit(const VoiceRmsEvent(rms: 5.0, normalized: 0.75));
      await pumpEventQueue();

      expect(engine.state.soundLevel, 0.75);
    });

    test('10. Native error mapping: no_speech maps to friendly message', () async {
      await engine.startListening();

      voiceService.emit(const VoiceErrorEvent(
        errorCode: 'no_speech',
        rawCode: 7,
        message: 'No match',
      ));
      await pumpEventQueue();

      expect(engine.state.status, VoiceState.error);
      expect(engine.state.errorMessage, contains("I didn't hear anything"));
    });

    test('11. Recognizer unavailable sets error and flags isAvailable false', () async {
      voiceService.isAvailableMock = false;

      await engine.startListening();

      expect(engine.state.status, VoiceState.error);
      expect(engine.state.isAvailable, isFalse);
      expect(engine.state.errorMessage, contains('unavailable'));
    });

    test('12. Recovery from error to idle via reset()', () async {
      permissionService.mockState = DevicePermissionState.denied;
      await engine.startListening();
      expect(engine.state.status, VoiceState.error);

      engine.reset();
      expect(engine.state.status, VoiceState.idle);
      expect(engine.state.isIdle, isTrue);
    });

    test('13. Speaking state transitions cleanly to speaking and back to idle', () async {
      final future = engine.speak('Hello from VAJRA');
      expect(engine.state.status, VoiceState.speaking);
      expect(engine.state.isSpeaking, isTrue);
      await future;

      ttsService.emit(const TtsDoneEvent(utteranceId: 'utt_1'));
      await pumpEventQueue();

      expect(engine.state.status, VoiceState.idle);
      expect(engine.state.isIdle, isTrue);
      expect(ttsService.speakCalled, isTrue);
      expect(ttsService.lastSpokenText, 'Hello from VAJRA');
    });

    test('14. Open settings delegates to permission service', () async {
      final opened = await engine.openSettings();
      expect(opened, isTrue);
    });
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/intelligence/voice/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsService Platform Channel Tests', () {
    const MethodChannel methodChannel = MethodChannel('com.vajra.app/tts');
    late TtsService ttsService;
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        methodCalls.add(call);
        switch (call.method) {
          case 'initialize':
            return {
              'available': true,
              'initialized': true,
              'language': 'en_US',
            };
          case 'isAvailable':
            return {
              'available': true,
              'isSpeaking': false,
            };
          case 'speak':
            return true;
          case 'stop':
            return true;
          case 'setLanguage':
            return true;
          case 'testDiagnosticSpeak':
            return {
              'success': true,
              'utteranceId': 'diag_123',
              'engine': 'com.google.android.tts',
              'language': 'en_US',
              'streamVolume': 10,
              'maxVolume': 15,
            };
          default:
            return null;
        }
      });

      ttsService = TtsService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('1. initialize() invokes native initialize and returns availability', () async {
      final res = await ttsService.initialize();
      expect(res.available, isTrue);
      expect(res.language, 'en_US');
      expect(methodCalls.any((c) => c.method == 'initialize'), isTrue);
    });

    test('2. initialize() handles native error gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        throw PlatformException(code: 'INIT_ERROR', message: 'Engine failure');
      });

      final res = await ttsService.initialize();
      expect(res.available, isFalse);
    });

    test('3. checkAvailability() returns engine status', () async {
      final res = await ttsService.checkAvailability();
      expect(res.available, isTrue);
      expect(res.isSpeaking, isFalse);
      expect(methodCalls.any((c) => c.method == 'isAvailable'), isTrue);
    });

    test('4. speak() invokes platform method with text and utteranceId', () async {
      final success = await ttsService.speak('Hello from VAJRA', utteranceId: 'utt_1');
      expect(success, isTrue);
      final speakCall = methodCalls.firstWhere((c) => c.method == 'speak');
      expect(speakCall.arguments['text'], 'Hello from VAJRA');
      expect(speakCall.arguments['utteranceId'], 'utt_1');
    });

    test('5. speak() returns false immediately for empty or whitespace text', () async {
      final success1 = await ttsService.speak('');
      final success2 = await ttsService.speak('   ');
      expect(success1, isFalse);
      expect(success2, isFalse);
      expect(methodCalls.any((c) => c.method == 'speak'), isFalse);
    });

    test('6. stop() invokes platform stop', () async {
      final success = await ttsService.stop();
      expect(success, isTrue);
      expect(methodCalls.any((c) => c.method == 'stop'), isTrue);
    });

    test('7. setLanguage() invokes platform setLanguage', () async {
      final success = await ttsService.setLanguage('en_US');
      expect(success, isTrue);
      final call = methodCalls.firstWhere((c) => c.method == 'setLanguage');
      expect(call.arguments['language'], 'en_US');
    });

    test('8. testDiagnosticSpeak() invokes platform testDiagnosticSpeak and returns metadata', () async {
      final res = await ttsService.testDiagnosticSpeak();
      expect(res['success'], isTrue);
      expect(res['engine'], 'com.google.android.tts');
      expect(res['streamVolume'], 10);
      expect(methodCalls.any((c) => c.method == 'testDiagnosticSpeak'), isTrue);
    });
  });
}

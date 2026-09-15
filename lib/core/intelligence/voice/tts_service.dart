import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Container describing text-to-speech engine availability on the platform.
class TtsAvailability {
  final bool available;
  final bool isSpeaking;
  final String? language;

  const TtsAvailability({
    required this.available,
    this.isSpeaking = false,
    this.language,
  });

  factory TtsAvailability.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const TtsAvailability(available: false);
    }
    return TtsAvailability(
      available: map['available'] == true,
      isSpeaking: map['isSpeaking'] == true,
      language: map['language'] as String?,
    );
  }
}

/// Base class for events emitted from the Android TTS platform channel.
abstract class TtsPlatformEvent {
  const TtsPlatformEvent();
}

class TtsStartEvent extends TtsPlatformEvent {
  final String utteranceId;
  const TtsStartEvent({required this.utteranceId});
}

class TtsDoneEvent extends TtsPlatformEvent {
  final String utteranceId;
  const TtsDoneEvent({required this.utteranceId});
}

class TtsStopEvent extends TtsPlatformEvent {
  final String utteranceId;
  final bool interrupted;
  const TtsStopEvent({required this.utteranceId, this.interrupted = false});
}

class TtsErrorEvent extends TtsPlatformEvent {
  final String utteranceId;
  final String errorCode;
  final String message;
  const TtsErrorEvent({
    required this.utteranceId,
    required this.errorCode,
    required this.message,
  });
}

/// Service abstracting the Android native TextToSpeech platform channels.
class TtsService {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<TtsPlatformEvent>? _eventStream;

  TtsService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('com.vajra.app/tts'),
        _eventChannel = eventChannel ?? const EventChannel('com.vajra.app/tts/events');

  /// Stream of TTS playback events from the native platform.
  Stream<TtsPlatformEvent> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map<TtsPlatformEvent>((event) => _mapEvent(Map<String, dynamic>.from(event as Map)));
    return _eventStream!;
  }

  /// Initializes the Android native TextToSpeech engine.
  Future<TtsAvailability> initialize() async {
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('initialize');
      return TtsAvailability.fromMap(res);
    } catch (e) {
      debugPrint('TtsService.initialize error: $e');
      return const TtsAvailability(available: false);
    }
  }

  /// Checks if TTS engine is initialized and available.
  Future<TtsAvailability> checkAvailability() async {
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('isAvailable');
      return TtsAvailability.fromMap(res);
    } catch (e) {
      debugPrint('TtsService.checkAvailability error: $e');
      return const TtsAvailability(available: false);
    }
  }

  /// Synthesizes and speaks the given [text] aloud using the native engine.
  Future<bool> speak(String text, {String? utteranceId}) async {
    if (text.trim().isEmpty) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('speak', {
        'text': text,
        'utteranceId': ?utteranceId,
      });
      return res ?? false;
    } on PlatformException catch (pe) {
      debugPrint('TtsService.speak platform error: ${pe.code} - ${pe.message}');
      return false;
    } catch (e) {
      debugPrint('TtsService.speak error: $e');
      return false;
    }
  }

  /// Immediately halts any ongoing TTS speech playback.
  Future<bool> stop() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('stop');
      return res ?? false;
    } catch (e) {
      debugPrint('TtsService.stop error: $e');
      return false;
    }
  }

  /// Configures speech language locale (e.g. "en_US").
  Future<bool> setLanguage(String language) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('setLanguage', {
        'language': language,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('TtsService.setLanguage error: $e');
      return false;
    }
  }

  /// Performs an internal diagnostic speech test saying "VAJRA voice test successful."
  /// Isolates native TTS engine and audio output from the Dart conversation pipeline.
  Future<Map<String, dynamic>> testDiagnosticSpeak() async {
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('testDiagnosticSpeak');
      return Map<String, dynamic>.from(res ?? {});
    } catch (e) {
      debugPrint('[VAJRA_TTS] TtsService.testDiagnosticSpeak error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  TtsPlatformEvent _mapEvent(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? '';
    final utteranceId = map['utteranceId'] as String? ?? '';
    switch (type) {
      case 'start':
        return TtsStartEvent(utteranceId: utteranceId);
      case 'done':
        return TtsDoneEvent(utteranceId: utteranceId);
      case 'stop':
        return TtsStopEvent(
          utteranceId: utteranceId,
          interrupted: map['interrupted'] == true,
        );
      case 'error':
        return TtsErrorEvent(
          utteranceId: utteranceId,
          errorCode: map['errorCode'] as String? ?? 'tts_error',
          message: map['message'] as String? ?? 'TTS playback error',
        );
      default:
        return TtsStopEvent(utteranceId: utteranceId, interrupted: true);
    }
  }
}

/// Provider for TtsService.
final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

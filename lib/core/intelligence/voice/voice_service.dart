import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Container describing speech recognition availability on the platform.
class VoiceAvailability {
  final bool available;
  final bool onDeviceAvailable;

  const VoiceAvailability({
    required this.available,
    required this.onDeviceAvailable,
  });

  factory VoiceAvailability.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const VoiceAvailability(available: false, onDeviceAvailable: false);
    }
    return VoiceAvailability(
      available: map['available'] == true,
      onDeviceAvailable: map['onDeviceAvailable'] == true,
    );
  }
}

/// Base class for events emitted from the Android Voice platform channel.
abstract class VoicePlatformEvent {
  const VoicePlatformEvent();
}

class VoiceReadyEvent extends VoicePlatformEvent {
  final bool onDevice;
  const VoiceReadyEvent({this.onDevice = false});
}

class VoiceSpeechStartEvent extends VoicePlatformEvent {
  const VoiceSpeechStartEvent();
}

class VoiceRmsEvent extends VoicePlatformEvent {
  final double rms;
  final double normalized;
  const VoiceRmsEvent({required this.rms, required this.normalized});
}

class VoiceSpeechEndEvent extends VoicePlatformEvent {
  const VoiceSpeechEndEvent();
}

class VoicePartialResultEvent extends VoicePlatformEvent {
  final String text;
  const VoicePartialResultEvent(this.text);
}

class VoiceFinalResultEvent extends VoicePlatformEvent {
  final String text;
  const VoiceFinalResultEvent(this.text);
}

class VoiceErrorEvent extends VoicePlatformEvent {
  final String errorCode;
  final int rawCode;
  final String message;
  const VoiceErrorEvent({
    required this.errorCode,
    required this.rawCode,
    required this.message,
  });
}

class VoiceCancelledEvent extends VoicePlatformEvent {
  const VoiceCancelledEvent();
}

/// Service abstracting the Android native SpeechRecognizer platform channels.
class VoiceService {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<VoicePlatformEvent>? _eventStream;

  VoiceService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('com.vajra.app/voice'),
        _eventChannel = eventChannel ?? const EventChannel('com.vajra.app/voice/events');

  /// Stream of voice recognition events from the native platform.
  Stream<VoicePlatformEvent> get events {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map<VoicePlatformEvent>((event) => _mapEvent(Map<String, dynamic>.from(event as Map)));
    return _eventStream!;
  }

  /// Checks if speech recognition and on-device recognition are available.
  Future<VoiceAvailability> checkAvailability() async {
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('checkAvailability');
      return VoiceAvailability.fromMap(res);
    } catch (e) {
      debugPrint('VoiceService.checkAvailability error: $e');
      return const VoiceAvailability(available: false, onDeviceAvailable: false);
    }
  }

  /// Starts listening for speech using Android native SpeechRecognizer.
  Future<bool> startListening({String? locale}) async {
    try {
      final res = await _methodChannel.invokeMethod<dynamic>('startListening', {
        'locale': ?locale,
      });
      if (res is Map) {
        return res['started'] == true;
      }
      return res == true;
    } on PlatformException catch (pe) {
      debugPrint('VoiceService.startListening platform error: ${pe.code} - ${pe.message}');
      return false;
    } catch (e) {
      debugPrint('VoiceService.startListening error: $e');
      return false;
    }
  }

  /// Tells the speech recognizer to stop capturing and finalize speech.
  Future<bool> stopListening() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('stopListening');
      return res ?? false;
    } catch (e) {
      debugPrint('VoiceService.stopListening error: $e');
      return false;
    }
  }

  /// Cancels speech recognition immediately without producing a final result.
  Future<bool> cancelListening() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('cancelListening');
      return res ?? false;
    } catch (e) {
      debugPrint('VoiceService.cancelListening error: $e');
      return false;
    }
  }

  /// Opens the Android application settings page so the user can grant permission.
  Future<bool> openAppSettings() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('openAppSettings');
      return res ?? false;
    } catch (e) {
      debugPrint('VoiceService.openAppSettings error: $e');
      return false;
    }
  }

  VoicePlatformEvent _mapEvent(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? '';
    switch (type) {
      case 'ready':
        return VoiceReadyEvent(onDevice: map['onDevice'] == true);
      case 'speechStart':
        return const VoiceSpeechStartEvent();
      case 'rms':
        final rms = (map['rms'] as num?)?.toDouble() ?? 0.0;
        final norm = (map['normalized'] as num?)?.toDouble() ?? 0.0;
        return VoiceRmsEvent(rms: rms, normalized: norm);
      case 'speechEnd':
        return const VoiceSpeechEndEvent();
      case 'partialResult':
        return VoicePartialResultEvent(map['text'] as String? ?? '');
      case 'finalResult':
        return VoiceFinalResultEvent(map['text'] as String? ?? '');
      case 'error':
        return VoiceErrorEvent(
          errorCode: map['errorCode'] as String? ?? 'unknown_error',
          rawCode: (map['rawCode'] as num?)?.toInt() ?? -1,
          message: map['message'] as String? ?? 'Recognition failed.',
        );
      case 'cancelled':
        return const VoiceCancelledEvent();
      default:
        return const VoiceCancelledEvent();
    }
  }
}

/// Provider for VoiceService.
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

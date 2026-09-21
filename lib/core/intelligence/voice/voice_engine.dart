import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../integrations/device_permission_service.dart';
import 'tts_service.dart';
import 'tts_text_cleaner.dart';
import 'voice_service.dart';
import 'voice_state.dart';

export 'voice_state.dart';
export 'voice_service.dart';
export 'tts_service.dart';
export 'tts_text_cleaner.dart';

/// The VoiceEngine manages speech recognition lifecycle, permissions,
/// native event handling, text-to-speech output, and transitions between voice states.
class VoiceEngine extends StateNotifier<VoiceSessionState> {
  final DevicePermissionService _permissionService;
  final VoiceService _voiceService;
  final TtsService _ttsService;
  StreamSubscription<VoicePlatformEvent>? _eventSubscription;
  StreamSubscription<TtsPlatformEvent>? _ttsSubscription;

  Timer? _listeningTimeoutTimer;
  Timer? _processingTimeoutTimer;
  int _activeTtsGeneration = 0;

  VoiceEngine([
    DevicePermissionService? permissionService,
    VoiceService? voiceService,
    TtsService? ttsService,
  ])  : _permissionService = permissionService ?? DevicePermissionService(),
        _voiceService = voiceService ?? VoiceService(),
        _ttsService = ttsService ?? TtsService(),
        super(const VoiceSessionState()) {
    _subscribeToEvents();
    _subscribeToTtsEvents();
    _ttsService.initialize();
  }

  void _subscribeToEvents() {
    try {
      _eventSubscription = _voiceService.events.listen(
        _handlePlatformEvent,
        onError: (e) {
          debugPrint('VoiceEngine events stream error: $e');
          _cancelTimers();
          state = state.copyWith(
            status: VoiceState.error,
            errorMessage: 'Voice recognition connection error.',
          );
        },
      );
    } catch (e) {
      debugPrint('VoiceEngine subscription error: $e');
    }
  }

  void _handlePlatformEvent(VoicePlatformEvent event) {
    // Barge-in: if user starts speaking while TTS is speaking, stop speech immediately
    if (state.isSpeaking && (event is VoiceSpeechStartEvent || event is VoicePartialResultEvent)) {
      debugPrint('[VAJRA_VOICE] In-stream barge-in detected! Halting active TTS.');
      _ttsService.stop();
      state = state.copyWith(
        status: VoiceState.listening,
        bargeInCounter: state.bargeInCounter + 1,
        session: state.session?.copyWith(
          bargeInCount: (state.session?.bargeInCount ?? 0) + 1,
        ),
      );
    }

    if (event is VoiceReadyEvent) {
      state = state.copyWith(
        status: VoiceState.listening,
        isOnDevice: event.onDevice,
        errorMessage: null,
      );
    } else if (event is VoiceSpeechStartEvent) {
      state = state.copyWith(
        status: VoiceState.listening,
      );
    } else if (event is VoiceRmsEvent) {
      if (state.isListening) {
        state = state.copyWith(
          soundLevel: event.normalized,
        );
      }
    } else if (event is VoicePartialResultEvent) {
      if (state.isListening || state.isProcessing) {
        state = state.copyWith(
          partialTranscript: event.text,
        );
      }
    } else if (event is VoiceSpeechEndEvent) {
      state = state.copyWith(
        status: VoiceState.processing,
      );
      _startProcessingTimer();
    } else if (event is VoiceFinalResultEvent) {
      _cancelTimers();
      final text = event.text.trim();
      if (text.isNotEmpty) {
        state = state.copyWith(
          status: VoiceState.processing,
          finalTranscript: text,
          partialTranscript: text,
          soundLevel: 0.0,
        );
      } else {
        state = state.copyWith(
          status: VoiceState.idle,
          soundLevel: 0.0,
        );
      }
    } else if (event is VoiceErrorEvent) {
      _cancelTimers();
      final friendly = _formatErrorMessage(event.errorCode, event.message);
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: friendly,
        errorCode: event.errorCode,
        soundLevel: 0.0,
      );
    } else if (event is VoiceCancelledEvent) {
      _cancelTimers();
      state = const VoiceSessionState(status: VoiceState.idle);
    }
  }

  void _subscribeToTtsEvents() {
    try {
      _ttsSubscription = _ttsService.events.listen(
        _handleTtsEvent,
        onError: (e) {
          debugPrint('VoiceEngine TTS stream error: $e');
          if (state.isSpeaking) {
            state = state.copyWith(status: VoiceState.idle);
          }
        },
      );
    } catch (e) {
      debugPrint('VoiceEngine TTS subscription error: $e');
    }
  }

  void _handleTtsEvent(TtsPlatformEvent event) {
    if (event is TtsStartEvent) {
      state = state.copyWith(status: VoiceState.speaking);
    } else if (event is TtsDoneEvent) {
      if (state.isSpeaking) {
        state = state.copyWith(status: VoiceState.idle);
      }
    } else if (event is TtsStopEvent) {
      if (state.isSpeaking) {
        state = state.copyWith(status: VoiceState.idle);
      }
    } else if (event is TtsErrorEvent) {
      debugPrint('VoiceEngine TTS error: ${event.errorCode} - ${event.message}');
      state = state.copyWith(
        status: VoiceState.idle,
        errorMessage: null,
      );
    }
  }

  /// Starts listening for speech with contextual runtime permission check and barge-in capability.
  Future<void> startListening({String? locale}) async {
    try {
      _cancelTimers();

      // Barge-in: if currently speaking, abort speech immediately
      if (state.isSpeaking) {
        debugPrint('[VAJRA_VOICE] Barge-in activated via startListening: stopping active TTS.');
        await stopSpeech();
        state = state.copyWith(
          bargeInCounter: state.bargeInCounter + 1,
          session: state.session?.copyWith(
            bargeInCount: (state.session?.bargeInCount ?? 0) + 1,
          ),
        );
      }

      // 1. Contextual permission check
      final permStatus = await _permissionService.checkStatus(DevicePermissionType.microphone);
      if (permStatus != DevicePermissionState.granted) {
        state = state.copyWith(status: VoiceState.requestingPermission);
        final req = await _permissionService.request(DevicePermissionType.microphone);
        if (req != DevicePermissionState.granted) {
          state = state.copyWith(
            status: VoiceState.error,
            isPermissionDenied: true,
            isPermanentlyDenied: req == DevicePermissionState.permanentlyDenied,
            errorMessage: 'Microphone permission denied. Enable it in settings to talk to VAJRA.',
            errorCode: 'PERMISSION_DENIED',
          );
          return;
        }
      }

      // 2. Platform availability check
      final availability = await _voiceService.checkAvailability();
      if (!availability.available && !kIsWeb) {
        state = state.copyWith(
          status: VoiceState.error,
          isAvailable: false,
          errorMessage: 'Speech recognizer is unavailable on this device.',
          errorCode: 'RECOGNIZER_UNAVAILABLE',
        );
        return;
      }

      // 3. Update to listening state
      state = VoiceSessionState(
        status: VoiceState.listening,
        isOnDevice: availability.onDeviceAvailable,
        isAvailable: availability.available,
      );

      // Start safety timeout timer (15 seconds) so recognition never hangs
      _listeningTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (state.isListening) {
          debugPrint('VoiceEngine listening safety timeout triggered.');
          stopListening();
        }
      });

      final started = await _voiceService.startListening(locale: locale);
      if (!started) {
        debugPrint('VoiceEngine native startListening returned false or mock.');
      }
    } catch (e) {
      debugPrint('VoiceEngine startListening error: $e');
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: 'Unable to start speech recognition: $e',
      );
    }
  }

  /// Stops capturing speech and prepares to process the final recognized transcript.
  Future<void> stopListening() async {
    _cancelListeningTimer();
    state = state.copyWith(
      status: VoiceState.processing,
      soundLevel: 0.0,
    );
    _startProcessingTimer();

    try {
      await _voiceService.stopListening();
    } catch (e) {
      debugPrint('VoiceEngine stopListening error: $e');
    }
  }

  /// Cancels listening immediately without submitting or processing.
  Future<void> cancelListening() async {
    _cancelTimers();
    try {
      await _voiceService.cancelListening();
    } catch (e) {
      debugPrint('VoiceEngine cancelListening error: $e');
    }
    state = const VoiceSessionState(status: VoiceState.idle);
  }

  /// Clears active transcript and resets the voice state to idle.
  void reset() {
    _cancelTimers();
    state = const VoiceSessionState(status: VoiceState.idle);
  }

  /// Speaks the given response text using native Android Text-to-Speech.
  /// Prepares and sanitizes Markdown/code/technical formatting before speaking.
  Future<bool> speak(String text) async {
    final cleaned = TtsTextCleaner.clean(text);
    if (cleaned.isEmpty) {
      if (mounted && state.isSpeaking) {
        state = state.copyWith(status: VoiceState.idle);
      }
      return false;
    }

    state = state.copyWith(
      status: VoiceState.speaking,
      soundLevel: 0.0,
    );

    final gen = ++_activeTtsGeneration;
    try {
      debugPrint('[VAJRA_TTS] VoiceEngine.speak: invoking native TTS with ${cleaned.length} chars (gen: $gen)');
      final success = await _ttsService.speak(cleaned);
      if (_activeTtsGeneration != gen) return false;
      if (!success) {
        if (mounted) {
          state = state.copyWith(
            status: VoiceState.error,
            errorMessage: "Voice output isn't available right now.",
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && state.status == VoiceState.error) {
              state = state.copyWith(status: VoiceState.idle);
            }
          });
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('VoiceEngine speak error: $e');
      if (mounted) {
        state = state.copyWith(
          status: VoiceState.error,
          errorMessage: "Voice output isn't available right now.",
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && state.status == VoiceState.error) {
            state = state.copyWith(status: VoiceState.idle);
          }
        });
      }
      return false;
    }
  }

  /// Stops ongoing TTS playback immediately and resets state to idle.
  Future<void> stopSpeech() async {
    _activeTtsGeneration++;
    try {
      await _ttsService.stop();
    } catch (e) {
      debugPrint('VoiceEngine stopSpeech error: $e');
    }
    if (mounted && state.isSpeaking) {
      state = state.copyWith(status: VoiceState.idle);
    }
  }

  /// Interrupts ongoing speech or recognition immediately.
  /// If [toInterrupted] is true, sets status to [VoiceState.interrupted].
  /// Otherwise resets to idle for backward compatibility.
  void interrupt({bool toInterrupted = false}) {
    if (state.isSpeaking) {
      stopSpeech();
    }
    if (state.isListening || state.isProcessing) {
      cancelListening();
    }
    if (mounted) {
      state = state.copyWith(
        status: toInterrupted ? VoiceState.interrupted : VoiceState.idle,
        bargeInCounter: state.bargeInCounter + 1,
      );
    }
  }

  /// Triggers an explicit barge-in event, interrupting output and transitioning to interrupted state.
  void bargeIn() {
    interrupt(toInterrupted: true);
  }

  /// Resumes from interrupted state.
  void resume() {
    if (mounted) {
      state = state.copyWith(status: VoiceState.idle);
    }
  }

  /// Opens application settings so the user can grant microphone permissions.
  Future<bool> openSettings() async {
    return await _permissionService.openSettings();
  }

  /// Executes an internal native TTS diagnostic test ("VAJRA voice test successful.")
  /// and returns diagnostic metadata.
  Future<Map<String, dynamic>> runTtsDiagnostic() async {
    return await _ttsService.testDiagnosticSpeak();
  }

  void _startProcessingTimer() {
    _processingTimeoutTimer?.cancel();
    _processingTimeoutTimer = Timer(const Duration(seconds: 6), () {
      if (state.isProcessing) {
        debugPrint('VoiceEngine processing safety timeout triggered. Resetting to idle.');
        state = state.copyWith(
          status: VoiceState.idle,
          soundLevel: 0.0,
        );
      }
    });
  }

  void _cancelTimers() {
    _cancelListeningTimer();
    _processingTimeoutTimer?.cancel();
    _processingTimeoutTimer = null;
  }

  void _cancelListeningTimer() {
    _listeningTimeoutTimer?.cancel();
    _listeningTimeoutTimer = null;
  }

  String _formatErrorMessage(String code, String rawMessage) {
    switch (code) {
      case 'no_speech':
        return "I didn't hear anything. Tap the microphone when you're ready to speak.";
      case 'permission_denied':
        return 'Microphone permission is required to talk to VAJRA.';
      case 'network_error':
      case 'network_timeout':
        return 'Unable to reach speech recognition service. Please check your internet connection.';
      case 'recognizer_busy':
        return 'Speech recognizer is busy. Please try again in a moment.';
      case 'audio_error':
        return 'Microphone recording error. Please check your audio settings.';
      default:
        return rawMessage.isNotEmpty ? rawMessage : 'Speech recognition encountered an issue.';
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    _eventSubscription?.cancel();
    _ttsSubscription?.cancel();
    _ttsService.stop();
    super.dispose();
  }
}

/// Provider for the VoiceEngine.
final voiceEngineProvider = StateNotifierProvider<VoiceEngine, VoiceSessionState>((ref) {
  return VoiceEngine(
    ref.watch(devicePermissionServiceProvider),
    ref.watch(voiceServiceProvider),
    ref.watch(ttsServiceProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the various states of the Voice Engine.
enum VoiceState {
  idle,
  listening,
  thinking,
  speaking,
  interrupted,
}

/// Represents a voice session, including the current transcript.
class VoiceSessionState {
  final VoiceState currentState;
  final String currentTranscript;
  final String? error;

  const VoiceSessionState({
    this.currentState = VoiceState.idle,
    this.currentTranscript = '',
    this.error,
  });

  VoiceSessionState copyWith({
    VoiceState? currentState,
    String? currentTranscript,
    String? error,
  }) {
    return VoiceSessionState(
      currentState: currentState ?? this.currentState,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      error: error,
    );
  }
}

/// The VoiceEngine manages speech recognition, text-to-speech,
/// and the overall conversational state (listening, thinking, speaking).
class VoiceEngine extends StateNotifier<VoiceSessionState> {
  VoiceEngine() : super(const VoiceSessionState());

  /// Starts listening for user speech.
  Future<void> startListening() async {
    state = state.copyWith(
      currentState: VoiceState.listening,
      currentTranscript: '',
      error: null,
    );
    // Real implementation would interface with speech-to-text here
  }

  /// Stops listening and transitions to thinking/idle.
  Future<void> stopListening() async {
    state = state.copyWith(currentState: VoiceState.thinking);
    // Real implementation would stop STT and process transcript
  }

  /// Speaks the given text using text-to-speech.
  Future<void> speak(String text) async {
    state = state.copyWith(currentState: VoiceState.speaking);
    // Real implementation would send text to TTS engine
    await Future.delayed(const Duration(seconds: 2)); // Mock speaking duration
    state = state.copyWith(currentState: VoiceState.idle);
  }

  /// Interrupts current speech or listening.
  void interrupt() {
    state = state.copyWith(currentState: VoiceState.interrupted);
    // Real implementation would halt TTS immediately
  }

  /// Resumes from an interrupted state.
  void resume() {
    state = state.copyWith(currentState: VoiceState.idle);
  }
}

/// Provider for the VoiceEngine.
final voiceEngineProvider = StateNotifierProvider<VoiceEngine, VoiceSessionState>((ref) {
  return VoiceEngine();
});

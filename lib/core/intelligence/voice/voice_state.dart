/// Typed lifecycle status for the VAJRA Voice Engine.
enum VoiceState {
  idle,
  requestingPermission,
  listening,
  processing,
  speaking,
  error,
}

/// Alias for compatibility
typedef VoiceStatus = VoiceState;

/// Immutable state container representing the active VAJRA Voice session.
class VoiceSessionState {
  final VoiceState status;
  final String partialTranscript;
  final String finalTranscript;
  final double soundLevel; // 0.0 to 1.0 normalized RMS
  final String? errorMessage;
  final String? errorCode;
  final bool isPermissionDenied;
  final bool isPermanentlyDenied;
  final bool isOnDevice;
  final bool isAvailable;

  const VoiceSessionState({
    this.status = VoiceState.idle,
    this.partialTranscript = '',
    this.finalTranscript = '',
    this.soundLevel = 0.0,
    this.errorMessage,
    this.errorCode,
    this.isPermissionDenied = false,
    this.isPermanentlyDenied = false,
    this.isOnDevice = false,
    this.isAvailable = true,
  });

  bool get isIdle => status == VoiceState.idle;
  bool get isRequestingPermission => status == VoiceState.requestingPermission;
  bool get isListening => status == VoiceState.listening;
  bool get isProcessing => status == VoiceState.processing;
  bool get isSpeaking => status == VoiceState.speaking;
  bool get isError => status == VoiceState.error;

  // Backward compatibility getters
  VoiceState get currentState => status;
  String get currentTranscript => finalTranscript.isNotEmpty ? finalTranscript : partialTranscript;
  String? get error => errorMessage;

  VoiceSessionState copyWith({
    VoiceState? status,
    String? partialTranscript,
    String? finalTranscript,
    double? soundLevel,
    String? errorMessage,
    String? errorCode,
    bool? isPermissionDenied,
    bool? isPermanentlyDenied,
    bool? isOnDevice,
    bool? isAvailable,
    // Alias parameter for legacy tests
    VoiceState? currentState,
  }) {
    return VoiceSessionState(
      status: status ?? currentState ?? this.status,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      finalTranscript: finalTranscript ?? this.finalTranscript,
      soundLevel: soundLevel ?? this.soundLevel,
      errorMessage: errorMessage,
      errorCode: errorCode,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
      isOnDevice: isOnDevice ?? this.isOnDevice,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  String toString() {
    return 'VoiceSessionState(status: $status, partial: "$partialTranscript", final: "$finalTranscript", soundLevel: $soundLevel, error: $errorMessage)';
  }
}

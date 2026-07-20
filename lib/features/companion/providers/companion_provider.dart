import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/companion_repository.dart';
import '../models/stream_event.dart';
import '../models/avatar_state.dart';

class CompanionState {
  final List<String> messages; // Simplified for scaffolding; use proper ChatMessage model later
  final AvatarState avatarState;
  final String activeStreamText;

  CompanionState({
    this.messages = const [],
    this.avatarState = AvatarState.idle,
    this.activeStreamText = '',
  });

  CompanionState copyWith({
    List<String>? messages,
    AvatarState? avatarState,
    String? activeStreamText,
  }) {
    return CompanionState(
      messages: messages ?? this.messages,
      avatarState: avatarState ?? this.avatarState,
      activeStreamText: activeStreamText ?? this.activeStreamText,
    );
  }
}

final companionProvider = StateNotifierProvider<CompanionNotifier, CompanionState>((ref) {
  return CompanionNotifier(ref.watch(companionRepositoryProvider));
});

class CompanionNotifier extends StateNotifier<CompanionState> {
  final CompanionRepository _repository;
  final String _currentSessionId = "session_1";

  CompanionNotifier(this._repository) : super(CompanionState());

  void sendMessage(String text) async {
    // 1. Add user message
    final newMessages = List<String>.from(state.messages)..add("User: $text");
    state = state.copyWith(
      messages: newMessages,
      avatarState: AvatarState.thinking, // Immediate UI feedback
      activeStreamText: '',
    );

    try {
      // 2. Listen to SSE Stream
      await for (final event in _repository.processConversation(_currentSessionId, text)) {
        _handleStreamEvent(event);
      }
    } catch (e) {
      state = state.copyWith(avatarState: AvatarState.error);
    }
  }

  void _handleStreamEvent(BackendStreamEvent event) {
    switch (event.eventType) {
      case EventType.thinking:
        state = state.copyWith(avatarState: AvatarState.thinking);
        break;
      case EventType.toolStarted:
        final tool = event.payload['tool'] as String?;
        if (tool == 'planner' || tool == 'calendar') {
          state = state.copyWith(avatarState: AvatarState.planning);
        } else {
          state = state.copyWith(avatarState: AvatarState.searching);
        }
        break;
      case EventType.token:
        final token = event.payload['text'] as String? ?? '';
        state = state.copyWith(
          avatarState: AvatarState.speaking,
          activeStreamText: state.activeStreamText + token,
        );
        break;
      case EventType.complete:
        final finalMessages = List<String>.from(state.messages)..add("VAJRA: ${state.activeStreamText}");
        state = state.copyWith(
          messages: finalMessages,
          activeStreamText: '',
          avatarState: AvatarState.idle,
        );
        break;
      case EventType.error:
        state = state.copyWith(avatarState: AvatarState.error);
        break;
      default:
        break;
    }
  }
}

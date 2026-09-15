import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/intelligence/action/action_engine.dart';
import '../../../core/intelligence/action/vajra_command_router.dart';
import '../services/companion_repository.dart';
import '../models/stream_event.dart';
import '../models/avatar_state.dart';
import '../models/chat_message.dart';

class CompanionState {
  final List<ChatMessage> messages;
  final AvatarState avatarState;
  final String activeStreamText;
  final String sessionId;

  CompanionState({
    this.messages = const [],
    this.avatarState = AvatarState.idle,
    this.activeStreamText = '',
    required this.sessionId,
  });

  CompanionState copyWith({
    List<ChatMessage>? messages,
    AvatarState? avatarState,
    String? activeStreamText,
    String? sessionId,
  }) {
    return CompanionState(
      messages: messages ?? this.messages,
      avatarState: avatarState ?? this.avatarState,
      activeStreamText: activeStreamText ?? this.activeStreamText,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

final companionProvider = StateNotifierProvider<CompanionNotifier, CompanionState>((ref) {
  return CompanionNotifier(
    ref.watch(companionRepositoryProvider),
    ref.watch(actionEngineProvider.notifier),
  );
});

class CompanionNotifier extends StateNotifier<CompanionState> {
  final CompanionRepository _repository;
  final ActionEngine? _actionEngine;
  static const _uuid = Uuid();

  CompanionNotifier(this._repository, [this._actionEngine])
      : super(CompanionState(
          sessionId: _uuid.v4(),
          messages: [
            ChatMessage(
              id: _uuid.v4(),
              text: "Hello! I'm VAJRA, your personal AI companion. How can I assist your day?",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
        ));

  void startNewSession() {
    _repository.resetActiveConversation();
    state = state.copyWith(
      sessionId: _uuid.v4(),
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          text: "Hello! I'm VAJRA, your personal AI companion. How can I assist your day?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      activeStreamText: '',
      avatarState: AvatarState.idle,
    );
  }

  Future<String?> sendMessage(String text, {bool isVoice = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (state.avatarState == AvatarState.thinking || state.avatarState == AvatarState.speaking) {
      // Prevent duplicate sends during active streaming
      return null;
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      avatarState: AvatarState.thinking,
      activeStreamText: '',
    );

    // 1. Check for real action execution intents via Command Router
    final parsed = VajraCommandRouter.parse(trimmed);
    if (parsed.type != VajraIntentType.information && _actionEngine != null) {
      if (parsed.type == VajraIntentType.calendar ||
          parsed.type == VajraIntentType.planning ||
          parsed.type == VajraIntentType.task ||
          parsed.type == VajraIntentType.studySession) {
        state = state.copyWith(avatarState: AvatarState.planning);
      } else if (parsed.type == VajraIntentType.recallMemory) {
        state = state.copyWith(avatarState: AvatarState.searching);
      } else {
        state = state.copyWith(avatarState: AvatarState.thinking);
      }

      final result = await _actionEngine.executeParsedCommand(parsed);
      final String responseText = result.status == ActionStatus.offlinePending
          ? "I've saved that locally and will sync it when you're back online."
          : result.message;

      final actionMsg = ChatMessage(
        id: _uuid.v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, actionMsg],
        avatarState: AvatarState.idle,
        activeStreamText: '',
      );
      return responseText;
    }

    // 2. Fall back to streaming conversation
    try {
      await for (final event in _repository.processConversation(state.sessionId, trimmed)) {
        _handleStreamEvent(event);
      }
      final lastMsg = state.messages.isNotEmpty ? state.messages.last : null;
      if (lastMsg != null && !lastMsg.isUser) {
        return lastMsg.text;
      }
      return null;
    } catch (e) {
      final isOffline = e.toString().toLowerCase().contains("offline") ||
          e.toString().toLowerCase().contains("connection error") ||
          e.toString().toLowerCase().contains("socketexception");

      final replyText = isOffline
          ? "I am currently offline. I can still create tasks, schedule calendar events, set reminders, access your memory vault, and plan your day. Reconnect to the internet for full cloud features!"
          : "I ran into a temporary issue connecting to the VAJRA cloud. Your offline data and actions remain fully functional.";

      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        avatarState: AvatarState.idle,
        activeStreamText: '',
      );
      return replyText;
    } finally {
      if (state.avatarState == AvatarState.thinking || state.avatarState == AvatarState.speaking) {
        state = state.copyWith(avatarState: AvatarState.idle);
      }
    }
  }

  void retryLastMessage() {
    final lastUserMsg = state.messages.reversed.firstWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(id: '', text: '', isUser: true, timestamp: DateTime.now()),
    );
    if (lastUserMsg.text.isNotEmpty) {
      sendMessage(lastUserMsg.text);
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
        final completedText = state.activeStreamText.isNotEmpty
            ? state.activeStreamText
            : (event.payload['text'] as String? ?? '');
        
        final assistantMessage = ChatMessage(
          id: _uuid.v4(),
          text: completedText,
          isUser: false,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          activeStreamText: '',
          avatarState: AvatarState.idle,
        );
        break;
      case EventType.error:
        final errText = event.payload['error'] as String? ?? 'Unable to complete response.';
        final errorMsg = ChatMessage(
          id: _uuid.v4(),
          text: "I encountered an issue: $errText",
          isUser: false,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, errorMsg],
          avatarState: AvatarState.idle,
          activeStreamText: '',
        );
        break;
      default:
        break;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single message in the conversation.
class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Represents the state of the ConversationEngine.
class ConversationState {
  final List<Message> history;
  final String currentMessage;
  final bool isStreaming;
  final String? error;

  const ConversationState({
    this.history = const [],
    this.currentMessage = '',
    this.isStreaming = false,
    this.error,
  });

  ConversationState copyWith({
    List<Message>? history,
    String? currentMessage,
    bool? isStreaming,
    String? error,
  }) {
    return ConversationState(
      history: history ?? this.history,
      currentMessage: currentMessage ?? this.currentMessage,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
    );
  }
}

/// The ConversationEngine manages the lifecycle of a chat session,
/// including message history, pending responses, and streaming.
class ConversationEngine extends StateNotifier<ConversationState> {
  ConversationEngine() : super(const ConversationState());

  /// Starts a new conversation session.
  void startConversation() {
    state = const ConversationState();
  }

  /// Sends a message from the user to the companion.
  Future<void> sendMessage(String text) async {
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      history: [...state.history, userMessage],
      isStreaming: true,
      error: null,
    );

    // Trigger response generation (normally would stream from backend)
    await streamResponse('Processing: $text');
  }

  /// Streams a response back from the companion.
  Future<void> streamResponse(String text) async {
    // Mock streaming delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final companionMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      history: [...state.history, companionMessage],
      isStreaming: false,
    );
  }

  /// Cancels a pending or streaming response.
  void cancel() {
    state = state.copyWith(isStreaming: false);
  }

  /// Retries the last failed message.
  Future<void> retry() async {
    if (state.history.isEmpty) return;
    
    final lastMessage = state.history.last;
    if (lastMessage.isUser) {
      await sendMessage(lastMessage.text);
    }
  }

  /// Clears the current conversation history.
  void clearConversation() {
    state = const ConversationState();
  }

  /// Continues an existing conversation (e.g., loaded from disk).
  void continueConversation(List<Message> history) {
    state = state.copyWith(history: history);
  }
}

/// Provider for the ConversationEngine.
final conversationEngineProvider = StateNotifierProvider<ConversationEngine, ConversationState>((ref) {
  return ConversationEngine();
});

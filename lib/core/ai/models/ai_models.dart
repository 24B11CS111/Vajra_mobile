enum AiMessageRole { system, user, assistant, tool }

class AiMessage {
  final AiMessageRole role;
  final String content;
  final String? toolCallId;
  final String? name;

  const AiMessage({
    required this.role,
    required this.content,
    this.toolCallId,
    this.name,
  });
}

class AiRequest {
  final List<AiMessage> messages;
  final double temperature;
  final int? maxTokens;
  final List<dynamic>? tools;

  const AiRequest({
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens,
    this.tools,
  });
}

class AiResponse {
  final String content;
  final String? finishReason;
  final Map<String, dynamic>? toolCalls;
  final AiUsage? usage;
  final String? error;

  const AiResponse({
    required this.content,
    this.finishReason,
    this.toolCalls,
    this.usage,
    this.error,
  });
}

class AiUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const AiUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });
}

class AiConfig {
  final String providerName; // e.g., 'mock', 'openai', 'gemini'
  final String? apiKey; // Normally injected securely, never logged
  final String? endpoint;

  const AiConfig({
    required this.providerName,
    this.apiKey,
    this.endpoint,
  });
}

class AiError implements Exception {
  final String code;
  final String message;
  final bool isRetryable;

  const AiError({
    required this.code,
    required this.message,
    this.isRetryable = false,
  });

  @override
  String toString() => 'AiError($code): $message';
}

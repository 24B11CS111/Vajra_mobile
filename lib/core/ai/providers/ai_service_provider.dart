import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../interfaces/ai_provider.dart';
import '../models/ai_models.dart';
import '../adapters/mock_ai_adapter.dart';
import '../adapters/gemini_adapter.dart';
import '../adapters/openai_adapter.dart';
import '../adapters/claude_adapter.dart';
import '../adapters/ollama_adapter.dart';

/// Exposes the current AI configuration.
/// In a real app, this might be loaded from SharedPreferences or secure storage.
final aiConfigProvider = StateProvider<AiConfig>((ref) {
  return const AiConfig(providerName: 'mock');
});

/// The core AI provider instance that the Intelligence Core interacts with.
/// This acts as a factory, returning the appropriate adapter based on config.
final aiProvider = Provider<AiProvider>((ref) {
  final config = ref.watch(aiConfigProvider);

  switch (config.providerName.toLowerCase()) {
    case 'openai':
      return OpenAiAdapter(config);
    case 'gemini':
      return GeminiAdapter(config);
    case 'claude':
      return ClaudeAdapter(config);
    case 'ollama':
      return OllamaAdapter(config);
    case 'mock':
    default:
      return MockAiAdapter();
  }
});

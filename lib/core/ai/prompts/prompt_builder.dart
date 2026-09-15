/// Centralized builder for constructing system prompts.
class PromptBuilder {
  /// Base system prompt that establishes the AI's identity.
  static String buildSystemIdentity() {
    return 'You are VAJRA, an intelligent, concise, and helpful AI companion. '
           'You communicate naturally, with an elegant tone.';
  }

  /// Builds a prompt specifically for conversation, incorporating current context.
  static String buildConversationPrompt(Map<String, dynamic> context) {
    return '${buildSystemIdentity()}\n\n'
           'Current Context:\n'
           '- Time: ${context['currentTime']}\n'
           '- Screen: ${context['currentScreen']}\n'
           '- Mode: ${context['userMode']}\n\n'
           'Respond directly to the user.';
  }

  /// Builds a prompt for the planning engine.
  static String buildPlanningPrompt(String goal) {
    return 'You are a highly logical task planner. Break the following goal down '
           'into actionable, step-by-step tasks. Output as a JSON array of strings.\n\n'
           'Goal: $goal';
  }

  /// Builds a prompt for the memory engine.
  static String buildMemoryExtractionPrompt() {
    return 'Analyze the user input and extract any factual memories, preferences, '
           'or biographical data that should be stored long-term. Return a JSON array of strings.';
  }

  /// Builds a prompt for the knowledge engine.
  static String buildKnowledgeSynthesisPrompt(List<String> retrievedFacts) {
    return 'Synthesize an accurate answer based ONLY on the following facts. '
           'If the answer is not in the facts, say you do not know.\n\n'
           'Facts:\n${retrievedFacts.join('\n')}';
  }

  /// Builds a prompt for the decision engine.
  static String buildDecisionPrompt(Map<String, dynamic> context, List<String> availableActions) {
    return 'Evaluate the context and choose the most appropriate action from the list. '
           'Context: $context\n'
           'Actions: $availableActions\n'
           'Return only the chosen action ID.';
  }

  /// Builds a prompt for task extraction.
  static String buildTaskExtractionPrompt() {
    return 'Extract actionable tasks or reminders from the text. '
           'Return a JSON array of objects with "title" and "priority" (integer 0-10).';
  }
}

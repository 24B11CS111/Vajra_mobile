import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the current context of the user and application.
class ContextState {
  final DateTime currentTime;
  final String currentScreen;
  final String recentActivity;
  final bool isConnected;
  final double batteryLevel;
  final String userMode; // e.g., 'study', 'work', 'sleep', 'default'

  const ContextState({
    required this.currentTime,
    this.currentScreen = 'home',
    this.recentActivity = 'idle',
    this.isConnected = true,
    this.batteryLevel = 1.0,
    this.userMode = 'default',
  });

  ContextState copyWith({
    DateTime? currentTime,
    String? currentScreen,
    String? recentActivity,
    bool? isConnected,
    double? batteryLevel,
    String? userMode,
  }) {
    return ContextState(
      currentTime: currentTime ?? this.currentTime,
      currentScreen: currentScreen ?? this.currentScreen,
      recentActivity: recentActivity ?? this.recentActivity,
      isConnected: isConnected ?? this.isConnected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      userMode: userMode ?? this.userMode,
    );
  }
}

/// The ContextEngine is responsible for maintaining the situational context
/// of the user, such as current screen, activity, connectivity, and mode.
class ContextEngine extends StateNotifier<ContextState> {
  ContextEngine() : super(ContextState(currentTime: DateTime.now()));

  /// Captures a snapshot of the current context.
  ContextState capture() {
    return state;
  }

  /// Updates the context with new values.
  void update({
    String? currentScreen,
    String? recentActivity,
    bool? isConnected,
    double? batteryLevel,
    String? userMode,
  }) {
    state = state.copyWith(
      currentTime: DateTime.now(),
      currentScreen: currentScreen,
      recentActivity: recentActivity,
      isConnected: isConnected,
      batteryLevel: batteryLevel,
      userMode: userMode,
    );
  }

  /// Observes a specific stream of events and updates the context.
  void observe(Stream<Map<String, dynamic>> contextStream) {
    contextStream.listen((event) {
      update(
        currentScreen: event['currentScreen'] as String?,
        recentActivity: event['recentActivity'] as String?,
        isConnected: event['isConnected'] as bool?,
        batteryLevel: event['batteryLevel'] as double?,
        userMode: event['userMode'] as String?,
      );
    });
  }

  /// Calculates relevance score (0.0 to 1.0) of a text snippet against a query.
  double calculateRelevance(String text, String query) {
    if (query.trim().isEmpty || text.trim().isEmpty) return 0.0;
    final queryTokens = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
    if (queryTokens.isEmpty) return 0.1;
    final textLower = text.toLowerCase();
    int matchCount = 0;
    for (final token in queryTokens) {
      if (textLower.contains(token)) {
        matchCount++;
      }
    }
    return (matchCount / queryTokens.length).clamp(0.0, 1.0);
  }

  /// Assembles an aggregated, relevance-filtered contextual snapshot for the AI operating system.
  Map<String, dynamic> assembleContext({
    required String query,
    List<String> memories = const [],
    List<String> activeTasks = const [],
    List<String> notifications = const [],
    String? studyState,
  }) {
    final rankedMemories = memories
        .map((m) => MapEntry(m, calculateRelevance(m, query)))
        .where((entry) => entry.value > 0.1 || memories.length <= 3)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'screen': state.currentScreen,
      'user_mode': state.userMode,
      'connectivity': state.isConnected,
      'battery': state.batteryLevel,
      'relevant_memories': rankedMemories.take(5).map((e) => e.key).toList(),
      'active_tasks': activeTasks.take(5).toList(),
      'recent_notifications': notifications.take(3).toList(),
      'study_state': studyState ?? 'idle',
    };
  }
}

/// Provider for the ContextEngine.
final contextEngineProvider = StateNotifierProvider<ContextEngine, ContextState>((ref) {
  return ContextEngine();
});

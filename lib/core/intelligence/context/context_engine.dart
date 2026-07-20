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
}

/// Provider for the ContextEngine.
final contextEngineProvider = StateNotifierProvider<ContextEngine, ContextState>((ref) {
  return ContextEngine();
});

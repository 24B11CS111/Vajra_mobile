import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a system action to be executed.
class SystemAction {
  final String id;
  final String type; // e.g., 'notification', 'calendar', 'navigate', 'system'
  final Map<String, dynamic> payload;

  const SystemAction({
    required this.id,
    required this.type,
    required this.payload,
  });
}

/// Represents the state of the ActionEngine.
class ActionState {
  final List<SystemAction> actionHistory;
  final bool isExecuting;
  final String? lastError;

  const ActionState({
    this.actionHistory = const [],
    this.isExecuting = false,
    this.lastError,
  });

  ActionState copyWith({
    List<SystemAction>? actionHistory,
    bool? isExecuting,
    String? lastError,
  }) {
    return ActionState(
      actionHistory: actionHistory ?? this.actionHistory,
      isExecuting: isExecuting ?? this.isExecuting,
      lastError: lastError,
    );
  }
}

/// The ActionEngine acts as the execution layer, dispatching intents to
/// various system modules (notifications, calendar, navigation, plugins).
class ActionEngine extends StateNotifier<ActionState> {
  ActionEngine() : super(const ActionState());

  /// Executes a system action.
  Future<bool> execute(SystemAction action) async {
    state = state.copyWith(isExecuting: true);
    
    // Validate action first
    if (!validate(action)) {
      state = state.copyWith(isExecuting: false, lastError: 'Invalid action');
      return false;
    }

    // Mock execution delay
    await Future.delayed(const Duration(milliseconds: 200));

    state = state.copyWith(
      isExecuting: false,
      actionHistory: [...state.actionHistory, action],
      lastError: null,
    );
    return true;
  }

  /// Undoes the last executed action if possible.
  Future<bool> undo() async {
    if (state.actionHistory.isEmpty) return false;
    
    // Perform undo logic for the last action here
    
    state = state.copyWith(
      actionHistory: state.actionHistory.sublist(0, state.actionHistory.length - 1),
    );
    return true;
  }

  /// Previews the outcome of an action without executing it.
  String preview(SystemAction action) {
    return 'Preview for action ${action.id} of type ${action.type}';
  }

  /// Validates an action before execution.
  bool validate(SystemAction action) {
    if (action.id.isEmpty || action.type.isEmpty) return false;
    return true;
  }
}

/// Provider for the ActionEngine.
final actionEngineProvider = StateNotifierProvider<ActionEngine, ActionState>((ref) {
  return ActionEngine();
});

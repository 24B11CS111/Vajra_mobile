/// Safety tiers for the Universal Action Model.
enum ActionSafetyLevel {
  lowRisk,
  confirmationRequired,
  blocked,
}

/// The 11 canonical lifecycle states of any VAJRA action.
enum ActionLifecycleState {
  parsed,
  validating,
  ready,
  confirmationRequired,
  executing,
  success,
  failed,
  unsupported,
  notInstalled,
  permissionRequired,
  cancelled,
}

/// Universal action representation used throughout VAJRA Mobile.
class UniversalAction {
  final String actionType;
  final String target;
  final String? app;
  final Map<String, dynamic> parameters;
  final String requiredCapability;
  final ActionSafetyLevel safetyLevel;
  final bool confirmationRequired;
  final String executor;
  final bool acknowledgementRequired;
  final ActionLifecycleState state;
  final String? resultMessage;
  final String? errorCode;

  const UniversalAction({
    required this.actionType,
    this.target = 'phone',
    this.app,
    this.parameters = const {},
    this.requiredCapability = 'core',
    this.safetyLevel = ActionSafetyLevel.lowRisk,
    this.confirmationRequired = false,
    this.executor = 'native_android',
    this.acknowledgementRequired = false,
    this.state = ActionLifecycleState.parsed,
    this.resultMessage,
    this.errorCode,
  });

  UniversalAction copyWith({
    String? actionType,
    String? target,
    String? app,
    Map<String, dynamic>? parameters,
    String? requiredCapability,
    ActionSafetyLevel? safetyLevel,
    bool? confirmationRequired,
    String? executor,
    bool? acknowledgementRequired,
    ActionLifecycleState? state,
    String? resultMessage,
    String? errorCode,
  }) {
    return UniversalAction(
      actionType: actionType ?? this.actionType,
      target: target ?? this.target,
      app: app ?? this.app,
      parameters: parameters ?? this.parameters,
      requiredCapability: requiredCapability ?? this.requiredCapability,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      confirmationRequired: confirmationRequired ?? this.confirmationRequired,
      executor: executor ?? this.executor,
      acknowledgementRequired: acknowledgementRequired ?? this.acknowledgementRequired,
      state: state ?? this.state,
      resultMessage: resultMessage ?? this.resultMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  Map<String, dynamic> toMap() => {
    'action_type': actionType,
    'target': target,
    'app': app,
    'parameters': parameters,
    'required_capability': requiredCapability,
    'safety_level': safetyLevel.name,
    'confirmation_required': confirmationRequired,
    'executor': executor,
    'acknowledgement_required': acknowledgementRequired,
    'state': state.name,
    if (resultMessage != null) 'result_message': resultMessage,
    if (errorCode != null) 'error_code': errorCode,
  };
}

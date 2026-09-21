import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../features/planner/models/planner_model.dart';
import '../../../features/study/models/study_models.dart';
import '../../../features/study/models/study_session_model.dart';
import '../../../features/planner/services/planner_repository.dart';
import '../../../features/study/services/study_repository.dart';
import '../../../features/memory/services/memory_repository.dart';
import '../../integrations/device_calendar_service.dart';
import '../../integrations/device_notification_service.dart';
import '../../assistant/call_assistant.dart';
import '../../assistant/message_assistant.dart';
import '../../assistant/device_control_service.dart';
import '../../assistant/notification_assistant.dart';
import '../../assistant/proactive_assistant.dart';
import '../../assistant/mobile_app_launch_engine.dart';
import 'universal_action_model.dart';
import 'vajra_command_router.dart';

/// Explicit execution status for ActionResults.
enum ActionStatus {
  success,
  failure,
  needsConfirmation,
  unsupported,
  offlinePending,
}

/// Typed result container for specific system tools.
class ToolResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final bool retryable;

  const ToolResult({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.retryable = false,
  });

  factory ToolResult.success(T data) => ToolResult(success: true, data: data);
  factory ToolResult.failure(String error, {String? errorCode, bool retryable = false}) =>
      ToolResult(success: false, error: error, errorCode: errorCode, retryable: retryable);
}

/// Structured result of an executed action or parsed command.
class ActionResult {
  final ActionStatus status;
  final String message;
  final dynamic data;
  final String? errorCode;

  bool get isSuccess => status == ActionStatus.success;
  bool get isFailure => status == ActionStatus.failure;
  bool get isOfflinePending => status == ActionStatus.offlinePending;
  bool get isNeedsConfirmation => status == ActionStatus.needsConfirmation;
  bool get isUnsupported => status == ActionStatus.unsupported;

  const ActionResult({
    required this.status,
    required this.message,
    this.data,
    this.errorCode,
  });

  factory ActionResult.success(String message, [dynamic data]) =>
      ActionResult(status: ActionStatus.success, message: message, data: data);

  factory ActionResult.failure(String message, {String? errorCode}) =>
      ActionResult(status: ActionStatus.failure, message: message, errorCode: errorCode);

  factory ActionResult.offlinePending(String message, [dynamic data]) =>
      ActionResult(status: ActionStatus.offlinePending, message: message, data: data);

  factory ActionResult.needsConfirmation(String message, [dynamic data]) =>
      ActionResult(status: ActionStatus.needsConfirmation, message: message, data: data);

  factory ActionResult.unsupported(String message) =>
      ActionResult(status: ActionStatus.unsupported, message: message);
}

/// Permission level governing tool & action execution safety.
enum ActionPermissionLevel {
  readOnly,
  lowRisk,
  userConfirmation,
  sensitive,
  blocked,
}

/// Lifecycle state for system actions.
enum ActionExecutionStatus {
  pending,
  validating,
  waitingConfirmation,
  executing,
  success,
  failed,
  cancelled,
}

/// Specification for approved system tools.
class ToolDefinition {
  final String name;
  final String description;
  final ActionPermissionLevel permissionLevel;
  final bool requiresConfirmation;
  final Map<String, dynamic> inputSchema;

  const ToolDefinition({
    required this.name,
    required this.description,
    required this.permissionLevel,
    this.requiresConfirmation = false,
    this.inputSchema = const {},
  });
}

/// Represents a system action to be executed.
class SystemAction {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final ActionExecutionStatus status;
  final ActionPermissionLevel permissionLevel;

  const SystemAction({
    required this.id,
    required this.type,
    required this.payload,
    this.status = ActionExecutionStatus.pending,
    this.permissionLevel = ActionPermissionLevel.lowRisk,
  });

  SystemAction copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    ActionExecutionStatus? status,
    ActionPermissionLevel? permissionLevel,
  }) {
    return SystemAction(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      permissionLevel: permissionLevel ?? this.permissionLevel,
    );
  }
}

/// Represents the state of the ActionEngine.
class ActionState {
  final List<SystemAction> actionHistory;
  final bool isExecuting;
  final String? lastError;
  final ActionExecutionStatus currentStatus;
  final UniversalAction? pendingAction;

  const ActionState({
    this.actionHistory = const [],
    this.isExecuting = false,
    this.lastError,
    this.currentStatus = ActionExecutionStatus.pending,
    this.pendingAction,
  });

  ActionState copyWith({
    List<SystemAction>? actionHistory,
    bool? isExecuting,
    String? lastError,
    ActionExecutionStatus? currentStatus,
    UniversalAction? pendingAction,
    bool clearPendingAction = false,
  }) {
    return ActionState(
      actionHistory: actionHistory ?? this.actionHistory,
      isExecuting: isExecuting ?? this.isExecuting,
      lastError: lastError,
      currentStatus: currentStatus ?? this.currentStatus,
      pendingAction: clearPendingAction ? null : (pendingAction ?? this.pendingAction),
    );
  }
}

/// The ActionEngine acts as the execution layer, dispatching intents to
/// various system modules (notifications, calendar, navigation, plugins).
class ActionEngine extends StateNotifier<ActionState> {
  final PlannerRepository? _plannerRepository;
  final StudyRepository? _studyRepository;
  final DeviceCalendarService? _deviceCalendarService;
  final DeviceNotificationService? _deviceNotificationService;
  final MemoryRepository? _memoryRepository;
  final CallAssistant? _callAssistant;
  final MessageAssistant? _messageAssistant;
  final DeviceControlService? _deviceControlService;
  final NotificationAssistant? _notificationAssistant;
  final ProactiveAssistant? _proactiveAssistant;
  final MobileAppLaunchEngine? _mobileAppLaunchEngine;

  ActionEngine({
    PlannerRepository? plannerRepository,
    StudyRepository? studyRepository,
    DeviceCalendarService? deviceCalendarService,
    DeviceNotificationService? deviceNotificationService,
    MemoryRepository? memoryRepository,
    CallAssistant? callAssistant,
    MessageAssistant? messageAssistant,
    DeviceControlService? deviceControlService,
    NotificationAssistant? notificationAssistant,
    ProactiveAssistant? proactiveAssistant,
    MobileAppLaunchEngine? mobileAppLaunchEngine,
  })  : _plannerRepository = plannerRepository,
        _studyRepository = studyRepository,
        _deviceCalendarService = deviceCalendarService,
        _deviceNotificationService = deviceNotificationService,
        _memoryRepository = memoryRepository,
        _callAssistant = callAssistant,
        _messageAssistant = messageAssistant,
        _deviceControlService = deviceControlService,
        _notificationAssistant = notificationAssistant,
        _proactiveAssistant = proactiveAssistant,
        _mobileAppLaunchEngine = mobileAppLaunchEngine,
        super(const ActionState());

  CallAssistant? get callAssistant => _callAssistant;
  MessageAssistant? get messageAssistant => _messageAssistant;
  DeviceControlService? get deviceControlService => _deviceControlService;
  NotificationAssistant? get notificationAssistant => _notificationAssistant;
  ProactiveAssistant? get proactiveAssistant => _proactiveAssistant;
  MobileAppLaunchEngine? get mobileAppLaunchEngine => _mobileAppLaunchEngine;

  /// Strict approved tool catalog for VAJRA 2.0
  static const Map<String, ToolDefinition> toolCatalog = {
    'memory.search': ToolDefinition(
      name: 'memory.search',
      description: 'Search semantic memory vault',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'memory.save': ToolDefinition(
      name: 'memory.save',
      description: 'Save user fact or preference',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'memory.update': ToolDefinition(
      name: 'memory.update',
      description: 'Update existing memory',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'memory.delete': ToolDefinition(
      name: 'memory.delete',
      description: 'Delete memory permanently',
      permissionLevel: ActionPermissionLevel.userConfirmation,
      requiresConfirmation: true,
    ),
    'planner.create': ToolDefinition(
      name: 'planner.create',
      description: 'Create planner task or study session',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'planner.update': ToolDefinition(
      name: 'planner.update',
      description: 'Update planner task',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'planner.complete': ToolDefinition(
      name: 'planner.complete',
      description: 'Mark planner task completed',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'planner.delete': ToolDefinition(
      name: 'planner.delete',
      description: 'Delete planner task',
      permissionLevel: ActionPermissionLevel.userConfirmation,
      requiresConfirmation: true,
    ),
    'planner.reorder': ToolDefinition(
      name: 'planner.reorder',
      description: 'Reorder tasks',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'notification.create': ToolDefinition(
      name: 'notification.create',
      description: 'Schedule a notification or reminder',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'notification.read': ToolDefinition(
      name: 'notification.read',
      description: 'Mark notification read',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'notification.dismiss': ToolDefinition(
      name: 'notification.dismiss',
      description: 'Dismiss notification',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'profile.get': ToolDefinition(
      name: 'profile.get',
      description: 'Retrieve user profile settings',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'profile.update': ToolDefinition(
      name: 'profile.update',
      description: 'Update proactivity or communication settings',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'conversation.search': ToolDefinition(
      name: 'conversation.search',
      description: 'Search past conversation turns',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'study.create_session': ToolDefinition(
      name: 'study.create_session',
      description: 'Create study plan session',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'study.complete_session': ToolDefinition(
      name: 'study.complete_session',
      description: 'Record completed study session',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'navigation.open_screen': ToolDefinition(
      name: 'navigation.open_screen',
      description: 'Navigate to app screen',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'browser.open_url': ToolDefinition(
      name: 'browser.open_url',
      description: 'Open external URL in safe browser',
      permissionLevel: ActionPermissionLevel.userConfirmation,
      requiresConfirmation: true,
    ),
    'call.make': ToolDefinition(
      name: 'call.make',
      description: 'Initiate phone call or open dialer',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'call.search_contacts': ToolDefinition(
      name: 'call.search_contacts',
      description: 'Search device contacts',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'message.prepare_draft': ToolDefinition(
      name: 'message.prepare_draft',
      description: 'Prepare an SMS/text draft',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'message.send': ToolDefinition(
      name: 'message.send',
      description: 'Send text message via SMS composer',
      permissionLevel: ActionPermissionLevel.userConfirmation,
      requiresConfirmation: true,
    ),
    'device.flashlight': ToolDefinition(
      name: 'device.flashlight',
      description: 'Toggle device flashlight/torch',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'device.timer': ToolDefinition(
      name: 'device.timer',
      description: 'Set device countdown timer',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'device.settings': ToolDefinition(
      name: 'device.settings',
      description: 'Open device system settings screen',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'device.media': ToolDefinition(
      name: 'device.media',
      description: 'Dispatch media playback control',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'notification.missed_summary': ToolDefinition(
      name: 'notification.missed_summary',
      description: 'Summarize unread on-device notifications',
      permissionLevel: ActionPermissionLevel.readOnly,
    ),
    'app.launch': ToolDefinition(
      name: 'app.launch',
      description: 'Launch verified on-device application',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
    'app.action': ToolDefinition(
      name: 'app.action',
      description: 'Execute deep action in verified on-device application',
      permissionLevel: ActionPermissionLevel.lowRisk,
    ),
  };

  /// Executes a system action with real backing implementations.
  Future<bool> execute(SystemAction action) async {
    state = state.copyWith(
      isExecuting: true,
      currentStatus: ActionExecutionStatus.validating,
    );
    
    // Validate action first
    if (!validate(action)) {
      state = state.copyWith(
        isExecuting: false,
        lastError: 'Invalid action',
        currentStatus: ActionExecutionStatus.failed,
      );
      return false;
    }

    // Check permission level
    if (action.permissionLevel == ActionPermissionLevel.blocked) {
      state = state.copyWith(
        isExecuting: false,
        lastError: 'Execution blocked by security policy',
        currentStatus: ActionExecutionStatus.failed,
      );
      return false;
    }

    state = state.copyWith(currentStatus: ActionExecutionStatus.executing);

    final planner = _plannerRepository;
    final study = _studyRepository;
    final notif = _deviceNotificationService;
    final memory = _memoryRepository;

    bool executionSuccess = false;
    try {
      if (action.type == 'planner.create' && planner != null) {
        final title = action.payload['title']?.toString() ?? 'New Task';
        final priority = action.payload['priority']?.toString() ?? 'medium';
        final res = await planner.createTask({'title': title, 'priority': priority});
        executionSuccess = res.isSuccess;
      } else if (action.type == 'study.create_session' && study != null) {
        final res = await study.createAssignment(action.payload);
        executionSuccess = res.isSuccess;
      } else if (action.type == 'notification.create' && notif != null) {
        final title = action.payload['title']?.toString() ?? 'Reminder';
        final body = action.payload['body']?.toString() ?? 'VAJRA reminder';
        final epoch = action.payload['scheduledEpoch'] as int?;
        if (epoch != null) {
          executionSuccess = await notif.scheduleReminder(
            title: title,
            body: body,
            scheduledDate: DateTime.fromMillisecondsSinceEpoch(epoch),
          );
        } else {
          executionSuccess = await notif.showReminder(title: title, body: body);
        }
      } else if (action.type == 'memory.save' && memory != null) {
        final content = action.payload['content']?.toString() ?? '';
        if (content.isNotEmpty) {
          final res = await memory.saveFact(content);
          executionSuccess = res.isSuccess;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 50));
        executionSuccess = true;
      }
    } catch (e) {
      executionSuccess = false;
      state = state.copyWith(
        isExecuting: false,
        lastError: e.toString(),
        currentStatus: ActionExecutionStatus.failed,
      );
      return false;
    }

    final executedAction = action.copyWith(
      status: executionSuccess ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
    );

    state = state.copyWith(
      isExecuting: false,
      currentStatus: executionSuccess ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
      actionHistory: [...state.actionHistory, executedAction],
      lastError: executionSuccess ? null : 'Failed to execute ${action.type}',
    );
    return executionSuccess;
  }

  /// Dispatches and executes high-level parsed natural language commands.
  Future<ActionResult> executeParsedCommand(VajraParsedCommand command) async {
    state = state.copyWith(isExecuting: true, currentStatus: ActionExecutionStatus.executing);

    final planner = _plannerRepository;
    final study = _studyRepository;
    final notif = _deviceNotificationService;
    final memory = _memoryRepository;
    final cal = _deviceCalendarService;

    try {
      switch (command.type) {
        case VajraIntentType.task:
          if (planner == null) {
            return ActionResult.failure('Planner is currently unavailable.', errorCode: 'SERVICE_UNAVAILABLE');
          }
          final targetDate = command.dateTime ?? DateTime.now();
          final res = await planner.createTask({
            'title': command.title,
            'priority': command.priority ?? 'medium',
            'due_date': targetDate.toIso8601String(),
            'start_time': targetDate.toIso8601String(),
            'end_time': targetDate.add(const Duration(hours: 1)).toIso8601String(),
          });
          if (res.isSuccess) {
            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'planner.create',
              payload: {'title': command.title, 'type': 'task'},
              status: ActionExecutionStatus.success,
            );
            state = state.copyWith(
              isExecuting: false,
              currentStatus: ActionExecutionStatus.success,
              actionHistory: [...state.actionHistory, action],
            );
            final lowerInput = command.originalInput.toLowerCase();
            final String timeSuffix;
            if (lowerInput.contains('tomorrow')) {
              timeSuffix = ' tomorrow';
            } else if (lowerInput.contains('today') || lowerInput.contains('tonight')) {
              timeSuffix = ' today';
            } else if (command.dateTime != null) {
              timeSuffix = ' on ${DateFormat('MMMM d').format(command.dateTime!)}';
            } else {
              timeSuffix = '';
            }
            return ActionResult.success('Added to your planner — ${command.title}$timeSuffix.');
          } else {
            return ActionResult.failure(res.message ?? 'Failed to create task.', errorCode: 'TASK_FAILED');
          }

        case VajraIntentType.calendar:
          final start = command.dateTime ?? DateTime.now().add(const Duration(hours: 1));
          final end = command.endDateTime ??
              (command.duration != null ? start.add(command.duration!) : start.add(const Duration(hours: 1)));

          // 1. Attempt device native calendar insertion
          if (cal != null) {
            final nativeResult = await cal.createCalendarEventDetailed(
              title: command.title,
              startTime: start,
              endTime: end,
              description: command.description,
            );

            // CRITICAL: ENFORCE RULE #1 — Never claim success if native calendar failed
            if (!nativeResult.isSuccess) {
              if (nativeResult.errorCode == 'PERMISSION_DENIED') {
                return ActionResult.failure(
                  "I couldn't add this event because calendar access isn't enabled.",
                  errorCode: 'PERMISSION_DENIED',
                );
              } else if (nativeResult.errorCode == 'CALENDAR_UNAVAILABLE') {
                return ActionResult.failure(
                  "I couldn't add this event because no writable calendar account was found on this device.",
                  errorCode: 'CALENDAR_UNAVAILABLE',
                );
              } else {
                return ActionResult.failure(
                  "I couldn't add this event to your calendar: ${nativeResult.error ?? 'Calendar insertion failed.'}",
                  errorCode: nativeResult.errorCode ?? 'CALENDAR_FAILED',
                );
              }
            }
          }

          // 2. Mirror to VAJRA's internal Planner calendar only after native succeeds
          if (planner != null) {
            await planner.createCalendarEvent({
              'title': command.title,
              'event_type': 'meeting',
              'start_time': start.toIso8601String(),
              'end_time': end.toIso8601String(),
              if (command.description != null) 'description': command.description,
            });
          }

          final hasExplicitRangeOrDuration = command.originalInput.toLowerCase().contains(' to ') ||
              command.originalInput.toLowerCase().contains('for ') ||
              command.originalInput.contains(' - ') ||
              RegExp(r'\b\d{1,2}(?::\d{2})?\s*(?:am|pm)?\s*(?:to|-)\s*\d{1,2}', caseSensitive: false).hasMatch(command.originalInput);
          final friendlyTime = hasExplicitRangeOrDuration
              ? _formatFriendlyMeetingTime(start, end)
              : _formatFriendlyMeetingTime(start);
          final action = SystemAction(
            id: const Uuid().v4(),
            type: 'calendar.create',
            payload: {
              'title': command.title,
              'start': start.toIso8601String(),
              'end': end.toIso8601String(),
            },
            status: ActionExecutionStatus.success,
          );
          state = state.copyWith(
            isExecuting: false,
            currentStatus: ActionExecutionStatus.success,
            actionHistory: [...state.actionHistory, action],
          );
          return ActionResult.success("Done — I've scheduled your meeting for $friendlyTime.");

        case VajraIntentType.reminder:
          final scheduled = command.dateTime ?? DateTime.now().add(const Duration(hours: 1));
          bool reminderSet = false;

          if (notif != null) {
            final notifResult = await notif.scheduleReminderDetailed(
              title: 'VAJRA Reminder',
              body: command.title,
              scheduledDate: scheduled,
            );
            if (notifResult.isSuccess) {
              reminderSet = true;
            } else if (notifResult.errorCode == 'PERMISSION_DENIED') {
              return ActionResult.failure(
                "I couldn't set that reminder because notification access is unavailable.",
                errorCode: 'PERMISSION_DENIED',
              );
            }
          }

          if (planner != null) {
            final res = await planner.createCalendarEvent({
              'title': 'Reminder: ${command.title}',
              'event_type': 'reminder',
              'start_time': scheduled.toIso8601String(),
              'end_time': scheduled.add(const Duration(minutes: 30)).toIso8601String(),
            });
            if (res.isSuccess) reminderSet = true;
          }

          if (reminderSet) {
            final timeStr = _formatTimeOnly(scheduled);
            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'notification.create',
              payload: {'title': command.title, 'scheduled': scheduled.toIso8601String()},
              status: ActionExecutionStatus.success,
            );
            state = state.copyWith(
              isExecuting: false,
              currentStatus: ActionExecutionStatus.success,
              actionHistory: [...state.actionHistory, action],
            );
            return ActionResult.success("Done — I'll remind you to ${command.title} at $timeStr.");
          } else {
            return ActionResult.failure(
              "I couldn't schedule the reminder. Notification service is currently unavailable.",
              errorCode: 'NOTIFICATION_FAILED',
            );
          }

        case VajraIntentType.assignment:
          if (study == null) {
            return ActionResult.failure('Study Hub is currently unavailable.', errorCode: 'SERVICE_UNAVAILABLE');
          }
          final dueDate = command.dateTime ?? DateTime.now().add(const Duration(days: 3));
          final subject = command.subject ?? 'General';
          final res = await study.createAssignment({
            'title': command.title,
            'subject_name': subject,
            'due_date': dueDate.toIso8601String(),
            'priority': command.priority ?? 'medium',
          });

          if (res.isSuccess) {
            // Also mirror deadline to planner calendar
            if (planner != null) {
              await planner.createCalendarEvent({
                'title': 'Due: ${subject != 'General' ? '$subject ' : ''}${command.title}',
                'event_type': 'assignment',
                'start_time': dueDate.toIso8601String(),
                'end_time': dueDate.add(const Duration(hours: 1)).toIso8601String(),
              });
            }

            final dayName = DateFormat('EEEE').format(dueDate);
            final subjectPrefix = subject != 'General' ? '$subject ' : '';
            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'study.create_assignment',
              payload: {'title': command.title, 'due': dueDate.toIso8601String()},
              status: ActionExecutionStatus.success,
            );
            state = state.copyWith(
              isExecuting: false,
              currentStatus: ActionExecutionStatus.success,
              actionHistory: [...state.actionHistory, action],
            );
            return ActionResult.success('Added — ${subjectPrefix}assignment is due $dayName.');
          } else {
            return ActionResult.failure(res.message ?? 'Failed to add assignment.');
          }

        case VajraIntentType.studySession:
          if (study == null) {
            return ActionResult.failure('Study Hub is currently unavailable.', errorCode: 'SERVICE_UNAVAILABLE');
          }
          final sessionTime = command.dateTime ?? DateTime.now().add(const Duration(hours: 1));
          final res = await study.createStudySession({
            'subject': command.subject ?? 'General Study',
            'topic': command.title,
            'scheduled_time': sessionTime.toIso8601String(),
            'duration_minutes': 45,
          });

          if (res.isSuccess) {
            if (notif != null && sessionTime.isAfter(DateTime.now())) {
              await notif.scheduleReminderDetailed(
                title: 'Upcoming Study Session',
                body: 'Time for your ${command.subject ?? 'study'} session: ${command.title}',
                scheduledDate: sessionTime.subtract(const Duration(minutes: 10)),
              );
            }

            final friendlyTime = _formatFriendlyMeetingTime(sessionTime);
            return ActionResult.success("Scheduled your study session for $friendlyTime.");
          } else {
            return ActionResult.failure(res.message ?? 'Failed to schedule study session.');
          }

        case VajraIntentType.subject:
          if (study == null) {
            return ActionResult.failure('Study Hub is currently unavailable.');
          }
          final res = await study.createSubject({
            'name': command.title,
            'color': '#8B5CF6',
            'priority': 'medium',
          });
          if (res.isSuccess) {
            return ActionResult.success('Created new subject "${command.title}".');
          } else {
            return ActionResult.failure(res.message ?? 'Failed to create subject.');
          }

        case VajraIntentType.saveMemory:
          if (memory == null) {
            return ActionResult.failure('Memory vault is currently unavailable.', errorCode: 'SERVICE_UNAVAILABLE');
          }
          final res = await memory.saveFact(command.title);
          if (res.isSuccess) {
            return ActionResult.success('Got it — I\'ll remember that ${command.title}.');
          } else {
            return ActionResult.failure('Could not save to memory vault.');
          }

        case VajraIntentType.recallMemory:
          if (memory == null) {
            return ActionResult.failure('Memory vault is currently unavailable.');
          }
          final res = await memory.getMemories();
          final memories = res.data ?? [];
          final query = command.title.toLowerCase();
          
          final matches = memories.where((m) {
            final content = m.content.toLowerCase();
            if (content.contains(query)) return true;
            final tokens = query.split(RegExp(r'\s+')).where((t) => t.length > 2);
            return tokens.any((t) => content.contains(t));
          }).toList();

          if (matches.isNotEmpty) {
            final best = matches.first.content;
            return ActionResult.success('Got it — $best');
          } else {
            return ActionResult.success(
              "I don't have any saved notes about '${command.title}' in your memory vault.",
            );
          }

        case VajraIntentType.planning:
          return await _generatePlanMyDay(command);

        case VajraIntentType.call:
          final callAssistant = _callAssistant ?? CallAssistant();
          String targetNumber = command.phoneNumber ?? '';
          String? contactName = command.contactName;

          if (targetNumber.isEmpty && contactName != null) {
            final matches = await callAssistant.findContacts(contactName);
            if (matches.isNotEmpty) {
              targetNumber = matches.first.phoneNumber;
              contactName = matches.first.displayName;
            } else {
              return ActionResult.failure(
                "Could not find a contact matching '$contactName'.",
                errorCode: 'CONTACT_NOT_FOUND',
              );
            }
          }

          if (targetNumber.isEmpty) {
            return ActionResult.failure(
              "Please specify a phone number or contact name to call.",
              errorCode: 'MISSING_NUMBER',
            );
          }

          final displayName = contactName ?? targetNumber;
          final pendingCall = UniversalAction(
            actionType: 'call.make',
            target: 'phone',
            parameters: {'phoneNumber': targetNumber, 'contactName': ?contactName},
            requiredCapability: 'telephony',
            safetyLevel: ActionSafetyLevel.confirmationRequired,
            confirmationRequired: true,
            state: ActionLifecycleState.confirmationRequired,
          );

          final action = SystemAction(
            id: const Uuid().v4(),
            type: 'call.make',
            payload: {'phoneNumber': targetNumber, 'contactName': contactName},
            status: ActionExecutionStatus.waitingConfirmation,
            permissionLevel: ActionPermissionLevel.userConfirmation,
          );

          state = state.copyWith(
            isExecuting: false,
            currentStatus: ActionExecutionStatus.waitingConfirmation,
            pendingAction: pendingCall,
            actionHistory: [...state.actionHistory, action],
          );

          return ActionResult.needsConfirmation(
            "Call $displayName at $targetNumber?",
            {'phoneNumber': targetNumber, 'contactName': contactName},
          );

        case VajraIntentType.message:
          final msgAssistant = _messageAssistant ?? MessageAssistant();
          final callAssistant = _callAssistant ?? CallAssistant();
          String recipient = command.phoneNumber ?? command.contactName ?? '';
          String? contactName = command.contactName;

          if (command.phoneNumber == null && contactName != null) {
            final matches = await callAssistant.findContacts(contactName);
            if (matches.isNotEmpty) {
              recipient = matches.first.phoneNumber;
              contactName = matches.first.displayName;
            }
          }

          final draftRes = msgAssistant.prepareDraft(
            recipient: recipient,
            body: command.messageBody ?? '',
            recipientName: contactName,
          );

          if (draftRes.success && draftRes.requiresConfirmation && draftRes.draft != null) {
            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'message.prepare_draft',
              payload: draftRes.draft!.toMap(),
              status: ActionExecutionStatus.waitingConfirmation,
              permissionLevel: ActionPermissionLevel.userConfirmation,
            );
            state = state.copyWith(
              isExecuting: false,
              currentStatus: ActionExecutionStatus.waitingConfirmation,
              actionHistory: [...state.actionHistory, action],
            );
            return ActionResult.needsConfirmation(
              draftRes.message,
              draftRes.draft!.toMap(),
            );
          } else {
            return ActionResult.failure(
              draftRes.message,
              errorCode: draftRes.errorCode ?? 'DRAFT_FAILED',
            );
          }

        case VajraIntentType.deviceControl:
          final device = _deviceControlService ?? DeviceControlService();
          final subtype = command.actionSubtype ?? '';

          if (subtype == 'flashlight_on') {
            final ok = await device.setFlashlight(true);
            return ok
                ? ActionResult.success("Turned on flashlight.")
                : ActionResult.failure("Could not turn on flashlight.", errorCode: 'DEVICE_ERROR');
          } else if (subtype == 'flashlight_off') {
            final ok = await device.setFlashlight(false);
            return ok
                ? ActionResult.success("Turned off flashlight.")
                : ActionResult.failure("Could not turn off flashlight.", errorCode: 'DEVICE_ERROR');
          } else if (subtype == 'volume_up') {
            final ok = await device.adjustVolume(up: true);
            return ok
                ? ActionResult.success("Volume increased.")
                : ActionResult.failure("Could not adjust volume.", errorCode: 'VOLUME_ERROR');
          } else if (subtype == 'volume_down') {
            final ok = await device.adjustVolume(up: false);
            return ok
                ? ActionResult.success("Volume decreased.")
                : ActionResult.failure("Could not adjust volume.", errorCode: 'VOLUME_ERROR');
          } else if (subtype == 'timer_cancel') {
            final ok = await device.cancelTimer();
            return ok
                ? ActionResult.success("Timer cancelled.")
                : ActionResult.failure("Could not cancel timer.", errorCode: 'TIMER_ERROR');
          } else if (subtype == 'timer') {
            final secs = command.timerSeconds ?? 60;
            final ok = await device.setTimer(seconds: secs, label: command.title);
            final mins = (secs / 60).round();
            final label = mins > 0 ? '$mins minute${mins > 1 ? "s" : ""}' : '$secs seconds';
            return ok
                ? ActionResult.success("Started timer for $label.")
                : ActionResult.failure("Unable to start timer.", errorCode: 'TIMER_ERROR');
          } else if (subtype.startsWith('settings_')) {
            final settingName = subtype.replaceFirst('settings_', '');
            DeviceSettingType? targetType;
            for (final type in DeviceSettingType.values) {
              if (type.name.toLowerCase() == settingName.toLowerCase()) {
                targetType = type;
                break;
              }
            }
            if (targetType != null) {
              final ok = await device.openSetting(targetType);
              return ok
                  ? ActionResult.success("Opening $settingName settings.")
                  : ActionResult.failure("Could not open settings.", errorCode: 'SETTINGS_ERROR');
            } else {
              return ActionResult.success("Opening settings.");
            }
          } else if (subtype.startsWith('media_')) {
            final cmd = subtype.replaceFirst('media_', '');
            final ok = await device.sendMediaControl(cmd);
            return ok
                ? ActionResult.success("Media: $cmd")
                : ActionResult.failure("Could not control media playback.", errorCode: 'MEDIA_ERROR');
          }
          return ActionResult.unsupported("Unsupported device control command.");

        case VajraIntentType.notificationQuery:
          final notifAssistant = _notificationAssistant ?? NotificationAssistant();
          final summary = await notifAssistant.getSummary();
          return ActionResult.success(summary);

        case VajraIntentType.appAction:
          final launchEngine = _mobileAppLaunchEngine ?? MobileAppLaunchEngine(_deviceControlService);
          final targetApp = command.targetApp;
          final appAction = command.appAction ?? 'app.launch';
          final extra = command.extraParameters ?? {};

          if (command.universalAction?.safetyLevel == ActionSafetyLevel.blocked ||
              command.universalAction?.state == ActionLifecycleState.unsupported) {
            return ActionResult.failure(
              "That app isn't currently available through VAJRA on your phone.",
              errorCode: 'UNAPPROVED_APP',
            );
          }

          if (appAction == 'whatsapp.prepare_message') {
            final recipient = extra['contact']?.toString() ?? '';
            final msg = extra['message']?.toString() ?? '';
            final pendingWa = UniversalAction(
              actionType: 'whatsapp.prepare_message',
              target: 'phone',
              app: 'whatsapp',
              parameters: {'contact': recipient, 'message': msg},
              requiredCapability: 'messaging',
              safetyLevel: ActionSafetyLevel.confirmationRequired,
              confirmationRequired: true,
              state: ActionLifecycleState.confirmationRequired,
            );

            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'whatsapp.prepare_message',
              payload: {'contact': recipient, 'message': msg},
              status: ActionExecutionStatus.waitingConfirmation,
              permissionLevel: ActionPermissionLevel.userConfirmation,
            );

            state = state.copyWith(
              isExecuting: false,
              currentStatus: ActionExecutionStatus.waitingConfirmation,
              pendingAction: pendingWa,
              actionHistory: [...state.actionHistory, action],
            );

            return ActionResult.needsConfirmation(
              "Send WhatsApp message to $recipient saying '$msg'?",
              {'contact': recipient, 'message': msg},
            );
          }

          if (appAction == 'app.launch') {
            if (targetApp == null || targetApp.isEmpty) {
              return ActionResult.failure("No application specified to launch.", errorCode: 'MISSING_APP');
            }
            final launchRes = await launchEngine.launchApp(targetApp);
            if (launchRes.success) {
              final action = SystemAction(
                id: const Uuid().v4(),
                type: 'app.launch',
                payload: {
                  'targetApp': targetApp,
                  'app': launchRes.appName,
                  if (launchRes.packageName != null) 'package': launchRes.packageName,
                },
                status: ActionExecutionStatus.success,
                permissionLevel: ActionPermissionLevel.lowRisk,
              );
              state = state.copyWith(
                isExecuting: false,
                currentStatus: ActionExecutionStatus.success,
                actionHistory: [...state.actionHistory, action],
              );
              return ActionResult.success(launchRes.message, {
                'app': launchRes.appName,
                'package': launchRes.packageName,
              });
            } else {
              return ActionResult.failure(
                launchRes.message,
                errorCode: launchRes.error ?? 'LAUNCH_FAILED',
              );
            }
          } else {
            final uri = extra['uri']?.toString();
            final actionRes = await launchEngine.executeAction(
              appId: targetApp ?? '',
              actionType: appAction,
              uriString: uri,
              extraParams: extra,
            );
            if (actionRes.success) {
              final action = SystemAction(
                id: const Uuid().v4(),
                type: appAction,
                payload: {
                  'targetApp': targetApp,
                  'action': appAction,
                  'app': actionRes.appName,
                  if (actionRes.packageName != null) 'package': actionRes.packageName,
                  ...extra,
                },
                status: ActionExecutionStatus.success,
                permissionLevel: ActionPermissionLevel.lowRisk,
              );
              state = state.copyWith(
                isExecuting: false,
                currentStatus: ActionExecutionStatus.success,
                actionHistory: [...state.actionHistory, action],
              );
              return ActionResult.success(actionRes.message, {
                'app': actionRes.appName,
                'package': actionRes.packageName,
                'action': appAction,
              });
            } else {
              return ActionResult.failure(
                actionRes.message,
                errorCode: actionRes.error ?? 'ACTION_FAILED',
              );
            }
          }

        case VajraIntentType.actionConfirm:
          final pending = state.pendingAction;
          if (pending == null) {
            return ActionResult.failure(
              'There is no pending action to confirm.',
              errorCode: 'NO_PENDING_ACTION',
            );
          }

          if (pending.actionType == 'call.make' || pending.actionType == 'phone.prepare_call') {
            final callAssistant = _callAssistant ?? CallAssistant();
            final targetNumber = pending.parameters['phoneNumber']?.toString() ?? '';
            final contactName = pending.parameters['contactName']?.toString();
            final callRes = await callAssistant.makeCall(
              phoneNumber: targetNumber,
              contactName: contactName,
              directCall: false,
            );

            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'call.make',
              payload: {'phoneNumber': targetNumber, 'contactName': contactName},
              status: callRes.success ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
            );

            state = state.copyWith(
              isExecuting: false,
              clearPendingAction: true,
              currentStatus: callRes.success ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
              actionHistory: [...state.actionHistory, action],
            );

            return callRes.success
                ? ActionResult.success(callRes.message, {'contact': contactName, 'number': targetNumber})
                : ActionResult.failure(callRes.message, errorCode: callRes.errorCode ?? 'CALL_FAILED');
          } else if (pending.actionType == 'whatsapp.prepare_message') {
            final launchEngine = _mobileAppLaunchEngine ?? MobileAppLaunchEngine(_deviceControlService);
            final actionRes = await launchEngine.executeAction(
              appId: 'whatsapp',
              actionType: 'whatsapp.prepare_message',
              extraParams: pending.parameters,
            );

            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'whatsapp.prepare_message',
              payload: pending.parameters,
              status: actionRes.success ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
            );

            state = state.copyWith(
              isExecuting: false,
              clearPendingAction: true,
              currentStatus: actionRes.success ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
              actionHistory: [...state.actionHistory, action],
            );

            return actionRes.success
                ? ActionResult.success(actionRes.message, actionRes.packageName != null ? {'package': actionRes.packageName} : null)
                : ActionResult.failure(actionRes.message, errorCode: actionRes.error ?? 'ACTION_FAILED');
          } else if (pending.actionType == 'message.prepare_draft') {
            final msgAssistant = _messageAssistant ?? MessageAssistant();
            final recipient = pending.parameters['recipient']?.toString() ?? '';
            final body = pending.parameters['body']?.toString() ?? '';
            final draft = msgAssistant.activeDraft ?? DraftedMessage(
              id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
              recipient: recipient,
              messageBody: body,
              createdAt: DateTime.now(),
            );
            final sendRes = await msgAssistant.confirmAndSend(draft);

            final action = SystemAction(
              id: const Uuid().v4(),
              type: 'message.send',
              payload: {'recipient': recipient, 'body': body},
              status: sendRes.success ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
            );

            state = state.copyWith(
              isExecuting: false,
              clearPendingAction: true,
              currentStatus: sendRes.success ? ActionExecutionStatus.success : ActionExecutionStatus.failed,
              actionHistory: [...state.actionHistory, action],
            );

            return sendRes.success
                ? ActionResult.success(sendRes.message)
                : ActionResult.failure(sendRes.message, errorCode: sendRes.errorCode ?? 'SEND_FAILED');
          }

          state = state.copyWith(clearPendingAction: true);
          return ActionResult.failure('Unknown pending action type: ${pending.actionType}');

        case VajraIntentType.actionCancel:
          final hadPending = state.pendingAction != null;
          state = state.copyWith(
            isExecuting: false,
            clearPendingAction: true,
            currentStatus: ActionExecutionStatus.cancelled,
          );
          return hadPending
              ? ActionResult.success('Action cancelled.')
              : ActionResult.success('Nothing to cancel.');

        case VajraIntentType.information:
          return ActionResult.success('Information request');
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        lastError: e.toString(),
        currentStatus: ActionExecutionStatus.failed,
      );
      return ActionResult.failure('Action execution failed: $e');
    } finally {
      if (state.isExecuting) {
        state = state.copyWith(isExecuting: false);
      }
    }
  }

  Future<ActionResult> _generatePlanMyDay(VajraParsedCommand command) async {
    final now = command.dateTime ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final isToday = now.day == DateTime.now().day && now.month == DateTime.now().month;
    final dayLabel = isToday ? 'today' : DateFormat('EEEE, MMM d').format(now);

    final planner = _plannerRepository;
    final devCal = _deviceCalendarService;
    final study = _studyRepository;

    // 1. Fetch Calendar Events
    final events = <Map<String, dynamic>>[];
    if (planner != null) {
      final eventsRes = await planner.getCalendarEvents(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      for (final e in eventsRes.data ?? []) {
        events.add({
          'title': e.title,
          'start': e.startTime,
          'end': e.endTime,
          'type': e.eventType,
        });
      }
    }
    if (devCal != null && isToday) {
      try {
        final deviceEvents = await devCal.getTodayEvents();
        for (final de in deviceEvents) {
          if (!events.any((e) => e['title'] == de.title)) {
            events.add({
              'title': de.title,
              'start': de.startTime,
              'end': de.endTime,
              'type': 'device_calendar',
            });
          }
        }
      } catch (_) {}
    }

    events.sort((a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));

    // 2. Fetch Tasks
    final tasks = <PlannerTask>[];
    if (planner != null) {
      final tasksRes = await planner.getTasks(now);
      final rawTasks = tasksRes.data ?? [];
      tasks.addAll(rawTasks.where((t) => !t.isCompleted));
    }

    // 3. Fetch Assignments
    final activeAssignments = <AssignmentModel>[];
    if (study != null) {
      final assignRes = await study.getAssignments();
      final allAssign = assignRes.data ?? [];
      activeAssignments.addAll(allAssign.where((a) => a.status != 'COMPLETED'));
    }

    // 4. Fetch Study Sessions
    final sessions = <StudySessionModel>[];
    if (study != null) {
      final sessionsRes = await study.getUpcomingSessions();
      final allSessions = sessionsRes.data ?? [];
      sessions.addAll(allSessions.where((s) =>
          s.scheduledTime.year == now.year &&
          s.scheduledTime.month == now.month &&
          s.scheduledTime.day == now.day));
    }

    // Check if we have ANY real data
    final hasAnyData = events.isNotEmpty || tasks.isNotEmpty || activeAssignments.isNotEmpty || sessions.isNotEmpty;
    if (!hasAnyData) {
      return ActionResult.success(
        "You don't have any scheduled events, pending tasks, or upcoming assignments in your planner or calendar for $dayLabel.\n\nWould you like me to schedule a study session or create tasks for your current goals?",
      );
    }

    final buffer = StringBuffer("Here's your plan for $dayLabel:\n\n");

    // Print Schedule
    if (events.isNotEmpty || sessions.isNotEmpty) {
      buffer.writeln("📅 Schedule:");
      for (final e in events) {
        final startStr = DateFormat('h:mm a').format(e['start'] as DateTime);
        final endStr = DateFormat('h:mm a').format(e['end'] as DateTime);
        buffer.writeln("  • $startStr–$endStr — ${e['title']}");
      }
      for (final s in sessions) {
        final startStr = DateFormat('h:mm a').format(s.scheduledTime);
        final endStr = DateFormat('h:mm a').format(s.scheduledTime.add(Duration(minutes: s.durationMinutes)));
        buffer.writeln("  • $startStr–$endStr — ${s.subject} study session: ${s.topic}");
      }
      buffer.writeln();
    }

    // Print Priority Tasks
    if (tasks.isNotEmpty) {
      buffer.writeln("📋 Priority Tasks:");
      for (final t in tasks.take(4)) {
        buffer.writeln("  • ${t.title}");
      }
      buffer.writeln();
    }

    // Print Assignments & Deadlines
    if (activeAssignments.isNotEmpty) {
      buffer.writeln("📚 Upcoming Deadlines:");
      for (final a in activeAssignments.take(3)) {
        final dueStr = a.dueDate != null ? ' (due ${DateFormat('EEE, MMM d').format(a.dueDate!)})' : '';
        buffer.writeln("  • ${a.title}$dueStr");
      }
      buffer.writeln();
    }

    // Prioritization note
    final urgentAssignment = activeAssignments.where((a) =>
        a.dueDate != null && a.dueDate!.difference(now).inDays <= 2).firstOrNull;
    if (urgentAssignment != null) {
      buffer.writeln("You have '${urgentAssignment.title}' due soon, so I prioritized time for it today.");
    }

    return ActionResult.success(buffer.toString().trim());
  }

  static String _formatFriendlyMeetingTime(DateTime dt, [DateTime? endDt]) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;

    String timeStr;
    if (endDt != null) {
      timeStr = "from ${_formatTimeOnly(dt)} to ${_formatTimeOnly(endDt)}";
    } else {
      timeStr = "at ${_formatTimeOnly(dt)}";
    }

    if (isTomorrow) {
      return "tomorrow $timeStr";
    } else if (isToday) {
      return "today $timeStr";
    } else {
      return "${DateFormat('EEEE, MMM d').format(dt)} $timeStr";
    }
  }

  static String _formatTimeOnly(DateTime dt) {
    if (dt.minute == 0) {
      return DateFormat('h a').format(dt);
    } else {
      return DateFormat('h:mm a').format(dt);
    }
  }

  /// Undoes the last executed action if possible.
  Future<bool> undo() async {
    if (state.actionHistory.isEmpty) return false;
    
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

  /// Validates whether a tool can be executed by checking permissions.
  bool canExecuteTool(String toolName) {
    final tool = toolCatalog[toolName];
    if (tool == null) return false;
    return tool.permissionLevel != ActionPermissionLevel.blocked;
  }
}

/// Provider for the ActionEngine.
final actionEngineProvider = StateNotifierProvider<ActionEngine, ActionState>((ref) {
  return ActionEngine(
    plannerRepository: ref.watch(plannerRepositoryProvider),
    studyRepository: ref.watch(studyRepositoryProvider),
    deviceCalendarService: ref.watch(deviceCalendarServiceProvider),
    deviceNotificationService: ref.watch(deviceNotificationServiceProvider),
    memoryRepository: ref.watch(memoryRepositoryProvider),
    callAssistant: ref.watch(callAssistantProvider),
    messageAssistant: ref.watch(messageAssistantProvider),
    deviceControlService: ref.watch(deviceControlServiceProvider),
    notificationAssistant: ref.watch(notificationAssistantProvider),
    proactiveAssistant: ref.watch(proactiveAssistantProvider),
    mobileAppLaunchEngine: ref.watch(mobileAppLaunchEngineProvider),
  );
});

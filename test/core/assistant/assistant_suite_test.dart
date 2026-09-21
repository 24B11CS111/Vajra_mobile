import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/assistant/call_assistant.dart';
import 'package:vajra_mobile/core/assistant/device_control_service.dart';
import 'package:vajra_mobile/core/assistant/message_assistant.dart';
import 'package:vajra_mobile/core/assistant/notification_assistant.dart';
import 'package:vajra_mobile/core/assistant/proactive_assistant.dart';
import 'package:vajra_mobile/core/intelligence/action/vajra_command_router.dart';
import 'package:vajra_mobile/core/intelligence/voice/voice_engine.dart';
import 'package:vajra_mobile/core/network/api_response.dart';
import 'package:vajra_mobile/features/planner/models/calendar_event_model.dart';
import 'package:vajra_mobile/features/planner/models/planner_model.dart';
import 'package:vajra_mobile/features/planner/services/planner_repository.dart';
import 'package:vajra_mobile/core/integrations/device_notification_service.dart';
import 'package:vajra_mobile/core/integrations/device_permission_service.dart';

import 'package:vajra_mobile/features/planner/services/planner_local_data_source.dart';

class _FakePlannerRepository implements PlannerRepository {
  final List<PlannerTask> tasks;
  final List<CalendarEventModel> events;

  _FakePlannerRepository({this.tasks = const [], this.events = const []});

  @override
  PlannerLocalDataSource get localDataSource => throw UnimplementedError();

  @override
  Future<ApiResponse<PlannerTask>> createTask(Map<String, dynamic> data) async =>
      ApiResponse.error('not implemented');

  @override
  Future<ApiResponse<CalendarEventModel>> createCalendarEvent(Map<String, dynamic> data) async =>
      ApiResponse.error('not implemented');

  @override
  Future<ApiResponse<List<PlannerTask>>> getTasks(DateTime date) async => ApiResponse.success(tasks);

  @override
  Future<ApiResponse<List<CalendarEventModel>>> getCalendarEvents(
          {DateTime? startDate, DateTime? endDate, String? eventType}) async =>
      ApiResponse.success(events);

  @override
  Future<ApiResponse<void>> deleteCalendarEvent(String id) async => ApiResponse.success(null);
  @override
  Future<ApiResponse<void>> deleteTask(String id) async => ApiResponse.success(null);
  @override
  Future<ApiResponse<void>> reorderTasks(List<String> taskIds) async => ApiResponse.success(null);
  @override
  Future<ApiResponse<bool>> toggleTaskCompletion(String id, bool isCompleted) async => ApiResponse.success(true);
  @override
  Future<ApiResponse<CalendarEventModel>> updateCalendarEvent(String id, Map<String, dynamic> data) async =>
      ApiResponse.error('not implemented');
}

class _FakeNotificationService extends DeviceNotificationService {
  final List<Map<String, dynamic>> shownReminders = [];

  _FakeNotificationService() : super(DevicePermissionService());

  @override
  Future<bool> showReminder({required String title, required String body, int? id}) async {
    shownReminders.add({'id': id, 'title': title, 'body': body});
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VAJRA 2.0 Assistant Expansion Tests', () {
    // -------------------------------------------------------------
    // 1. Call Assistant Tests
    // -------------------------------------------------------------
    group('CallAssistant', () {
      const channel = MethodChannel('com.vajra.app/call_assistant');

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'searchContacts') {
            final q = methodCall.arguments['query'] as String;
            if (q.toLowerCase().contains('alice')) {
              return [
                {'id': '1', 'displayName': 'Alice Smith', 'phoneNumber': '+15551234'}
              ];
            }
            return [];
          }
          if (methodCall.method == 'makeCall') {
            return {
              'success': true,
              'message': 'Calling ${methodCall.arguments['phoneNumber']}...',
              'openedDialer': false,
            };
          }
          if (methodCall.method == 'openDialer') {
            return true;
          }
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      test('findContacts returns matched contact list', () async {
        final assistant = CallAssistant(channel);
        final results = await assistant.findContacts('Alice');
        expect(results.length, 1);
        expect(results.first.displayName, 'Alice Smith');
        expect(results.first.phoneNumber, '+15551234');
      });

      test('makeCall dispatches telephony call cleanly', () async {
        final assistant = CallAssistant(channel);
        final res = await assistant.makeCall(phoneNumber: '+15551234', contactName: 'Alice');
        expect(res.success, isTrue);
        expect(res.phoneNumber, '+15551234');
        expect(res.contactName, 'Alice');
      });

      test('openDialer invokes dialer without error', () async {
        final assistant = CallAssistant(channel);
        final res = await assistant.openDialer('+15559876');
        expect(res.success, isTrue);
        expect(res.openedDialer, isTrue);
      });
    });

    // -------------------------------------------------------------
    // 2. Message Assistant Tests
    // -------------------------------------------------------------
    group('MessageAssistant', () {
      const channel = MethodChannel('com.vajra.app/message_assistant');

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'openSmsComposer') {
            return {'success': true};
          }
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      test('prepareDraft requires approval and does NOT send automatically', () {
        final assistant = MessageAssistant(channel);
        final result = assistant.prepareDraft(
          recipient: '+15551234',
          body: 'Running 10 mins late',
          recipientName: 'Alice',
        );

        expect(result.success, isTrue);
        expect(result.requiresConfirmation, isTrue);
        expect(result.draft, isNotNull);
        expect(result.draft!.isConfirmed, isFalse);
        expect(result.draft!.messageBody, 'Running 10 mins late');
      });

      test('confirmAndSend dispatches draft after explicit approval', () async {
        final assistant = MessageAssistant(channel);
        final draftRes = assistant.prepareDraft(
          recipient: '+15551234',
          body: 'On my way',
          recipientName: 'Alice',
        );

        expect(assistant.activeDraft, isNotNull);
        final sendRes = await assistant.confirmAndSend(draftRes.draft);
        expect(sendRes.success, isTrue);
        expect(sendRes.draft?.isConfirmed, isTrue);
        expect(assistant.activeDraft, isNull);
      });
    });

    // -------------------------------------------------------------
    // 3. Notification Assistant Tests
    // -------------------------------------------------------------
    group('NotificationAssistant', () {
      const channel = MethodChannel('com.vajra.app/notification_assistant');

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'isPermissionGranted') {
            return true;
          }
          if (methodCall.method == 'getActiveNotifications') {
            return [
              {
                'id': '1_123',
                'packageName': 'com.whatsapp',
                'appName': 'WhatsApp',
                'title': 'Alice',
                'text': 'See you soon',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
              {
                'id': '2_123',
                'packageName': 'com.google.android.gm',
                'appName': 'Gmail',
                'title': 'Project Update',
                'text': 'New report attached',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              }
            ];
          }
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      test('getSummary produces privacy-first local notification summary', () async {
        final assistant = NotificationAssistant(channel);
        final summary = await assistant.getSummary();
        expect(summary.contains('WhatsApp'), isTrue);
        expect(summary.contains('Gmail'), isTrue);
      });
    });

    // -------------------------------------------------------------
    // 4. Device Control Service Tests
    // -------------------------------------------------------------
    group('DeviceControlService', () {
      const channel = MethodChannel('com.vajra.app/device_control');

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'setFlashlight') return true;
          if (methodCall.method == 'setTimer') return true;
          if (methodCall.method == 'openSetting') return true;
          if (methodCall.method == 'sendMediaControl') return true;
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      test('setFlashlight returns true on native success', () async {
        final service = DeviceControlService(channel);
        final ok = await service.setFlashlight(true);
        expect(ok, isTrue);
      });

      test('setTimer passes duration to native timer', () async {
        final service = DeviceControlService(channel);
        final ok = await service.setTimer(seconds: 300, label: 'Study');
        expect(ok, isTrue);
      });

      test('openSetting launches wifi setting', () async {
        final service = DeviceControlService(channel);
        final ok = await service.openSetting(DeviceSettingType.wifi);
        expect(ok, isTrue);
      });

      test('sendMediaControl dispatches play/pause command', () async {
        final service = DeviceControlService(channel);
        final ok = await service.sendMediaControl('pause');
        expect(ok, isTrue);
      });
    });

    // -------------------------------------------------------------
    // 5. Proactive Assistant Tests
    // -------------------------------------------------------------
    group('ProactiveAssistant', () {
      test('isQuietHours accurately detects night hours', () {
        final fakePlanner = _FakePlannerRepository();
        final fakeNotif = _FakeNotificationService();
        final assistant = ProactiveAssistant(
          plannerRepository: fakePlanner,
          notificationService: fakeNotif,
        );

        final midnight = DateTime(2026, 9, 16, 23, 30);
        final noon = DateTime(2026, 9, 16, 12, 0);

        expect(assistant.isQuietHours(midnight), isTrue);
        expect(assistant.isQuietHours(noon), isFalse);
      });

      test('generateAlerts detects overdue tasks and upcoming events', () async {
        final now = DateTime(2026, 9, 16, 14, 0);
        final overdueTask = PlannerTask(
          id: 't1',
          title: 'Review physics notes',
          category: 'General',
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.subtract(const Duration(minutes: 30)),
          isCompleted: false,
        );
        final upcomingEvent = CalendarEventModel(
          id: 'e1',
          userId: 'u1',
          title: 'Team Standup',
          startTime: now.add(const Duration(minutes: 15)),
          eventType: 'meeting',
        );

        final fakePlanner = _FakePlannerRepository(
          tasks: [overdueTask],
          events: [upcomingEvent],
        );
        final fakeNotif = _FakeNotificationService();
        final assistant = ProactiveAssistant(
          plannerRepository: fakePlanner,
          notificationService: fakeNotif,
        );

        final alerts = await assistant.generateAlerts(now);
        expect(alerts.length, 2);
        expect(alerts.any((a) => a.type == ProactiveSuggestionType.overdueTask), isTrue);
        expect(alerts.any((a) => a.type == ProactiveSuggestionType.upcomingEvent), isTrue);
      });
    });

    // -------------------------------------------------------------
    // 6. Router Classification for Assistant Intents
    // -------------------------------------------------------------
    group('VajraCommandRouter Assistant Intent Parsing', () {
      test('Parses Call Intent correctly', () {
        final cmd1 = VajraCommandRouter.parse('Call Alice');
        expect(cmd1.type, VajraIntentType.call);
        expect(cmd1.contactName, 'Alice');

        final cmd2 = VajraCommandRouter.parse('Dial +15551234');
        expect(cmd2.type, VajraIntentType.call);
        expect(cmd2.phoneNumber, '+15551234');
      });

      test('Parses Message Intent with recipient and body', () {
        final cmd = VajraCommandRouter.parse('Text Alice that I am running 10 minutes late');
        expect(cmd.type, VajraIntentType.message);
        expect(cmd.contactName, 'Alice');
        expect(cmd.messageBody, 'I am running 10 minutes late');
      });

      test('Parses Device Control: Flashlight', () {
        final onCmd = VajraCommandRouter.parse('Turn on flashlight');
        expect(onCmd.type, VajraIntentType.deviceControl);
        expect(onCmd.actionSubtype, 'flashlight_on');

        final offCmd = VajraCommandRouter.parse('Turn off flashlight');
        expect(offCmd.type, VajraIntentType.deviceControl);
        expect(offCmd.actionSubtype, 'flashlight_off');
      });

      test('Parses Device Control: Timer', () {
        final cmd = VajraCommandRouter.parse('Set a timer for 15 minutes');
        expect(cmd.type, VajraIntentType.deviceControl);
        expect(cmd.actionSubtype, 'timer');
        expect(cmd.timerSeconds, 900);
      });

      test('Parses Device Control: Settings', () {
        final cmd = VajraCommandRouter.parse('Open wifi settings');
        expect(cmd.type, VajraIntentType.deviceControl);
        expect(cmd.actionSubtype, 'settings_wifi');
      });

      test('Parses Device Control: Media control', () {
        final cmd = VajraCommandRouter.parse('Pause music');
        expect(cmd.type, VajraIntentType.deviceControl);
        expect(cmd.actionSubtype, 'media_pause');
      });

      test('Parses Notification Query', () {
        final cmd = VajraCommandRouter.parse('What did I miss?');
        expect(cmd.type, VajraIntentType.notificationQuery);
      });
    });

    // -------------------------------------------------------------
    // 7. Voice Core Barge-In & State Transitions
    // -------------------------------------------------------------
    group('Voice Core Barge-In and Interrupted States', () {
      test('VoiceSessionState tracks interrupted status and bargeIns', () {
        final session = VoiceSession(
          sessionId: 's1',
          startedAt: DateTime(2026, 9, 16),
          bargeInCount: 2,
        );
        final state = VoiceSessionState(
          status: VoiceState.interrupted,
          bargeInCounter: 2,
          session: session,
        );

        expect(state.isInterrupted, isTrue);
        expect(state.bargeInCounter, 2);
      });
    });
  });
}

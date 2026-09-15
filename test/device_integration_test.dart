import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/integrations/device_permission_service.dart';
import 'package:vajra_mobile/core/integrations/device_calendar_service.dart';
import 'package:vajra_mobile/core/integrations/device_notification_service.dart';
import 'package:vajra_mobile/core/integrations/device_location_service.dart';
import 'package:vajra_mobile/core/intelligence/voice/voice_engine.dart';

class _MockPermissionService extends DevicePermissionService {
  DevicePermissionState mockState;

  _MockPermissionService({this.mockState = DevicePermissionState.granted});

  @override
  Future<DevicePermissionState> checkStatus(DevicePermissionType type) async => mockState;

  @override
  Future<DevicePermissionState> request(DevicePermissionType type) async => mockState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Device Integration & Permission Layer Tests', () {
    test('Permission granted returns granted state', () async {
      final permService = _MockPermissionService(mockState: DevicePermissionState.granted);
      final status = await permService.checkStatus(DevicePermissionType.calendar);
      expect(status, DevicePermissionState.granted);
    });

    test('Permission denied returns denied state', () async {
      final permService = _MockPermissionService(mockState: DevicePermissionState.denied);
      final status = await permService.checkStatus(DevicePermissionType.location);
      expect(status, DevicePermissionState.denied);
    });

    test('Calendar: permission denied returns empty list without throwing', () async {
      final permService = _MockPermissionService(mockState: DevicePermissionState.denied);
      final calendarService = DeviceCalendarService(permService);

      final todayEvents = await calendarService.getTodayEvents();
      expect(todayEvents, isEmpty);

      final upcomingEvents = await calendarService.getUpcomingEvents();
      expect(upcomingEvents, isEmpty);
    });

    test('Calendar: event creation when permission denied returns false gracefully', () async {
      final permService = _MockPermissionService(mockState: DevicePermissionState.denied);
      final calendarService = DeviceCalendarService(permService);

      final created = await calendarService.createCalendarEvent(
        title: 'Team Sync',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(created, isFalse);
    });

    test('Notifications: permission denied returns false gracefully without crashing', () async {
      final permService = _MockPermissionService(mockState: DevicePermissionState.denied);
      final notifService = DeviceNotificationService(permService);

      final shown = await notifService.showReminder(
        title: 'Study Reminder',
        body: 'Physics revision in 15 minutes',
      );
      expect(shown, isFalse);

      final scheduled = await notifService.scheduleReminder(
        title: 'Assignment Due',
        body: 'Submit by midnight',
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(scheduled, isFalse);
    });

    test('Location: permission denied returns null without crashing', () async {
      final permService = _MockPermissionService(mockState: DevicePermissionState.denied);
      final locationService = DeviceLocationService(permService);

      final loc = await locationService.getCurrentLocation();
      expect(loc, isNull);
    });

    test('Microphone: voice engine records error and transitions back to idle when permission denied', () async {
      final permService = _MockPermissionService(mockState: DevicePermissionState.denied);
      final voiceEngine = VoiceEngine(permService);

      await voiceEngine.startListening();

      // Must not be stuck in listening
      expect(voiceEngine.state.isListening, isFalse);
      expect(voiceEngine.state.currentState, anyOf(VoiceState.error, VoiceState.idle));
      // Must set informative error
      expect(voiceEngine.state.error, contains('Microphone permission denied'));
    });
  });
}

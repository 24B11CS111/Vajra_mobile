import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_permission_service.dart';

class DeviceCalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? location;

  const DeviceCalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'isAllDay': isAllDay,
        'location': location,
      };

  factory DeviceCalendarEvent.fromMap(Map<String, dynamic> map) {
    return DeviceCalendarEvent(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Event',
      description: map['description']?.toString(),
      startTime: DateTime.tryParse(map['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(map['endTime']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      isAllDay: map['isAllDay'] == true,
      location: map['location']?.toString(),
    );
  }
}

class CalendarActionResult {
  final bool isSuccess;
  final String? eventId;
  final String? calendarId;
  final String? error;
  final String? errorCode;

  const CalendarActionResult({
    required this.isSuccess,
    this.eventId,
    this.calendarId,
    this.error,
    this.errorCode,
  });

  factory CalendarActionResult.fromMap(Map<dynamic, dynamic> map) {
    final success = map['success'] == true;
    final eventId = map['eventId']?.toString();
    final calendarId = map['calendarId']?.toString();
    final error = map['error']?.toString();
    final message = map['message']?.toString() ?? error;
    return CalendarActionResult(
      isSuccess: success,
      eventId: eventId,
      calendarId: calendarId,
      error: message,
      errorCode: error,
    );
  }

  factory CalendarActionResult.success(dynamic eventId, {String? calendarId}) =>
      CalendarActionResult(
        isSuccess: true,
        eventId: eventId?.toString(),
        calendarId: calendarId,
      );

  factory CalendarActionResult.failure(String error, {String? errorCode}) =>
      CalendarActionResult(
        isSuccess: false,
        error: error,
        errorCode: errorCode,
      );
}

class DeviceCalendarService {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/device_calendar');
  final DevicePermissionService _permissionService;

  DeviceCalendarService(this._permissionService);

  /// Safely retrieves calendar events for today. Returns empty list if permission denied or unavailable.
  Future<List<DeviceCalendarEvent>> getTodayEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getEventsRange(start: startOfDay, end: endOfDay);
  }

  /// Safely retrieves upcoming calendar events for the next [days].
  Future<List<DeviceCalendarEvent>> getUpcomingEvents({int days = 7}) async {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    return getEventsRange(start: now, end: end);
  }

  /// Safely queries calendar events within [start] and [end]. Never throws on permission denied.
  Future<List<DeviceCalendarEvent>> getEventsRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final status = await _permissionService.checkStatus(DevicePermissionType.calendar);
      if (status != DevicePermissionState.granted) {
        return const [];
      }

      final result = await _channel.invokeMethod<List<dynamic>>('getEvents', {
        'startDate': start.millisecondsSinceEpoch,
        'endDate': end.millisecondsSinceEpoch,
      });

      if (result != null) {
        return result
            .whereType<Map>()
            .map((e) => DeviceCalendarEvent.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } on PlatformException catch (pe) {
      debugPrint('DeviceCalendarService platform error (gracefully handled): ${pe.message}');
      return const [];
    } catch (e) {
      debugPrint('DeviceCalendarService general error (gracefully handled): $e');
      return const [];
    }
  }

  /// Safely creates an event on the device calendar with structured result.
  Future<CalendarActionResult> createCalendarEventDetailed({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? location,
    String? userEmail,
  }) async {
    try {
      final status = await _permissionService.checkStatus(DevicePermissionType.calendar);
      if (status != DevicePermissionState.granted) {
        final req = await _permissionService.request(DevicePermissionType.calendar);
        if (req != DevicePermissionState.granted) {
          return CalendarActionResult.failure(
            'Calendar access is not enabled.',
            errorCode: 'PERMISSION_DENIED',
          );
        }
      }

      // Fetch active logged in user email if not explicitly provided
      String? effectiveEmail = userEmail;
      if (effectiveEmail == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          effectiveEmail = prefs.getString('vajra_current_user_id');
        } catch (_) {}
      }

      final result = await _channel.invokeMethod<dynamic>('createEvent', {
        'title': title,
        'description': description,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'isAllDay': isAllDay,
        'location': location,
        'userEmail': effectiveEmail,
      });

      if (result is Map) {
        return CalendarActionResult.fromMap(result);
      } else if (result is num && result.toInt() > 0) {
        return CalendarActionResult.success(result.toInt());
      }
      return CalendarActionResult.failure('Calendar could not record the event.', errorCode: 'INSERT_FAILED');
    } on PlatformException catch (pe) {
      return CalendarActionResult.failure(
        pe.message ?? 'Platform error while creating calendar event',
        errorCode: pe.code,
      );
    } catch (e) {
      return CalendarActionResult.failure(e.toString(), errorCode: 'CALENDAR_ERROR');
    }
  }

  /// Safely creates an event on the device calendar.
  Future<bool> createCalendarEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? location,
  }) async {
    final res = await createCalendarEventDetailed(
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      location: location,
    );
    return res.isSuccess;
  }
}

final deviceCalendarServiceProvider = Provider<DeviceCalendarService>((ref) {
  return DeviceCalendarService(ref.watch(devicePermissionServiceProvider));
});

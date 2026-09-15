import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_permission_service.dart';

class NotificationActionResult {
  final bool isSuccess;
  final int? notificationId;
  final String? error;
  final String? errorCode;

  const NotificationActionResult({
    required this.isSuccess,
    this.notificationId,
    this.error,
    this.errorCode,
  });

  factory NotificationActionResult.success(int id) =>
      NotificationActionResult(isSuccess: true, notificationId: id);

  factory NotificationActionResult.failure(String error, {String? errorCode}) =>
      NotificationActionResult(isSuccess: false, error: error, errorCode: errorCode);
}

class DeviceNotificationService {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/device_notifications');
  final DevicePermissionService _permissionService;

  DeviceNotificationService(this._permissionService);

  /// Requests notification permission (Android 13+ POST_NOTIFICATIONS).
  Future<bool> requestPermission() async {
    final res = await _permissionService.request(DevicePermissionType.notifications);
    return res == DevicePermissionState.granted;
  }

  /// Displays an immediate local notification reminder.
  Future<bool> showReminder({
    required String title,
    required String body,
    int? id,
  }) async {
    try {
      final status = await _permissionService.checkStatus(DevicePermissionType.notifications);
      if (status != DevicePermissionState.granted) {
        final req = await _permissionService.request(DevicePermissionType.notifications);
        if (req != DevicePermissionState.granted) {
          debugPrint('Notification permission denied, skipping system notification.');
          return false;
        }
      }

      final shown = await _channel.invokeMethod<dynamic>('showNotification', {
        'id': id ?? DateTime.now().millisecondsSinceEpoch % 100000,
        'title': title,
        'body': body,
      });

      return shown != null;
    } on PlatformException catch (pe) {
      debugPrint('DeviceNotificationService platform error (gracefully handled): ${pe.message}');
      return false;
    } catch (e) {
      debugPrint('DeviceNotificationService error (gracefully handled): $e');
      return false;
    }
  }

  /// Schedules a future local notification reminder with structured result.
  Future<NotificationActionResult> scheduleReminderDetailed({
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? id,
  }) async {
    try {
      final status = await _permissionService.checkStatus(DevicePermissionType.notifications);
      if (status != DevicePermissionState.granted) {
        final req = await _permissionService.request(DevicePermissionType.notifications);
        if (req != DevicePermissionState.granted) {
          return NotificationActionResult.failure(
            'Notification permission was not granted.',
            errorCode: 'PERMISSION_DENIED',
          );
        }
      }

      final notifId = id ?? (DateTime.now().millisecondsSinceEpoch % 100000);
      final res = await _channel.invokeMethod<dynamic>('scheduleNotification', {
        'id': notifId,
        'title': title,
        'body': body,
        'scheduledEpoch': scheduledDate.millisecondsSinceEpoch,
      });

      if (res is num) {
        return NotificationActionResult.success(res.toInt());
      }
      return NotificationActionResult.success(notifId);
    } on PlatformException catch (pe) {
      return NotificationActionResult.failure(
        pe.message ?? 'Platform error scheduling reminder',
        errorCode: pe.code,
      );
    } catch (e) {
      return NotificationActionResult.failure(e.toString(), errorCode: 'SCHEDULE_ERROR');
    }
  }

  /// Schedules a future local notification reminder for a task or calendar event.
  Future<bool> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? id,
  }) async {
    final res = await scheduleReminderDetailed(
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      id: id,
    );
    return res.isSuccess;
  }

  /// Cancels an existing scheduled notification.
  Future<bool> cancelReminder(int id) async {
    try {
      final res = await _channel.invokeMethod<bool>('cancelNotification', {'id': id});
      return res ?? true;
    } catch (_) {
      return false;
    }
  }
}

final deviceNotificationServiceProvider = Provider<DeviceNotificationService>((ref) {
  return DeviceNotificationService(ref.watch(devicePermissionServiceProvider));
});

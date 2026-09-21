import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents an on-device captured notification item.
class VajraNotificationItem {
  final String id;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final DateTime timestamp;

  const VajraNotificationItem({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.timestamp,
  });

  factory VajraNotificationItem.fromMap(Map<dynamic, dynamic> map) {
    return VajraNotificationItem(
      id: map['id']?.toString() ?? '',
      packageName: map['packageName']?.toString() ?? '',
      appName: map['appName']?.toString() ?? map['packageName']?.toString() ?? 'App',
      title: map['title']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'packageName': packageName,
    'appName': appName,
    'title': title,
    'text': text,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };
}

/// NotificationAssistant provides local privacy-first access to Android notification listener.
class NotificationAssistant {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/notification_assistant');
  final MethodChannel channel;

  NotificationAssistant([MethodChannel? customChannel]) : channel = customChannel ?? _channel;

  /// Checks if Notification Listener Service permission is granted by the user in system settings.
  Future<bool> isPermissionGranted() async {
    try {
      final res = await channel.invokeMethod<bool>('isPermissionGranted');
      return res ?? false;
    } catch (e) {
      debugPrint('[NotificationAssistant] isPermissionGranted error: $e');
      return false;
    }
  }

  /// Directs the user to Android Notification Listener Access settings screen.
  Future<bool> openPermissionSettings() async {
    try {
      final res = await channel.invokeMethod<bool>('openPermissionSettings');
      return res ?? false;
    } catch (e) {
      debugPrint('[NotificationAssistant] openPermissionSettings error: $e');
      return false;
    }
  }

  /// Retrieves list of currently active on-device notifications.
  Future<List<VajraNotificationItem>> getActiveNotifications() async {
    try {
      final res = await channel.invokeMethod<List<dynamic>>('getActiveNotifications');
      if (res == null) return [];
      return res
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => VajraNotificationItem.fromMap(m))
          .toList();
    } catch (e) {
      debugPrint('[NotificationAssistant] getActiveNotifications error: $e');
      return [];
    }
  }

  /// Generates a local, on-device natural language summary of recent notifications.
  /// Strictly processed locally without uploading raw notifications to the cloud.
  Future<String> getSummary() async {
    final hasPerm = await isPermissionGranted();
    if (!hasPerm) {
      return "I need Notification Access to read your notifications. Please enable it in Android Settings.";
    }

    final notifications = await getActiveNotifications();
    if (notifications.isEmpty) {
      return "You're all caught up! You have no new notifications.";
    }

    // Group notifications by app
    final Map<String, List<VajraNotificationItem>> grouped = {};
    for (final notif in notifications) {
      if (notif.title.isEmpty && notif.text.isEmpty) continue;
      grouped.putIfAbsent(notif.appName, () => []).add(notif);
    }

    if (grouped.isEmpty) {
      return "You have no active alerts.";
    }

    final buffer = StringBuffer();
    buffer.write("Here is what you missed: ");

    final entries = grouped.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final appName = entries[i].key;
      final items = entries[i].value;
      if (i > 0) {
        if (i == entries.length - 1) {
          buffer.write(", and ");
        } else {
          buffer.write(", ");
        }
      }

      if (items.length == 1) {
        final item = items.first;
        if (item.title.isNotEmpty) {
          buffer.write("${item.title} on $appName");
        } else {
          buffer.write("1 notification from $appName");
        }
      } else {
        buffer.write("${items.length} notifications from $appName");
      }
    }
    buffer.write(".");
    return buffer.toString();
  }
}

/// Provider for NotificationAssistant.
final notificationAssistantProvider = Provider<NotificationAssistant>((ref) {
  return NotificationAssistant();
});

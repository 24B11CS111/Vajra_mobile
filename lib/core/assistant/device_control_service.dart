import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported system settings destinations.
enum DeviceSettingType {
  wifi,
  bluetooth,
  sound,
  display,
  battery,
  notifications,
  settings,
  app,
  vajraApp,
}

/// DeviceControlService handles low-level Android device capabilities such as
/// flashlight, countdown timers, media dispatch, and settings panels.
class DeviceControlService {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/device_control');
  final MethodChannel channel;

  DeviceControlService([MethodChannel? customChannel]) : channel = customChannel ?? _channel;

  /// Turns flashlight on or off via Android CameraManager.
  Future<bool> setFlashlight(bool enable) async {
    try {
      final res = await channel.invokeMethod<bool>('setFlashlight', {'enable': enable});
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] setFlashlight error: $e');
      return false;
    }
  }

  /// Sets an Android countdown timer using AlarmClock.ACTION_SET_TIMER.
  Future<bool> setTimer({required int seconds, String? label}) async {
    try {
      final res = await channel.invokeMethod<bool>('setTimer', {
        'seconds': seconds,
        'label': label ?? 'VAJRA Timer',
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] setTimer error: $e');
      return false;
    }
  }

  /// Cancels an active countdown timer via AlarmClock.ACTION_DISMISS_TIMER.
  Future<bool> cancelTimer() async {
    try {
      final res = await channel.invokeMethod<bool>('cancelTimer');
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] cancelTimer error: $e');
      return false;
    }
  }

  /// Opens the requested system settings screen.
  Future<bool> openSetting(DeviceSettingType type) async {
    try {
      final settingTypeString = type == DeviceSettingType.vajraApp ? 'app' : type.name;
      final res = await channel.invokeMethod<bool>('openSetting', {
        'type': settingTypeString,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] openSetting error: $e');
      return false;
    }
  }

  /// Adjusts system volume up or down with standard Android volume slider UI.
  Future<bool> adjustVolume({required bool up}) async {
    try {
      final res = await channel.invokeMethod<bool>('adjustVolume', {
        'direction': up ? 'up' : 'down',
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] adjustVolume error: $e');
      return false;
    }
  }

  /// Dispatches a media playback control key event (play, pause, next, prev).
  Future<bool> sendMediaControl(String command) async {
    try {
      final res = await channel.invokeMethod<bool>('sendMediaControl', {
        'command': command,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] sendMediaControl error: $e');
      return false;
    }
  }

  /// Opens an approved Android application via its package name.
  Future<bool> openApp(String packageName) async {
    try {
      final res = await channel.invokeMethod<bool>('openApp', {
        'packageName': packageName,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] openApp error: $e');
      return false;
    }
  }

  /// Checks whether an application is installed by its package name.
  Future<bool> isAppInstalled(String packageName) async {
    try {
      final res = await channel.invokeMethod<bool>('isAppInstalled', {
        'packageName': packageName,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('[DeviceControlService] isAppInstalled error: $e');
      return false;
    }
  }

  /// Checks installation status for a batch of package names.
  Future<Map<String, bool>> checkInstalledPackages(List<String> packageNames) async {
    try {
      final res = await channel.invokeMapMethod<String, bool>('getInstalledApps', {
        'packages': packageNames,
      });
      return res ?? {};
    } catch (e) {
      debugPrint('[DeviceControlService] checkInstalledPackages error: $e');
      return {};
    }
  }

  /// Executes an app-specific action via native Android intent or deep link.
  Future<AppExecutionResult> executeAppAction({
    required String actionType,
    String? packageName,
    String? uriString,
    Map<String, dynamic>? extraParams,
  }) async {
    try {
      final res = await channel.invokeMapMethod<String, dynamic>('executeAppAction', {
        'actionType': actionType,
        'packageName': packageName,
        'uriString': uriString,
        'extraParams': extraParams ?? {},
      });
      final isOk = res?['success'] == true;
      final error = res?['error']?.toString();
      return isOk
          ? AppExecutionResult.success()
          : AppExecutionResult.failure(error ?? 'ACTION_EXECUTION_FAILED');
    } catch (e) {
      debugPrint('[DeviceControlService] executeAppAction error: $e');
      return AppExecutionResult.failure(e.toString());
    }
  }
}

/// Execution result returned by native app action calls.
class AppExecutionResult {
  final bool success;
  final String? error;

  const AppExecutionResult({required this.success, this.error});

  factory AppExecutionResult.success() => const AppExecutionResult(success: true);
  factory AppExecutionResult.failure(String error) => AppExecutionResult(success: false, error: error);
}

/// Provider for DeviceControlService.
final deviceControlServiceProvider = Provider<DeviceControlService>((ref) {
  return DeviceControlService();
});

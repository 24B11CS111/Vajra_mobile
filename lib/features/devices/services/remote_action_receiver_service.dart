import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/assistant/device_control_service.dart';
import '../../../core/assistant/mobile_app_registry.dart';
import 'device_registry_service.dart';

final remoteActionReceiverServiceProvider = Provider<RemoteActionReceiverService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final deviceRegistry = ref.watch(deviceRegistryServiceProvider);
  final deviceControl = ref.watch(deviceControlServiceProvider);
  return RemoteActionReceiverService(apiClient, deviceRegistry, deviceControl);
});

class RemoteActionReceiverService {
  final ApiClient _apiClient;
  final DeviceRegistryService _deviceRegistryService;
  final DeviceControlService _deviceControlService;

  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isRunning = false;

  RemoteActionReceiverService(
    this._apiClient,
    this._deviceRegistryService,
    this._deviceControlService,
  );

  bool get isRunning => _isRunning;

  /// Starts periodic polling for pending remote actions.
  void start({Duration interval = const Duration(seconds: 2)}) {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('[RemoteActionReceiver] Started remote action polling loop (${interval.inSeconds}s interval)');

    _pollPendingActions();
    _pollingTimer = Timer.periodic(interval, (_) => _pollPendingActions());
  }

  /// Stops polling.
  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isRunning = false;
    debugPrint('[RemoteActionReceiver] Stopped remote action polling loop');
  }

  Future<void> _pollPendingActions() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final deviceId = await _deviceRegistryService.getOrCreateDeviceId();
      final response = await _apiClient.dio.get(
        ApiEndpoints.pendingActions,
        queryParameters: {'device_id': deviceId},
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        List<dynamic> actions = [];
        if (data is Map<String, dynamic> && data['actions'] != null) {
          actions = data['actions'] as List<dynamic>;
        } else if (data is List<dynamic>) {
          actions = data;
        }

        for (final item in actions) {
          if (item is Map<String, dynamic>) {
            await executeRemoteAction(item);
          }
        }
      }
    } catch (e) {
      // Suppress network retry logs to avoid spamming console
    } finally {
      _isPolling = false;
    }
  }

  /// Approved applications whitelist for remote launch
  static const Map<String, String> approvedApps = {
    'chrome': 'com.android.chrome',
    'google chrome': 'com.android.chrome',
    'youtube': 'com.google.android.youtube',
    'maps': 'com.google.android.apps.maps',
    'google maps': 'com.google.android.apps.maps',
    'phone': 'com.google.android.dialer',
    'dialer': 'com.google.android.dialer',
    'messages': 'com.google.android.apps.messaging',
    'messaging': 'com.google.android.apps.messaging',
    'settings': 'com.android.settings',
  };

  /// Executes a single remote action and posts execution acknowledgement.
  Future<bool> executeRemoteAction(Map<String, dynamic> action) async {
    final actionId = action['id']?.toString() ?? '';
    final actionType = action['action_type']?.toString() ?? '';
    final params = action['parameters'] is Map<String, dynamic>
        ? action['parameters'] as Map<String, dynamic>
        : <String, dynamic>{};

    debugPrint('[RemoteActionReceiver] Received remote action: $actionType (ID: $actionId)');

    bool success = false;
    String resultMessage = '';
    String? errorCode;

    try {
      switch (actionType) {
        case 'device.flashlight':
          final enable = params['enabled'] == true || params['enabled'] == 'true';
          success = await _deviceControlService.setFlashlight(enable);
          resultMessage = success
              ? (enable ? 'Phone flashlight is on.' : 'Phone flashlight is off.')
              : 'Physical camera torch could not be toggled.';
          errorCode = success ? null : 'DEVICE_ERROR';
          break;

        case 'device.timer':
          final seconds = params['seconds'] is num ? (params['seconds'] as num).toInt() : 60;
          final label = params['label']?.toString() ?? 'VAJRA Timer';
          success = await _deviceControlService.setTimer(seconds: seconds, label: label);
          resultMessage = success ? 'Started timer for $seconds seconds.' : 'Could not start timer.';
          errorCode = success ? null : 'TIMER_ERROR';
          break;

        case 'device.media':
        case 'device.media.play':
        case 'device.media.pause':
        case 'device.media.next':
        case 'device.media.previous':
          String command = 'play';
          if (actionType.startsWith('device.media.')) {
            command = actionType.replaceFirst('device.media.', '');
          } else if (params['command'] != null) {
            command = params['command'].toString();
          }
          success = await _deviceControlService.sendMediaControl(command);
          resultMessage = success ? 'Media command "$command" executed on phone.' : 'Could not execute media command.';
          errorCode = success ? null : 'MEDIA_ERROR';
          break;

        case 'device.settings':
          success = await _deviceControlService.openSetting(DeviceSettingType.settings);
          resultMessage = success ? 'Phone settings opened.' : 'Could not open phone settings.';
          errorCode = success ? null : 'SETTINGS_ERROR';
          break;

        case 'device.wifi_settings':
          success = await _deviceControlService.openSetting(DeviceSettingType.wifi);
          resultMessage = success ? 'Phone Wi-Fi settings opened.' : 'Could not open Wi-Fi settings.';
          errorCode = success ? null : 'SETTINGS_ERROR';
          break;

        case 'device.bluetooth_settings':
          success = await _deviceControlService.openSetting(DeviceSettingType.bluetooth);
          resultMessage = success ? 'Phone Bluetooth settings opened.' : 'Could not open Bluetooth settings.';
          errorCode = success ? null : 'SETTINGS_ERROR';
          break;

        case 'device.app.open':
        case 'app.open':
          final appName = params['app']?.toString().toLowerCase().trim() ?? '';
          final requestedPackage = params['package']?.toString().trim();
          final universalAction = params['universal_action'] is Map<String, dynamic>
              ? params['universal_action'] as Map<String, dynamic>
              : (params['universal_action'] is Map ? Map<String, dynamic>.from(params['universal_action'] as Map) : null);
          final subAction = universalAction?['action_type']?.toString() ?? params['sub_action']?.toString();
          final query = params['query']?.toString() ??
              (universalAction?['parameters'] is Map ? (universalAction!['parameters'] as Map)['query']?.toString() : null);

          final appDef = (appName.isNotEmpty ? MobileAppRegistry.resolveApp(appName) : null) ??
              (requestedPackage != null ? MobileAppRegistry.resolveByPackage(requestedPackage) : null);

          if (appDef != null) {
            // Check if there is a deep action such as YouTube search, Maps search, or Browser search
            if (subAction == 'youtube.search' || (appDef.id == 'youtube' && query != null && query.isNotEmpty)) {
              final res = await _deviceControlService.executeAppAction(
                actionType: 'youtube.search',
                packageName: appDef.defaultPackage,
                extraParams: {'query': query},
              );
              success = res.success;
              resultMessage = success ? 'Searched YouTube for "$query" on phone.' : (res.error ?? 'YouTube search failed.');
              errorCode = success ? null : 'ACTION_FAILED';
            } else if (subAction == 'maps.search' || (appDef.id == 'maps' && query != null && query.isNotEmpty)) {
              final res = await _deviceControlService.executeAppAction(
                actionType: 'maps.search',
                packageName: appDef.defaultPackage,
                extraParams: {'query': query},
              );
              success = res.success;
              resultMessage = success ? 'Searched Maps for "$query" on phone.' : (res.error ?? 'Maps search failed.');
              errorCode = success ? null : 'ACTION_FAILED';
            } else if (subAction == 'browser.search' || (appDef.id == 'chrome' && query != null && query.isNotEmpty)) {
              final res = await _deviceControlService.executeAppAction(
                actionType: 'browser.search',
                packageName: appDef.defaultPackage,
                extraParams: {'query': query},
              );
              success = res.success;
              resultMessage = success ? 'Searched the web for "$query" on phone.' : (res.error ?? 'Browser search failed.');
              errorCode = success ? null : 'ACTION_FAILED';
            } else {
              String targetPackage = appDef.defaultPackage;
              bool isInstalled = await _deviceControlService.isAppInstalled(targetPackage);
              if (!isInstalled && appDef.fallbackPackages.isNotEmpty) {
                for (final fallback in appDef.fallbackPackages) {
                  if (await _deviceControlService.isAppInstalled(fallback)) {
                    targetPackage = fallback;
                    isInstalled = true;
                    break;
                  }
                }
              }

              if (appDef.id == 'settings') {
                success = await _deviceControlService.openSetting(DeviceSettingType.settings);
              } else {
                success = await _deviceControlService.openApp(targetPackage);
              }

              resultMessage = success
                  ? 'Opened ${appDef.name} on phone.'
                  : 'Could not open ${appDef.name} on phone.';
              errorCode = success ? null : 'LAUNCH_ERROR';
            }
          } else {
            success = false;
            resultMessage = "The app isn't currently available through VAJRA.";
            errorCode = 'APP_NOT_APPROVED';
          }
          break;

        case 'browser.search':
        case 'browser.open_url':
        case 'youtube.search':
        case 'youtube.open_video':
        case 'maps.search':
        case 'maps.navigate':
        case 'instagram.profile':
        case 'instagram.open_url':
        case 'whatsapp.chat':
        case 'whatsapp.prepare_message':
          final appId = actionType.split('.').first;
          final appDef = MobileAppRegistry.resolveApp(appId);
          if (appDef != null) {
            final res = await _deviceControlService.executeAppAction(
              actionType: actionType,
              packageName: appDef.defaultPackage,
              uriString: params['uri']?.toString() ?? params['url']?.toString(),
              extraParams: params,
            );
            success = res.success;
            resultMessage = success ? 'Executed $actionType on phone.' : (res.error ?? 'Action failed.');
            errorCode = success ? null : 'ACTION_FAILED';
          } else {
            success = false;
            resultMessage = 'App not approved for action.';
            errorCode = 'APP_NOT_APPROVED';
          }
          break;

        default:
          success = false;
          resultMessage = 'Action type $actionType is not supported on this device.';
          errorCode = 'UNSUPPORTED';
          break;
      }
    } catch (e) {
      success = false;
      resultMessage = 'Execution failed: $e';
      errorCode = 'EXECUTION_EXCEPTION';
    }

    // Acknowledge execution back to Cloud Brain
    if (actionId.isNotEmpty) {
      await acknowledgeAction(
        actionId: actionId,
        success: success,
        resultMessage: resultMessage,
        errorCode: errorCode,
      );
    }

    return success;
  }

  /// Posts execution acknowledgement (SUCCESS or FAILED) to the Cloud Brain.
  Future<bool> acknowledgeAction({
    required String actionId,
    required bool success,
    String? resultMessage,
    String? errorCode,
  }) async {
    try {
      final ackUrl = '${ApiEndpoints.devices}/actions/$actionId/ack';
      final payload = <String, dynamic>{
        'status': success ? 'SUCCESS' : 'FAILED',
      };
      if (resultMessage != null) {
        payload['result_message'] = resultMessage;
      }
      if (errorCode != null) {
        payload['error_code'] = errorCode;
      }
      final response = await _apiClient.dio.post(
        ackUrl,
        data: payload,
      );

      return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      debugPrint('[RemoteActionReceiver] Failed to acknowledge action $actionId: $e');
      return false;
    }
  }
}

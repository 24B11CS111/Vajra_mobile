import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/assistant/device_control_service.dart';
import 'package:vajra_mobile/core/network/api_client.dart';
import 'package:vajra_mobile/core/services/secure_storage_service.dart';
import 'package:vajra_mobile/features/devices/services/device_registry_service.dart';
import 'package:vajra_mobile/features/devices/services/remote_action_receiver_service.dart';

class _MockSecureStorageService implements SecureStorageService {
  String? _token;
  _MockSecureStorageService(this._token);
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<void> deleteToken() async => _token = null;
}

class FakeDeviceControlService extends DeviceControlService {
  bool lastFlashlightState = false;
  int setFlashlightCalls = 0;
  int setTimerCalls = 0;
  String? lastMediaCommand;
  DeviceSettingType? lastSettingType;
  String? lastOpenedPackage;

  @override
  Future<bool> setFlashlight(bool enable) async {
    setFlashlightCalls++;
    lastFlashlightState = enable;
    return true;
  }

  @override
  Future<bool> setTimer({required int seconds, String? label}) async {
    setTimerCalls++;
    return true;
  }

  @override
  Future<bool> sendMediaControl(String command) async {
    lastMediaCommand = command;
    return true;
  }

  @override
  Future<bool> openSetting(DeviceSettingType type) async {
    lastSettingType = type;
    return true;
  }

  @override
  Future<bool> openApp(String packageName) async {
    lastOpenedPackage = packageName;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Remote Action Receiver Tests', () {
    late FakeDeviceControlService fakeDeviceControl;
    late DeviceRegistryService fakeRegistry;
    late ApiClient fakeApiClient;
    late RemoteActionReceiverService service;

    setUp(() {
      fakeDeviceControl = FakeDeviceControlService();
      final storage = _MockSecureStorageService('mock_token_123');
      fakeApiClient = ApiClient(storage);
      fakeRegistry = DeviceRegistryService(fakeApiClient);
      service = RemoteActionReceiverService(fakeApiClient, fakeRegistry, fakeDeviceControl);
    });

    test('Executes device.flashlight enabled=true correctly', () async {
      final action = {
        'id': 'action_123',
        'action_type': 'device.flashlight',
        'parameters': {'enabled': true},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isTrue);
      expect(fakeDeviceControl.setFlashlightCalls, equals(1));
      expect(fakeDeviceControl.lastFlashlightState, isTrue);
    });

    test('Executes device.flashlight enabled=false correctly', () async {
      final action = {
        'id': 'action_124',
        'action_type': 'device.flashlight',
        'parameters': {'enabled': false},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isTrue);
      expect(fakeDeviceControl.setFlashlightCalls, equals(1));
      expect(fakeDeviceControl.lastFlashlightState, isFalse);
    });

    test('Executes device.timer correctly', () async {
      final action = {
        'id': 'action_125',
        'action_type': 'device.timer',
        'parameters': {'seconds': 120, 'label': 'Study Timer'},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isTrue);
      expect(fakeDeviceControl.setTimerCalls, equals(1));
    });

    test('Executes device.media.play correctly', () async {
      final action = {
        'id': 'action_media_1',
        'action_type': 'device.media.play',
        'parameters': {},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isTrue);
      expect(fakeDeviceControl.lastMediaCommand, equals('play'));
    });

    test('Executes device.wifi_settings correctly', () async {
      final action = {
        'id': 'action_wifi_1',
        'action_type': 'device.wifi_settings',
        'parameters': {},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isTrue);
      expect(fakeDeviceControl.lastSettingType, equals(DeviceSettingType.wifi));
    });

    test('Executes approved app launch (chrome) correctly', () async {
      final action = {
        'id': 'action_app_chrome',
        'action_type': 'device.app.open',
        'parameters': {'app': 'chrome'},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isTrue);
      expect(fakeDeviceControl.lastOpenedPackage, equals('com.android.chrome'));
    });

    test('Blocks unapproved app launch', () async {
      final action = {
        'id': 'action_app_bad',
        'action_type': 'device.app.open',
        'parameters': {'app': 'malicious_app_unknown'},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isFalse);
      expect(fakeDeviceControl.lastOpenedPackage, isNull);
    });

    test('Rejects unknown/unsupported remote action', () async {
      final action = {
        'id': 'action_126',
        'action_type': 'device.unsupported_action',
        'parameters': {},
      };

      final result = await service.executeRemoteAction(action);
      expect(result, isFalse);
    });
  });
}

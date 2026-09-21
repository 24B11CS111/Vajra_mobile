import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../models/device_model.dart';

final deviceRegistryServiceProvider = Provider<DeviceRegistryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeviceRegistryService(apiClient);
});

class DeviceRegistryService {
  final ApiClient _apiClient;
  static const String _deviceIdKey = 'vajra_persistent_device_id';

  DeviceRegistryService(this._apiClient);

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var devId = prefs.getString(_deviceIdKey);
    if (devId == null || devId.isEmpty) {
      final prefix = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'device');
      devId = '${prefix}_${const Uuid().v4().substring(0, 8)}';
      await prefs.setString(_deviceIdKey, devId);
    }
    return devId;
  }

  Future<ApiResponse<EcosystemDevice>> registerCurrentDevice({String? customName}) async {
    try {
      final devId = await getOrCreateDeviceId();
      final platformName = Platform.isAndroid
          ? 'android'
          : (Platform.isIOS ? 'ios' : (Platform.isWindows ? 'windows' : 'unknown'));
      final deviceName = customName ?? (Platform.isAndroid ? 'VAJRA Phone' : 'VAJRA Client');

      final response = await _apiClient.dio.post(
        ApiEndpoints.registerDevice,
        data: {
          'device_id': devId,
          'device_type': 'mobile',
          'device_name': deviceName,
          'platform': platformName,
          'app_version': '2.0.0',
          'capabilities': [
            'call',
            'sms',
            'camera',
            'gps',
            'flashlight',
            'notifications',
            'mobile_calendar',
            'mobile_alarms',
            'media',
            'settings',
            'apps',
          ],
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final device = EcosystemDevice.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success(device);
      }
      return ApiResponse.error('Failed to register device: status ${response.statusCode}');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<EcosystemDevice>>> getConnectedDevices() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.devices);
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final data = response.data;
        List<dynamic> deviceList = [];
        if (data is Map<String, dynamic> && data['devices'] != null) {
          deviceList = data['devices'] as List<dynamic>;
        } else if (data is List<dynamic>) {
          deviceList = data;
        }
        final list = deviceList
            .map((item) => EcosystemDevice.fromJson(item as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(list);
      }
      return ApiResponse.error('Failed to fetch devices: status ${response.statusCode}');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<void>> disconnectDevice(String deviceId) async {
    try {
      final response = await _apiClient.dio.delete('${ApiEndpoints.devices}/$deviceId');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error('Failed to disconnect device: status ${response.statusCode}');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

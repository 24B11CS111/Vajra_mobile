import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_permission_service.dart';

class DeviceLocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? description;

  const DeviceLocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'description': description,
      };

  factory DeviceLocationData.fromMap(Map<String, dynamic> map) {
    return DeviceLocationData(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      description: map['description']?.toString(),
    );
  }
}

class DeviceLocationService {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/device_location');
  final DevicePermissionService _permissionService;

  DeviceLocationService(this._permissionService);

  /// Requests foreground location only when a location-aware feature is explicitly invoked.
  /// Strictly NO background or continuous tracking.
  Future<DeviceLocationData?> getCurrentLocation({bool requestIfNotGranted = true}) async {
    try {
      DevicePermissionState status = await _permissionService.checkStatus(DevicePermissionType.location);

      if (status != DevicePermissionState.granted) {
        if (!requestIfNotGranted) return null;
        status = await _permissionService.request(DevicePermissionType.location);
        if (status != DevicePermissionState.granted) {
          debugPrint('Location permission not granted, gracefully returning null.');
          return null;
        }
      }

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation');
      if (result != null) {
        return DeviceLocationData.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (pe) {
      debugPrint('DeviceLocationService platform error (gracefully handled): ${pe.message}');
      return null;
    } catch (e) {
      debugPrint('DeviceLocationService error (gracefully handled): $e');
      return null;
    }
  }
}

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return DeviceLocationService(ref.watch(devicePermissionServiceProvider));
});

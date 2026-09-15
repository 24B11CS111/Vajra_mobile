import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum DevicePermissionType {
  calendar,
  notifications,
  microphone,
  location,
  camera,
}

enum DevicePermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

class DevicePermissionService {
  /// Checks the current status of a given permission type.
  Future<DevicePermissionState> checkStatus(DevicePermissionType type) async {
    try {
      final permission = _mapPermission(type);
      if (permission == null) return DevicePermissionState.unavailable;

      final status = await permission.status;
      return _mapStatus(status);
    } catch (e) {
      debugPrint('DevicePermissionService checkStatus error: $e');
      return DevicePermissionState.denied;
    }
  }

  /// Requests the given permission type gracefully. Never throws or crashes.
  Future<DevicePermissionState> request(DevicePermissionType type) async {
    try {
      final permission = _mapPermission(type);
      if (permission == null) return DevicePermissionState.unavailable;

      final status = await permission.request();
      return _mapStatus(status);
    } catch (e) {
      debugPrint('DevicePermissionService request error: $e');
      return DevicePermissionState.denied;
    }
  }

  /// Opens application settings if permanently denied.
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Permission? _mapPermission(DevicePermissionType type) {
    switch (type) {
      case DevicePermissionType.calendar:
        return Permission.calendarFullAccess;
      case DevicePermissionType.notifications:
        return Permission.notification;
      case DevicePermissionType.microphone:
        return Permission.microphone;
      case DevicePermissionType.location:
        return Permission.locationWhenInUse;
      case DevicePermissionType.camera:
        return Permission.camera;
    }
  }

  DevicePermissionState _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return DevicePermissionState.granted;
    } else if (status.isPermanentlyDenied) {
      return DevicePermissionState.permanentlyDenied;
    } else if (status.isRestricted) {
      return DevicePermissionState.restricted;
    } else {
      return DevicePermissionState.denied;
    }
  }
}

final devicePermissionServiceProvider = Provider<DevicePermissionService>((ref) {
  return DevicePermissionService();
});

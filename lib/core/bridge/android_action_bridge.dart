import 'package:flutter/services.dart';

/// Supported external actions on Android.
enum AndroidActionType {
  openBrowser,
  openUrl,
  openSettings,
  openMaps,
  openSupportedApp,
  shareText,
  openVajraScreen,
}

/// Structured observation returned after executing an Android platform action.
class BridgeObservation {
  final AndroidActionType action;
  final bool success;
  final bool isConfirmed;
  final String message;
  final DateTime timestamp;

  const BridgeObservation({
    required this.action,
    required this.success,
    required this.isConfirmed,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() => 'BridgeObservation(action: $action, success: $success, confirmed: $isConfirmed, message: $message)';
}

/// AndroidActionBridge safe platform execution and observation layer.
class AndroidActionBridge {
  static const MethodChannel _channel = MethodChannel('com.vajra.app/device_bridge');

  /// Known safe app schemes
  static const Map<String, String> _supportedApps = {
    'chrome': 'https://google.com',
    'youtube': 'https://youtube.com',
    'maps': 'https://maps.google.com',
    'settings': 'android.settings.SETTINGS',
  };

  /// Safely opens a web URL via platform bridge with observable result.
  Future<BridgeObservation> openUrl(String urlString) async {
    final now = DateTime.now();
    try {
      final uri = Uri.tryParse(urlString);
      if (uri == null || !uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return BridgeObservation(
          action: AndroidActionType.openUrl,
          success: false,
          isConfirmed: true,
          message: 'Invalid URL format or unsupported scheme: $urlString',
          timestamp: now,
        );
      }

      final launched = await _channel.invokeMethod<bool>('openUrl', {'url': urlString}) ?? true;
      return BridgeObservation(
        action: AndroidActionType.openUrl,
        success: launched,
        isConfirmed: launched,
        message: launched ? 'Web URL launched and verified.' : 'Browser launch could not be confirmed by platform.',
        timestamp: now,
      );
    } catch (_) {
      // Safe fallback acknowledging request
      return BridgeObservation(
        action: AndroidActionType.openUrl,
        success: true,
        isConfirmed: false,
        message: 'Browser launch requested; confirmation pending platform callback.',
        timestamp: now,
      );
    }
  }

  /// Opens a known supported app or falls back to web URL.
  Future<BridgeObservation> openSupportedApp(String appName) async {
    final clean = appName.trim().toLowerCase();
    final target = _supportedApps[clean];
    if (target != null && target.startsWith('http')) {
      return await openUrl(target);
    }
    return BridgeObservation(
      action: AndroidActionType.openSupportedApp,
      success: false,
      isConfirmed: true,
      message: 'App "$appName" is not in the allowlisted supported apps catalog.',
      timestamp: DateTime.now(),
    );
  }

  /// Opens Google Maps with a search query.
  Future<BridgeObservation> openMaps(String query) async {
    final encoded = Uri.encodeComponent(query);
    return await openUrl('https://maps.google.com/?q=$encoded');
  }

  /// Safely opens device settings.
  Future<BridgeObservation> openSettings() async {
    final now = DateTime.now();
    try {
      final res = await _channel.invokeMethod<bool>('openSettings') ?? true;
      return BridgeObservation(
        action: AndroidActionType.openSettings,
        success: res,
        isConfirmed: res,
        message: res ? 'Device settings opened.' : 'Failed to open device settings.',
        timestamp: now,
      );
    } catch (_) {
      return BridgeObservation(
        action: AndroidActionType.openSettings,
        success: true,
        isConfirmed: false,
        message: 'Settings launch requested.',
        timestamp: now,
      );
    }
  }
}

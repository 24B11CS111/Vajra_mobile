import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_control_service.dart';
import 'mobile_app_registry.dart';

/// Detailed result of an app launch or app action execution.
class MobileAppActionResult {
  final bool success;
  final String message;
  final String? appName;
  final String? packageName;
  final String? actionType;
  final bool notInstalled;
  final bool unapproved;
  final String? error;

  const MobileAppActionResult({
    required this.success,
    required this.message,
    this.appName,
    this.packageName,
    this.actionType,
    this.notInstalled = false,
    this.unapproved = false,
    this.error,
  });

  factory MobileAppActionResult.success({
    required String message,
    String? appName,
    String? packageName,
    String? actionType,
  }) {
    return MobileAppActionResult(
      success: true,
      message: message,
      appName: appName,
      packageName: packageName,
      actionType: actionType,
    );
  }

  factory MobileAppActionResult.notInstalled({
    required String appName,
    required String packageName,
  }) {
    return MobileAppActionResult(
      success: false,
      message: '$appName is not installed on your phone.',
      appName: appName,
      packageName: packageName,
      notInstalled: true,
      error: 'NOT_INSTALLED',
    );
  }

  factory MobileAppActionResult.unapproved(String query) {
    return MobileAppActionResult(
      success: false,
      message: "That app isn't currently available through VAJRA on your phone.",
      unapproved: true,
      error: 'UNAPPROVED_APP',
    );
  }

  factory MobileAppActionResult.failure({
    required String message,
    String? appName,
    String? errorCode,
  }) {
    return MobileAppActionResult(
      success: false,
      message: message,
      appName: appName,
      error: errorCode ?? 'EXECUTION_FAILED',
    );
  }
}

/// MobileAppLaunchEngine executes verified application launches and deep actions.
class MobileAppLaunchEngine {
  final DeviceControlService _deviceControlService;

  MobileAppLaunchEngine([DeviceControlService? deviceControlService])
      : _deviceControlService = deviceControlService ?? DeviceControlService();

  /// Resolves an app identifier, checks installation status, and launches it safely.
  Future<MobileAppActionResult> launchApp(String appQuery) async {
    final app = MobileAppRegistry.resolveApp(appQuery);
    if (app == null) {
      return MobileAppActionResult.unapproved(appQuery);
    }

    // Check primary package installation
    String targetPackage = app.defaultPackage;
    bool isInstalled = await _deviceControlService.isAppInstalled(targetPackage);

    // If primary is missing, check fallbacks
    if (!isInstalled && app.fallbackPackages.isNotEmpty) {
      for (final fallback in app.fallbackPackages) {
        if (await _deviceControlService.isAppInstalled(fallback)) {
          targetPackage = fallback;
          isInstalled = true;
          break;
        }
      }
    }

    if (!isInstalled) {
      return MobileAppActionResult.notInstalled(
        appName: app.name,
        packageName: targetPackage,
      );
    }

    // Special handling for Settings (opens general settings screen)
    if (app.id == 'settings') {
      final ok = await _deviceControlService.openSetting(DeviceSettingType.settings);
      return ok
          ? MobileAppActionResult.success(
              message: 'Opening Settings.',
              appName: app.name,
              packageName: targetPackage,
              actionType: 'app.launch',
            )
          : MobileAppActionResult.failure(
              message: 'Could not open Settings.',
              appName: app.name,
            );
    }

    // Launch application via package manager
    final ok = await _deviceControlService.openApp(targetPackage);
    if (ok) {
      return MobileAppActionResult.success(
        message: 'Opening ${app.name}.',
        appName: app.name,
        packageName: targetPackage,
        actionType: 'app.launch',
      );
    } else {
      return MobileAppActionResult.failure(
        message: 'Could not launch ${app.name}.',
        appName: app.name,
        errorCode: 'LAUNCH_FAILED',
      );
    }
  }

  /// Executes a rich app action (search, navigate, open url, profile, chat, message).
  Future<MobileAppActionResult> executeAction({
    required String appId,
    required String actionType,
    String? uriString,
    Map<String, dynamic>? extraParams,
  }) async {
    final app = MobileAppRegistry.resolveApp(appId);
    if (app == null) {
      return MobileAppActionResult.unapproved(appId);
    }

    // Check installation (except for system settings)
    if (app.id != 'settings') {
      bool isInstalled = await _deviceControlService.isAppInstalled(app.defaultPackage);
      if (!isInstalled && app.fallbackPackages.isNotEmpty) {
        for (final fallback in app.fallbackPackages) {
          if (await _deviceControlService.isAppInstalled(fallback)) {
            isInstalled = true;
            break;
          }
        }
      }
      if (!isInstalled) {
        return MobileAppActionResult.notInstalled(
          appName: app.name,
          packageName: app.defaultPackage,
        );
      }
    }

    // Block unsupported spam / mass automation actions
    if (app.id == 'instagram' &&
        (actionType.contains('like') ||
            actionType.contains('follow') ||
            actionType.contains('spam') ||
            actionType.contains('comment') ||
            actionType.contains('dm'))) {
      return MobileAppActionResult.failure(
        message: 'This Instagram action is not supported by VAJRA to protect your privacy and account security.',
        appName: app.name,
        errorCode: 'UNSUPPORTED_ACTION',
      );
    }

    String? resolvedUri = uriString;
    if (resolvedUri == null || resolvedUri.isEmpty) {
      switch (actionType) {
        case 'maps.directions':
          final dest = extraParams?['destination']?.toString() ?? '';
          if (dest.isNotEmpty) {
            resolvedUri = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(dest)}';
          }
          break;
        case 'maps.navigate':
          final dest = extraParams?['destination']?.toString() ?? '';
          if (dest.isNotEmpty) {
            resolvedUri = 'google.navigation:q=${Uri.encodeComponent(dest)}&mode=d';
          }
          break;
        case 'youtube.open_channel':
          final ch = extraParams?['channel']?.toString() ?? '';
          if (ch.isNotEmpty) {
            final cleanCh = ch.startsWith('@') ? ch.substring(1) : ch;
            resolvedUri = 'https://www.youtube.com/@$cleanCh';
          }
          break;
        case 'youtube.open_video':
          final vid = extraParams?['videoId']?.toString() ?? '';
          if (vid.isNotEmpty) {
            resolvedUri = vid.startsWith('http') ? vid : 'https://www.youtube.com/watch?v=$vid';
          } else {
            resolvedUri = 'https://www.youtube.com';
          }
          break;
        case 'instagram.post':
          final post = extraParams?['postId']?.toString() ?? '';
          if (post.isNotEmpty) {
            resolvedUri = post.startsWith('http') ? post : 'https://www.instagram.com/p/$post';
          }
          break;
        case 'instagram.reel':
          final reel = extraParams?['reelId']?.toString() ?? '';
          if (reel.isNotEmpty) {
            resolvedUri = reel.startsWith('http') ? reel : 'https://www.instagram.com/reel/$reel';
          }
          break;
        default:
          break;
      }
    }

    // Execute through native platform channel
    final res = await _deviceControlService.executeAppAction(
      actionType: actionType,
      packageName: app.defaultPackage,
      uriString: resolvedUri,
      extraParams: extraParams,
    );

    if (res.success) {
      String successMsg = 'Done.';
      switch (actionType) {
        case 'browser.search':
          final q = extraParams?['query'] ?? '';
          successMsg = 'Searching the web for "$q".';
          break;
        case 'browser.open_url':
          final url = uriString ?? extraParams?['url'] ?? '';
          successMsg = 'Opening $url in Chrome.';
          break;
        case 'youtube.search':
          final q = extraParams?['query'] ?? '';
          successMsg = 'Searching YouTube for "$q".';
          break;
        case 'youtube.open_video':
          successMsg = 'Opening YouTube video.';
          break;
        case 'youtube.open_channel':
          final ch = extraParams?['channel'] ?? '';
          successMsg = 'Opening YouTube channel $ch.';
          break;
        case 'maps.search':
          final q = extraParams?['query'] ?? '';
          successMsg = 'Searching Google Maps for "$q".';
          break;
        case 'maps.directions':
          final dest = extraParams?['destination'] ?? '';
          successMsg = 'Showing directions to $dest in Google Maps.';
          break;
        case 'maps.navigate':
          final dest = extraParams?['destination'] ?? '';
          successMsg = 'Navigating to $dest in Google Maps.';
          break;
        case 'instagram.profile':
          final user = extraParams?['username'] ?? '';
          successMsg = 'Opening Instagram profile @$user.';
          break;
        case 'instagram.post':
          successMsg = 'Opening Instagram post.';
          break;
        case 'instagram.reel':
          successMsg = 'Opening Instagram reel.';
          break;
        case 'instagram.open_url':
          successMsg = 'Opening Instagram URL.';
          break;
        case 'whatsapp.chat':
          final contact = extraParams?['contact'] ?? extraParams?['phone'] ?? '';
          successMsg = 'Opening WhatsApp chat with $contact.';
          break;
        case 'whatsapp.prepare_message':
          final contact = extraParams?['contact'] ?? extraParams?['phone'] ?? 'contact';
          successMsg = 'I\'ve prepared the WhatsApp message to $contact.';
          break;
      }

      return MobileAppActionResult.success(
        message: successMsg,
        appName: app.name,
        packageName: app.defaultPackage,
        actionType: actionType,
      );
    } else {
      return MobileAppActionResult.failure(
        message: 'Could not perform action on ${app.name}: ${res.error ?? "unknown error"}',
        appName: app.name,
        errorCode: res.error,
      );
    }
  }
}

/// Riverpod provider for MobileAppLaunchEngine.
final mobileAppLaunchEngineProvider = Provider<MobileAppLaunchEngine>((ref) {
  final deviceService = ref.watch(deviceControlServiceProvider);
  return MobileAppLaunchEngine(deviceService);
});

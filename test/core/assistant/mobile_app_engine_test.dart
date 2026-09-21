import 'package:flutter_test/flutter_test.dart';
import 'package:vajra_mobile/core/assistant/call_assistant.dart';
import 'package:vajra_mobile/core/assistant/device_control_service.dart';
import 'package:vajra_mobile/core/assistant/mobile_app_launch_engine.dart';
import 'package:vajra_mobile/core/assistant/mobile_app_registry.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';
import 'package:vajra_mobile/core/intelligence/action/universal_action_model.dart';
import 'package:vajra_mobile/core/intelligence/action/vajra_command_router.dart';

class _FakeDeviceControlService extends DeviceControlService {
  final Set<String> installedPackages;
  final List<String> openedPackages = [];
  final List<DeviceSettingType> openedSettings = [];
  final List<Map<String, dynamic>> executedActions = [];
  final List<bool> volumeAdjustments = [];
  bool timerCancelled = false;

  _FakeDeviceControlService({this.installedPackages = const {}});

  @override
  Future<bool> adjustVolume({required bool up}) async {
    volumeAdjustments.add(up);
    return true;
  }

  @override
  Future<bool> cancelTimer() async {
    timerCancelled = true;
    return true;
  }

  @override
  Future<bool> isAppInstalled(String packageName) async {
    return installedPackages.contains(packageName);
  }

  @override
  Future<Map<String, bool>> checkInstalledPackages(List<String> packageNames) async {
    final map = <String, bool>{};
    for (final pkg in packageNames) {
      map[pkg] = installedPackages.contains(pkg);
    }
    return map;
  }

  @override
  Future<bool> openApp(String packageName) async {
    openedPackages.add(packageName);
    return true;
  }

  @override
  Future<bool> openSetting(DeviceSettingType type) async {
    openedSettings.add(type);
    return true;
  }

  @override
  Future<AppExecutionResult> executeAppAction({
    required String actionType,
    String? packageName,
    String? uriString,
    Map<String, dynamic>? extraParams,
  }) async {
    executedActions.add({
      'actionType': actionType,
      'packageName': packageName,
      'uriString': uriString,
      'extraParams': extraParams,
    });
    return const AppExecutionResult(success: true);
  }
}

class _FakeCallAssistant extends CallAssistant {
  final List<String> dialedNumbers = [];

  @override
  Future<CallActionResult> makeCall({
    required String phoneNumber,
    String? contactName,
    bool directCall = false,
  }) async {
    dialedNumbers.add(phoneNumber);
    return CallActionResult.success(message: 'Calling ${contactName ?? phoneNumber}.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileAppRegistry Tests', () {
    test('catalog contains all 8 approved applications', () {
      expect(MobileAppRegistry.approvedApps.length, 8);
      final ids = MobileAppRegistry.approvedApps.map((a) => a.id).toSet();
      expect(ids, containsAll([
        'chrome',
        'youtube',
        'instagram',
        'whatsapp',
        'maps',
        'settings',
        'phone',
        'messages',
      ]));
    });

    test('resolves applications by id and aliases', () {
      expect(MobileAppRegistry.resolveApp('chrome')?.id, 'chrome');
      expect(MobileAppRegistry.resolveApp('google chrome')?.id, 'chrome');
      expect(MobileAppRegistry.resolveApp('browser')?.id, 'chrome');

      expect(MobileAppRegistry.resolveApp('youtube')?.id, 'youtube');
      expect(MobileAppRegistry.resolveApp('yt')?.id, 'youtube');

      expect(MobileAppRegistry.resolveApp('instagram')?.id, 'instagram');
      expect(MobileAppRegistry.resolveApp('insta')?.id, 'instagram');

      expect(MobileAppRegistry.resolveApp('whatsapp')?.id, 'whatsapp');
      expect(MobileAppRegistry.resolveApp('wa')?.id, 'whatsapp');

      expect(MobileAppRegistry.resolveApp('maps')?.id, 'maps');
      expect(MobileAppRegistry.resolveApp('google maps')?.id, 'maps');

      expect(MobileAppRegistry.resolveApp('settings')?.id, 'settings');

      expect(MobileAppRegistry.resolveApp('phone')?.id, 'phone');
      expect(MobileAppRegistry.resolveApp('dialer')?.id, 'phone');

      expect(MobileAppRegistry.resolveApp('messages')?.id, 'messages');
      expect(MobileAppRegistry.resolveApp('sms')?.id, 'messages');
    });

    test('unapproved applications return null', () {
      expect(MobileAppRegistry.resolveApp('spotify'), isNull);
      expect(MobileAppRegistry.resolveApp('netflix'), isNull);
      expect(MobileAppRegistry.resolveApp('slack'), isNull);
      expect(MobileAppRegistry.resolveApp('random_app'), isNull);
    });
  });

  group('MobileAppLaunchEngine Tests', () {
    late _FakeDeviceControlService fakeDeviceService;
    late MobileAppLaunchEngine launchEngine;

    setUp(() {
      fakeDeviceService = _FakeDeviceControlService(
        installedPackages: {
          'com.android.chrome',
          'com.google.android.youtube',
          'com.instagram.android',
          'com.whatsapp',
          'com.google.android.apps.maps',
          'com.android.settings',
          'com.google.android.dialer',
          'com.google.android.apps.messaging',
        },
      );
      launchEngine = MobileAppLaunchEngine(fakeDeviceService);
    });

    test('launches approved installed app', () async {
      final res = await launchEngine.launchApp('chrome');
      expect(res.success, isTrue);
      expect(res.appName, 'Google Chrome');
      expect(fakeDeviceService.openedPackages, contains('com.android.chrome'));
    });

    test('launches settings via openSetting', () async {
      final res = await launchEngine.launchApp('settings');
      expect(res.success, isTrue);
      expect(fakeDeviceService.openedSettings, contains(DeviceSettingType.settings));
    });

    test('returns unapproved for unregistered app query', () async {
      final res = await launchEngine.launchApp('spotify');
      expect(res.success, isFalse);
      expect(res.unapproved, isTrue);
      expect(res.error, 'UNAPPROVED_APP');
      expect(fakeDeviceService.openedPackages, isEmpty);
    });

    test('returns not installed when package is missing from device', () async {
      final emptyDeviceService = _FakeDeviceControlService(installedPackages: {});
      final emptyEngine = MobileAppLaunchEngine(emptyDeviceService);

      final res = await emptyEngine.launchApp('youtube');
      expect(res.success, isFalse);
      expect(res.notInstalled, isTrue);
      expect(res.error, 'NOT_INSTALLED');
      expect(emptyDeviceService.openedPackages, isEmpty);
    });

    test('falls back to alternate package if primary is not installed', () async {
      final fallbackService = _FakeDeviceControlService(
        installedPackages: {'com.android.dialer'}, // Fallback for dialer
      );
      final fallbackEngine = MobileAppLaunchEngine(fallbackService);

      final res = await fallbackEngine.launchApp('phone');
      expect(res.success, isTrue);
      expect(fakeDeviceService.openedPackages, isEmpty);
      expect(fallbackService.openedPackages, contains('com.android.dialer'));
    });

    test('executes browser search deep action', () async {
      final res = await launchEngine.executeAction(
        appId: 'chrome',
        actionType: 'browser.search',
        extraParams: {'query': 'Flutter 3.29 release notes'},
      );
      expect(res.success, isTrue);
      expect(fakeDeviceService.executedActions.length, 1);
      expect(fakeDeviceService.executedActions.first['actionType'], 'browser.search');
    });

    test('executes maps navigation deep action', () async {
      final res = await launchEngine.executeAction(
        appId: 'maps',
        actionType: 'maps.navigate',
        extraParams: {'destination': 'Bangalore Airport'},
      );
      expect(res.success, isTrue);
      expect(fakeDeviceService.executedActions.first['actionType'], 'maps.navigate');
    });

    test('executes youtube search deep action', () async {
      final res = await launchEngine.executeAction(
        appId: 'youtube',
        actionType: 'youtube.search',
        extraParams: {'query': 'lo-fi beats'},
      );
      expect(res.success, isTrue);
      expect(fakeDeviceService.executedActions.first['actionType'], 'youtube.search');
    });

    test('executes whatsapp prepare message deep action', () async {
      final res = await launchEngine.executeAction(
        appId: 'whatsapp',
        actionType: 'whatsapp.prepare_message',
        extraParams: {'contact': 'Rahul', 'message': 'I am on my way'},
      );
      expect(res.success, isTrue);
      expect(fakeDeviceService.executedActions.first['actionType'], 'whatsapp.prepare_message');
    });
  });

  group('UniversalAction Model Tests', () {
    test('creates and serializes UniversalAction correctly', () {
      const action = UniversalAction(
        actionType: 'browser.search',
        target: 'phone',
        app: 'chrome',
        parameters: {'query': 'test query'},
        requiredCapability: 'browser',
        safetyLevel: ActionSafetyLevel.lowRisk,
        confirmationRequired: false,
        state: ActionLifecycleState.parsed,
      );

      expect(action.actionType, 'browser.search');
      expect(action.target, 'phone');
      expect(action.app, 'chrome');
      expect(action.parameters['query'], 'test query');
      expect(action.safetyLevel, ActionSafetyLevel.lowRisk);
      expect(action.state, ActionLifecycleState.parsed);

      final map = action.toMap();
      expect(map['action_type'], 'browser.search');
      expect(map['target'], 'phone');
      expect(map['safety_level'], 'lowRisk');
      expect(map['state'], 'parsed');
    });
  });

  group('VajraCommandRouter App Action Parsing Tests', () {
    test('parses YouTube search command', () {
      final parsed = VajraCommandRouter.parse('Search YouTube for lo-fi hip hop');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'youtube');
      expect(parsed.appAction, 'youtube.search');
      expect(parsed.extraParameters?['query'], 'lo-fi hip hop');
      expect(parsed.universalAction?.actionType, 'youtube.search');
      expect(parsed.universalAction?.safetyLevel, ActionSafetyLevel.lowRisk);
    });

    test('parses Maps navigation command', () {
      final parsed = VajraCommandRouter.parse('Navigate to Bangalore Airport');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'maps');
      expect(parsed.appAction, 'maps.navigate');
      expect(parsed.extraParameters?['destination'], 'Bangalore Airport');
    });

    test('parses Maps directions command', () {
      final parsed = VajraCommandRouter.parse('Directions to Central Station');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'maps');
      expect(parsed.appAction, 'maps.directions');
      expect(parsed.extraParameters?['destination'], 'Central Station');
    });

    test('parses Maps search command', () {
      final parsed = VajraCommandRouter.parse('Search Maps for coffee shops near me');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'maps');
      expect(parsed.appAction, 'maps.search');
      expect(parsed.extraParameters?['query'], 'coffee shops near me');
    });

    test('parses Chrome web search command', () {
      final parsed = VajraCommandRouter.parse('Search the web for quantum computing');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'chrome');
      expect(parsed.appAction, 'browser.search');
      expect(parsed.extraParameters?['query'], 'quantum computing');
    });

    test('parses Chrome URL open command', () {
      final parsed = VajraCommandRouter.parse('Open https://flutter.dev');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'chrome');
      expect(parsed.appAction, 'browser.open_url');
      expect(parsed.extraParameters?['url'], 'https://flutter.dev');
    });

    test('parses Instagram profile command', () {
      final parsed = VajraCommandRouter.parse('Open Instagram profile @flutterdev');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'instagram');
      expect(parsed.appAction, 'instagram.profile');
      expect(parsed.extraParameters?['username'], 'flutterdev');
    });

    test('parses WhatsApp chat command', () {
      final parsed = VajraCommandRouter.parse('Open WhatsApp chat with Rahul');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'whatsapp');
      expect(parsed.appAction, 'whatsapp.chat');
      expect(parsed.extraParameters?['contact'], 'Rahul');
    });

    test('parses WhatsApp prepare message command', () {
      final parsed = VajraCommandRouter.parse('Prepare a WhatsApp message to Rahul saying I am on my way');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'whatsapp');
      expect(parsed.appAction, 'whatsapp.prepare_message');
      expect(parsed.extraParameters?['contact'], 'Rahul');
      expect(parsed.extraParameters?['message'], 'I am on my way');
    });

    test('parses app launch with on my phone suffix', () {
      final parsed = VajraCommandRouter.parse('Open Chrome on my phone');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'chrome');
      expect(parsed.appAction, 'app.launch');
    });

    test('parses direct app launch commands for all approved apps', () {
      final apps = ['Chrome', 'YouTube', 'Instagram', 'WhatsApp', 'Maps', 'Settings', 'Phone', 'Messages'];
      for (final app in apps) {
        final parsed = VajraCommandRouter.parse('Open $app');
        expect(parsed.type, anyOf(VajraIntentType.appAction, VajraIntentType.deviceControl),
            reason: 'Failed to parse Open $app');
      }
    });

    test('rejects unapproved app with blocked safety level', () {
      final parsed = VajraCommandRouter.parse('Open Spotify');
      expect(parsed.type, VajraIntentType.appAction);
      expect(parsed.targetApp, 'Spotify');
      expect(parsed.universalAction?.safetyLevel, ActionSafetyLevel.blocked);
      expect(parsed.universalAction?.state, ActionLifecycleState.unsupported);
    });

    test('preserves existing deviceControl flashlight and timer with UniversalAction', () {
      final flash = VajraCommandRouter.parse('Turn on the flashlight');
      expect(flash.type, VajraIntentType.deviceControl);
      expect(flash.actionSubtype, 'flashlight_on');
      expect(flash.universalAction?.actionType, 'device.flashlight');

      final timer = VajraCommandRouter.parse('Set a timer for 10 minutes');
      expect(timer.type, VajraIntentType.deviceControl);
      expect(timer.actionSubtype, 'timer');
      expect(timer.universalAction?.actionType, 'device.timer');
    });
  });

  group('ActionEngine App Action Execution Tests', () {
    late _FakeDeviceControlService fakeDeviceService;
    late MobileAppLaunchEngine launchEngine;
    late ActionEngine actionEngine;

    setUp(() {
      fakeDeviceService = _FakeDeviceControlService(
        installedPackages: {'com.android.chrome', 'com.google.android.youtube'},
      );
      launchEngine = MobileAppLaunchEngine(fakeDeviceService);
      actionEngine = ActionEngine(
        deviceControlService: fakeDeviceService,
        mobileAppLaunchEngine: launchEngine,
      );
    });

    test('executes approved app launch via ActionEngine', () async {
      final parsed = VajraCommandRouter.parse('Open Chrome');
      final result = await actionEngine.executeParsedCommand(parsed);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains('Opening Google Chrome'));
      expect(fakeDeviceService.openedPackages, contains('com.android.chrome'));
    });

    test('blocks unapproved app launch via ActionEngine without faking', () async {
      final parsed = VajraCommandRouter.parse('Open Spotify');
      final result = await actionEngine.executeParsedCommand(parsed);

      expect(result.isFailure, isTrue);
      expect(result.message, contains("isn't currently available through VAJRA"));
      expect(result.errorCode, 'UNAPPROVED_APP');
      expect(fakeDeviceService.openedPackages, isEmpty);
    });
  });

  group('All 19 Target Scenarios End-to-End Verification', () {
    late _FakeDeviceControlService fakeDevice;
    late MobileAppLaunchEngine launchEngine;
    late ActionEngine engine;

    setUp(() {
      fakeDevice = _FakeDeviceControlService(
        installedPackages: {
          'com.android.chrome',
          'com.google.android.youtube',
          'com.instagram.android',
          'com.whatsapp',
          'com.google.android.apps.maps',
          'com.android.settings',
          'com.google.android.dialer',
          'com.google.android.apps.messaging',
        },
      );
      launchEngine = MobileAppLaunchEngine(fakeDevice);
      engine = ActionEngine(
        deviceControlService: fakeDevice,
        mobileAppLaunchEngine: launchEngine,
      );
    });

    // 1. Open Chrome on my phone
    test('Scenario 1: Open Chrome on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open Chrome on my phone');
      expect(parsed.targetApp, 'chrome');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedPackages, contains('com.android.chrome'));
    });

    // 2. Open YouTube on my phone
    test('Scenario 2: Open YouTube on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open YouTube on my phone');
      expect(parsed.targetApp, 'youtube');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedPackages, contains('com.google.android.youtube'));
    });

    // 3. Open WhatsApp on my phone
    test('Scenario 3: Open WhatsApp on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open WhatsApp on my phone');
      expect(parsed.targetApp, 'whatsapp');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedPackages, contains('com.whatsapp'));
    });

    // 4. Open Instagram on my phone
    test('Scenario 4: Open Instagram on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open Instagram on my phone');
      expect(parsed.targetApp, 'instagram');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedPackages, contains('com.instagram.android'));
    });

    // 5. Open Maps on my phone
    test('Scenario 5: Open Maps on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open Maps on my phone');
      expect(parsed.targetApp, 'maps');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedPackages, contains('com.google.android.apps.maps'));
    });

    // 6. Open Settings on my phone
    test('Scenario 6: Open Settings on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open Settings on my phone');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedSettings, contains(DeviceSettingType.settings));
    });

    // 7. Open Phone on my phone
    test('Scenario 7: Open Phone on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open Phone on my phone');
      expect(parsed.targetApp, 'phone');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedPackages, contains('com.google.android.dialer'));
    });

    // 8. Open Messages on my phone
    test('Scenario 8: Open Messages on my phone', () async {
      final parsed = VajraCommandRouter.parse('Open Messages on my phone');
      expect(parsed.targetApp, 'messages');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedPackages, contains('com.google.android.apps.messaging'));
    });

    // 9. Search YouTube for lo-fi beats
    test('Scenario 9: Search YouTube for lo-fi beats', () async {
      final parsed = VajraCommandRouter.parse('Search YouTube for lo-fi beats');
      expect(parsed.appAction, 'youtube.search');
      expect(parsed.extraParameters?['query'], 'lo-fi beats');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'youtube.search' && a['extraParams']['query'] == 'lo-fi beats'), isTrue);
    });

    // 10. Navigate to Bangalore Airport
    test('Scenario 10: Navigate to Bangalore Airport', () async {
      final parsed = VajraCommandRouter.parse('Navigate to Bangalore Airport');
      expect(parsed.appAction, 'maps.navigate');
      expect(parsed.extraParameters?['destination'], 'Bangalore Airport');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'maps.navigate' && a['extraParams']['destination'] == 'Bangalore Airport'), isTrue);
    });

    // 11. Search Maps for coffee shops near me
    test('Scenario 11: Search Maps for coffee shops near me', () async {
      final parsed = VajraCommandRouter.parse('Search Maps for coffee shops near me');
      expect(parsed.appAction, 'maps.search');
      expect(parsed.extraParameters?['query'], 'coffee shops near me');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'maps.search' && a['extraParams']['query'] == 'coffee shops near me'), isTrue);
    });

    // 12. Search the web for Flutter 3.29 release notes
    test('Scenario 12: Search the web for Flutter 3.29 release notes', () async {
      final parsed = VajraCommandRouter.parse('Search the web for Flutter 3.29 release notes');
      expect(parsed.appAction, 'browser.search');
      expect(parsed.extraParameters?['query'], 'Flutter 3.29 release notes');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'browser.search' && a['extraParams']['query'] == 'Flutter 3.29 release notes'), isTrue);
    });

    // 13. Open https://flutter.dev
    test('Scenario 13: Open https://flutter.dev', () async {
      final parsed = VajraCommandRouter.parse('Open https://flutter.dev');
      expect(parsed.appAction, 'browser.open_url');
      expect(parsed.extraParameters?['url'], 'https://flutter.dev');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'browser.open_url' && a['extraParams']['url'] == 'https://flutter.dev'), isTrue);
    });

    // 14. Open Instagram profile @flutterdev
    test('Scenario 14: Open Instagram profile @flutterdev', () async {
      final parsed = VajraCommandRouter.parse('Open Instagram profile @flutterdev');
      expect(parsed.appAction, 'instagram.profile');
      expect(parsed.extraParameters?['username'], 'flutterdev');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'instagram.profile' && a['extraParams']['username'] == 'flutterdev'), isTrue);
    });

    // 15. Open WhatsApp chat with 9876543210
    test('Scenario 15: Open WhatsApp chat with 9876543210', () async {
      final parsed = VajraCommandRouter.parse('Open WhatsApp chat with 9876543210');
      expect(parsed.appAction, 'whatsapp.chat');
      expect(parsed.extraParameters?['contact'], '9876543210');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'whatsapp.chat' && a['extraParams']['contact'] == '9876543210'), isTrue);
    });

    // 16. Prepare a WhatsApp message to Rahul saying I am on my way
    test('Scenario 16: Prepare a WhatsApp message to Rahul saying I am on my way', () async {
      final parsed = VajraCommandRouter.parse('Prepare a WhatsApp message to Rahul saying I am on my way');
      expect(parsed.appAction, 'whatsapp.prepare_message');
      expect(parsed.extraParameters?['contact'], 'Rahul');
      expect(parsed.extraParameters?['message'], 'I am on my way');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isNeedsConfirmation, isTrue);
      expect(engine.state.pendingAction?.actionType, 'whatsapp.prepare_message');

      // Confirmation step
      final confirmCmd = VajraCommandRouter.parse('Confirm');
      final confirmRes = await engine.executeParsedCommand(confirmCmd);
      expect(confirmRes.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'whatsapp.prepare_message' && a['extraParams']['contact'] == 'Rahul' && a['extraParams']['message'] == 'I am on my way'), isTrue);
    });

    // 17. Open Spotify (unapproved rejection)
    test('Scenario 17: Open Spotify (unapproved rejection)', () async {
      final parsed = VajraCommandRouter.parse('Open Spotify');
      expect(parsed.targetApp, 'Spotify');
      expect(parsed.universalAction?.safetyLevel, ActionSafetyLevel.blocked);
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isFailure, isTrue);
      expect(res.errorCode, 'UNAPPROVED_APP');
      expect(fakeDevice.openedPackages, isEmpty);
    });

    // 18. Turn on the flashlight on my phone
    test('Scenario 18: Turn on the flashlight on my phone', () async {
      final parsed = VajraCommandRouter.parse('Turn on the flashlight on my phone');
      expect(parsed.type, VajraIntentType.deviceControl);
      expect(parsed.actionSubtype, 'flashlight_on');
    });

    // 19. Turn off the flashlight on my phone
    test('Scenario 19: Turn off the flashlight on my phone', () async {
      final parsed = VajraCommandRouter.parse('Turn off the flashlight on my phone');
      expect(parsed.type, VajraIntentType.deviceControl);
      expect(parsed.actionSubtype, 'flashlight_off');
    });
  });

  group('App Action Engine 2.0 Expanded Tests', () {
    late _FakeDeviceControlService fakeDevice;
    late _FakeCallAssistant fakeCallAssistant;
    late MobileAppLaunchEngine launchEngine;
    late ActionEngine engine;

    setUp(() {
      fakeDevice = _FakeDeviceControlService(
        installedPackages: {
          'com.android.chrome',
          'com.google.android.youtube',
          'com.instagram.android',
          'com.whatsapp',
          'com.google.android.apps.maps',
          'com.android.settings',
          'com.google.android.dialer',
          'com.google.android.apps.messaging',
        },
      );
      fakeCallAssistant = _FakeCallAssistant();
      launchEngine = MobileAppLaunchEngine(fakeDevice);
      engine = ActionEngine(
        deviceControlService: fakeDevice,
        mobileAppLaunchEngine: launchEngine,
        callAssistant: fakeCallAssistant,
      );
    });

    test('parses and executes YouTube video and channel actions', () async {
      final videoParsed = VajraCommandRouter.parse('Open this YouTube video');
      expect(videoParsed.appAction, 'youtube.open_video');
      final videoRes = await engine.executeParsedCommand(videoParsed);
      expect(videoRes.isSuccess, isTrue);

      final channelParsed = VajraCommandRouter.parse('Open YouTube channel Fireship');
      expect(channelParsed.appAction, 'youtube.open_channel');
      expect(channelParsed.extraParameters?['channel'], 'Fireship');
      final channelRes = await engine.executeParsedCommand(channelParsed);
      expect(channelRes.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'youtube.open_channel' && a['uriString'] == 'https://www.youtube.com/@Fireship'), isTrue);
    });

    test('parses and separates Maps directions and navigation', () async {
      final dirParsed = VajraCommandRouter.parse('Directions to Indiranagar');
      expect(dirParsed.appAction, 'maps.directions');
      final dirRes = await engine.executeParsedCommand(dirParsed);
      expect(dirRes.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'maps.directions' && a['uriString'].contains('destination=Indiranagar')), isTrue);

      final navParsed = VajraCommandRouter.parse('Navigate to Indiranagar');
      expect(navParsed.appAction, 'maps.navigate');
      final navRes = await engine.executeParsedCommand(navParsed);
      expect(navRes.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'maps.navigate' && a['uriString'].contains('google.navigation:q=Indiranagar')), isTrue);
    });

    test('parses and executes Instagram post and reel, blocks spam', () async {
      final postParsed = VajraCommandRouter.parse('Open Instagram post ABC123XYZ');
      expect(postParsed.appAction, 'instagram.post');
      final postRes = await engine.executeParsedCommand(postParsed);
      expect(postRes.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'instagram.post' && a['uriString'] == 'https://www.instagram.com/p/ABC123XYZ'), isTrue);

      final reelParsed = VajraCommandRouter.parse('Open Instagram reel REEL999');
      expect(reelParsed.appAction, 'instagram.reel');
      final reelRes = await engine.executeParsedCommand(reelParsed);
      expect(reelRes.isSuccess, isTrue);
      expect(fakeDevice.executedActions.any((a) => a['actionType'] == 'instagram.reel' && a['uriString'] == 'https://www.instagram.com/reel/REEL999'), isTrue);

      final spamParsed = VajraCommandRouter.parse('Send mass DMs on Instagram');
      expect(spamParsed.universalAction?.safetyLevel, ActionSafetyLevel.blocked);
      final spamRes = await engine.executeParsedCommand(spamParsed);
      expect(spamRes.isFailure, isTrue);
      expect(spamRes.errorCode, 'UNAPPROVED_APP');
    });

    test('handles WhatsApp cancellation cleanly', () async {
      final parsed = VajraCommandRouter.parse('Prepare a WhatsApp message to Alex saying Hello');
      final res = await engine.executeParsedCommand(parsed);
      expect(res.isNeedsConfirmation, isTrue);

      final cancelCmd = VajraCommandRouter.parse('Cancel');
      final cancelRes = await engine.executeParsedCommand(cancelCmd);
      expect(cancelRes.isSuccess, isTrue);
      expect(cancelRes.message, 'Action cancelled.');
      expect(engine.state.pendingAction, isNull);
    });

    test('handles Phone 3-stage calling flow with confirmation and execution', () async {
      final callCmd = VajraCommandRouter.parse('Call 9876543210');
      expect(callCmd.type, VajraIntentType.call);
      final callRes = await engine.executeParsedCommand(callCmd);
      expect(callRes.isNeedsConfirmation, isTrue);
      expect(engine.state.pendingAction?.actionType, 'call.make');

      final confirmCmd = VajraCommandRouter.parse('Send it');
      final confirmRes = await engine.executeParsedCommand(confirmCmd);
      expect(confirmRes.isSuccess, isTrue);
      expect(engine.state.pendingAction, isNull);
    });

    test('handles volume up and volume down controls', () async {
      final upCmd = VajraCommandRouter.parse('Turn the volume up');
      expect(upCmd.type, VajraIntentType.deviceControl);
      expect(upCmd.actionSubtype, 'volume_up');
      final upRes = await engine.executeParsedCommand(upCmd);
      expect(upRes.isSuccess, isTrue);
      expect(fakeDevice.volumeAdjustments, contains(true));

      final downCmd = VajraCommandRouter.parse('Volume down');
      expect(downCmd.type, VajraIntentType.deviceControl);
      expect(downCmd.actionSubtype, 'volume_down');
      final downRes = await engine.executeParsedCommand(downCmd);
      expect(downRes.isSuccess, isTrue);
      expect(fakeDevice.volumeAdjustments, contains(false));
    });

    test('handles timer cancellation', () async {
      final cancelTimerCmd = VajraCommandRouter.parse('Cancel my timer');
      expect(cancelTimerCmd.type, VajraIntentType.deviceControl);
      expect(cancelTimerCmd.actionSubtype, 'timer_cancel');
      final cancelRes = await engine.executeParsedCommand(cancelTimerCmd);
      expect(cancelRes.isSuccess, isTrue);
      expect(fakeDevice.timerCancelled, isTrue);
    });

    test('opens VAJRA app settings', () async {
      final vajraSettingsCmd = VajraCommandRouter.parse('Open VAJRA app settings');
      expect(vajraSettingsCmd.type, VajraIntentType.deviceControl);
      expect(vajraSettingsCmd.actionSubtype, 'settings_vajraApp');
      final res = await engine.executeParsedCommand(vajraSettingsCmd);
      expect(res.isSuccess, isTrue);
      expect(fakeDevice.openedSettings, contains(DeviceSettingType.vajraApp));
    });
  });
}

import '../../assistant/mobile_app_registry.dart';
import 'universal_action_model.dart';

enum VajraIntentType {
  task,
  calendar,
  assignment,
  subject,
  studySession,
  reminder,
  saveMemory,
  recallMemory,
  planning,
  call,
  message,
  deviceControl,
  notificationQuery,
  appAction,
  actionConfirm,
  actionCancel,
  information,
}

class VajraParsedCommand {
  final VajraIntentType type;
  final String title;
  final String? description;
  final DateTime? dateTime;
  final DateTime? endDateTime;
  final Duration? duration;
  final bool isRecurring;
  final String? subject;
  final String? priority;
  final String? contactName;
  final String? phoneNumber;
  final String? actionSubtype;
  final int? timerSeconds;
  final String? messageBody;
  final String originalInput;
  final String? targetApp;
  final String? appAction;
  final Map<String, dynamic>? extraParameters;
  final UniversalAction? universalAction;

  const VajraParsedCommand({
    required this.type,
    required this.title,
    this.description,
    this.dateTime,
    this.endDateTime,
    this.duration,
    this.isRecurring = false,
    this.subject,
    this.priority,
    this.contactName,
    this.phoneNumber,
    this.actionSubtype,
    this.timerSeconds,
    this.messageBody,
    required this.originalInput,
    this.targetApp,
    this.appAction,
    this.extraParameters,
    this.universalAction,
  });
}

class VajraCommandRouter {
  static final RegExp _taskKeywords = RegExp(
    r'\b(create|add|new|make)\s+(a\s+)?(daily\s+|weekly\s+|recurring\s+)?task\b|\b(task|todo|to-do):\s*|\b(add to tasks|put on my task list)\b',
    caseSensitive: false,
  );

  static final RegExp _studySessionKeywords = RegExp(
    r'\b(schedule|plan|start|set up|create|add)\s+(a\s+|my\s+)?study\s+session\b|\bstudy\s+session\b',
    caseSensitive: false,
  );

  static final RegExp _calendarKeywords = RegExp(
    r'\b(schedule|book|create|add)\s+(a\s+)?(meeting|event|call|appointment)\b|\badd\s+to\s+calendar\b|\bcalendar:\s*',
    caseSensitive: false,
  );

  static final RegExp _assignmentKeywords = RegExp(
    r'\b(add|create|new)\s+(an?\s+)?([a-zA-Z]+\s+)?(assignment|homework|project|submission)\b|\bassignment:\s*',
    caseSensitive: false,
  );

  static final RegExp _subjectKeywords = RegExp(
    r'\b(add|create|new)\s+(a\s+)?subject\b|\bsubject:\s*',
    caseSensitive: false,
  );

  static final RegExp _reminderKeywords = RegExp(
    r'\b(remind me to|set (a )?reminder|reminder to|alert me to)\b|\breminder:\s*',
    caseSensitive: false,
  );

  static final RegExp _saveMemoryKeywords = RegExp(
    r'\b(remember that|remember my|don\x27t forget that|keep in mind that|note down that|note that|save\s+(?:this\s+.*?\s+)?to\s+(?:my\s+)?memory:?|save\s+memory:?)\b',
    caseSensitive: false,
  );

  static final RegExp _recallMemoryKeywords = RegExp(
    r'\b(what is my|what was my|what are my|do you remember my|recall my|tell me my)\b',
    caseSensitive: false,
  );

  static final RegExp _planningKeywords = RegExp(
    r'\b(plan my day|what(\x27s| is) (on )?my (schedule|agenda|plan)|what do i have\s+(planned|scheduled)?\s*(for)?\s*(today|tomorrow)|show my agenda|list my tasks for today)\b',
    caseSensitive: false,
  );

  static final RegExp _flashlightKeywords = RegExp(
    r'\b(?:turn\s+(on|off)\s+(?:the\s+)?(?:flashlight|torch)|(?:flashlight|torch)\s+(on|off))\b',
    caseSensitive: false,
  );

  static final RegExp _timerKeywords = RegExp(
    r'\b(?:set|start)\s+(?:a\s+)?timer\s+(?:for\s+)?(\d+)\s*(seconds?|secs?|minutes?|mins?|hours?|hrs?)\b',
    caseSensitive: false,
  );

  static final RegExp _settingsKeywords = RegExp(
    r'\b(?:open|show|go to)\s+(wifi|wi-fi|bluetooth|sound|volume|display|battery|notifications?|settings|app settings)\b',
    caseSensitive: false,
  );

  static final RegExp _mediaKeywords = RegExp(
    r'\b(?:pause|resume|play|stop|next|skip|previous)\s+(?:music|song|track|media|playback)\b',
    caseSensitive: false,
  );

  static final RegExp _notificationKeywords = RegExp(
    r'\b(?:what did i miss|read (?:my\s+)?notifications?|(?:any|check|summarize)\s+(?:new\s+)?notifications?|notification summary)\b',
    caseSensitive: false,
  );

  static final RegExp _callKeywords = RegExp(
    r'^(?:please\s+)?(?:call|dial|phone|make a call to)\s+([^,]+)$',
    caseSensitive: false,
  );

  static final RegExp _messageKeywords = RegExp(
    r'^(?:please\s+)?(?:send\s+(?:a\s+)?(?:text|sms|message)\s+to|(?:text|message))\s+([^:,]+?)(?:\s+(?:that|saying|with message)?\s*[:,-]?\s*(.+))?$',
    caseSensitive: false,
  );

  // App Action Keywords & Regexes
  static final RegExp _youtubeSearchRegex = RegExp(
    r'^(?:please\s+)?(?:search\s+(?:on\s+)?youtube\s+for\s+(.+)|search\s+for\s+(.+?)\s+on\s+youtube|find\s+(.+?)\s+on\s+youtube|look\s+up\s+(.+?)\s+on\s+youtube|play\s+(.+?)\s+on\s+youtube|watch\s+(.+?)\s+on\s+youtube)$',
    caseSensitive: false,
  );

  static final RegExp _youtubeVideoRegex = RegExp(
    r'^(?:please\s+)?(?:open|watch|play)\s+youtube\s+video(?:\s+(.+))?$|^open\s+this\s+youtube\s+video$',
    caseSensitive: false,
  );

  static final RegExp _youtubeChannelRegex = RegExp(
    r'^(?:please\s+)?(?:open\s+(?:this\s+)?youtube\s+channel(?:\s+(.+))?|open\s+channel\s+(.+?)\s+on\s+youtube)$|^open\s+this\s+youtube\s+channel$',
    caseSensitive: false,
  );

  static final RegExp _mapsDirectionsRegex = RegExp(
    r'^(?:please\s+)?(?:show\s+directions\s+to|directions\s+to|get\s+directions\s+to|how\s+to\s+get\s+to)\s+(.+)$',
    caseSensitive: false,
  );

  static final RegExp _mapsNavigateRegex = RegExp(
    r'^(?:please\s+)?(?:navigate\s+to|take\s+me\s+to|drive\s+to|start\s+navigation\s+to)\s+(.+)$',
    caseSensitive: false,
  );

  static final RegExp _mapsSearchRegex = RegExp(
    r'^(?:please\s+)?(?:search\s+(?:on\s+)?(?:google\s+)?maps\s+for\s+(.+)|search\s+for\s+(.+?)\s+on\s+(?:google\s+)?maps|find\s+(.+?)\s+on\s+(?:google\s+)?maps|look\s+up\s+(.+?)\s+on\s+(?:google\s+)?maps|locate\s+(.+?)\s+on\s+(?:google\s+)?maps|find\s+(cafes|restaurants|hotels|coffee\s+shops|gas\s+stations|food|places)\s+near\s+me|search\s+(cafes|restaurants|hotels|coffee\s+shops|gas\s+stations)\s+near\s+me)$',
    caseSensitive: false,
  );

  static final RegExp _browserSearchRegex = RegExp(
    r'^(?:please\s+)?(?:search\s+the\s+web\s+for\s+(.+)|search\s+google\s+for\s+(.+)|search\s+chrome\s+for\s+(.+)|search\s+for\s+(.+?)\s+on\s+chrome|look\s+up\s+(.+?)\s+on\s+chrome|google\s+(.+))$',
    caseSensitive: false,
  );

  static final RegExp _browserUrlRegex = RegExp(
    r'^(?:please\s+)?(?:open\s+(?:url|website|link)\s+|open\s+)?(https?://[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*)$',
    caseSensitive: false,
  );

  static final RegExp _instagramProfileRegex = RegExp(
    r'^(?:please\s+)?(?:open\s+instagram\s+profile\s+@?([a-zA-Z0-9._]+)|open\s+@([a-zA-Z0-9._]+)\s+on\s+instagram|view\s+instagram\s+profile\s+@?([a-zA-Z0-9._]+))$|^open\s+this\s+instagram\s+profile$',
    caseSensitive: false,
  );

  static final RegExp _instagramPostRegex = RegExp(
    r'^(?:please\s+)?(?:open\s+(?:this\s+)?instagram\s+post(?:\s+([^\s]+))?|open\s+post\s+([^\s]+)\s+on\s+instagram)$|^open\s+this\s+instagram\s+post$',
    caseSensitive: false,
  );

  static final RegExp _instagramReelRegex = RegExp(
    r'^(?:please\s+)?(?:open\s+(?:this\s+)?instagram\s+reel(?:\s+([^\s]+))?|open\s+reel\s+([^\s]+)\s+on\s+instagram)$|^open\s+this\s+instagram\s+reel$',
    caseSensitive: false,
  );

  static final RegExp _instagramUrlRegex = RegExp(
    r'^(?:please\s+)?(?:open\s+instagram\s+(?:post\s+|reel\s+)?)(https?://(?:www\.)?instagram\.com/[^\s]+)$',
    caseSensitive: false,
  );

  static final RegExp _whatsappChatRegex = RegExp(
    r'^(?:please\s+)?(?:open\s+whatsapp\s+chat\s+with\s+(.+)|chat\s+with\s+(.+?)\s+on\s+whatsapp)$',
    caseSensitive: false,
  );

  static final RegExp _whatsappMessageRegex = RegExp(
    r'^(?:please\s+)?(?:send\s+(?:a\s+)?whatsapp\s+message\s+to|prepare\s+(?:a\s+)?whatsapp\s+message\s+to|whatsapp|message\s+(?:.+?)\s+on\s+whatsapp)\s+([^:,]+?)(?:\s+(?:that|saying|with message)?\s*[:,-]?\s*(.+))?$',
    caseSensitive: false,
  );

  static final RegExp _timerCancelRegex = RegExp(
    r'^(?:please\s+)?(?:cancel\s+(?:my\s+|the\s+)?timer|stop\s+(?:the\s+)?timer|dismiss\s+(?:the\s+)?timer|turn\s+off\s+(?:the\s+)?timer)$',
    caseSensitive: false,
  );

  static final RegExp _volumeUpRegex = RegExp(
    r'^(?:please\s+)?(?:turn\s+(?:the\s+)?volume\s+up|volume\s+up|louder|turn\s+up\s+(?:the\s+)?volume|increase\s+(?:the\s+)?volume)$',
    caseSensitive: false,
  );

  static final RegExp _volumeDownRegex = RegExp(
    r'^(?:please\s+)?(?:turn\s+(?:the\s+)?volume\s+down|volume\s+down|quieter|turn\s+down\s+(?:the\s+)?volume|decrease\s+(?:the\s+)?volume|lower\s+(?:the\s+)?volume)$',
    caseSensitive: false,
  );

  static final RegExp _confirmRegex = RegExp(
    r'^(?:yes|yep|yeah|confirm|send\s+it|send|proceed|do\s+it|call|place\s+call)$',
    caseSensitive: false,
  );

  static final RegExp _cancelRegex = RegExp(
    r'^(?:no|nope|cancel|don\x27t\s+send|do\s+not\s+send|stop|dismiss|never\s*mind|abort)$',
    caseSensitive: false,
  );

  static final RegExp _appLaunchRegex = RegExp(
    r'^(?:please\s+)?(?:open|launch|start)\s+([a-zA-Z0-9\s._-]+?)(?:\s+on\s+(?:my\s+)?phone)?$',
    caseSensitive: false,
  );

  static String _stripDeviceSuffix(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.endsWith(' on my phone')) {
      return text.trim().substring(0, text.trim().length - 12).trim();
    }
    if (lower.endsWith(' on the phone')) {
      return text.trim().substring(0, text.trim().length - 13).trim();
    }
    if (lower.endsWith(' on phone')) {
      return text.trim().substring(0, text.trim().length - 9).trim();
    }
    return text.trim();
  }

  /// Analyzes input text and classifies it into a parsed command.
  static VajraParsedCommand parse(String input) {
    final trimmed = input.trim();
    final stripped = _stripDeviceSuffix(trimmed);
    final lower = stripped.toLowerCase();

    // 0a. Explicit Confirmation intent ("Yes", "Confirm", "Send it", "Call")
    if (_confirmRegex.hasMatch(lower)) {
      return VajraParsedCommand(
        type: VajraIntentType.actionConfirm,
        title: 'Confirm',
        originalInput: trimmed,
        universalAction: const UniversalAction(
          actionType: 'action.confirm',
          target: 'phone',
          safetyLevel: ActionSafetyLevel.lowRisk,
          state: ActionLifecycleState.ready,
        ),
      );
    }

    // 0b. Explicit Cancellation intent ("No", "Cancel", "Don't send")
    if (_cancelRegex.hasMatch(lower) && !lower.contains('timer')) {
      return VajraParsedCommand(
        type: VajraIntentType.actionCancel,
        title: 'Cancel',
        originalInput: trimmed,
        universalAction: const UniversalAction(
          actionType: 'action.cancel',
          target: 'phone',
          safetyLevel: ActionSafetyLevel.lowRisk,
          state: ActionLifecycleState.cancelled,
        ),
      );
    }

    // 0c. Media Volume Controls ("Turn the volume up", "Volume down")
    if (_volumeUpRegex.hasMatch(lower)) {
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: 'Turn volume up',
        actionSubtype: 'volume_up',
        originalInput: trimmed,
        universalAction: const UniversalAction(
          actionType: 'device.volume_up',
          target: 'phone',
          requiredCapability: 'media',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    if (_volumeDownRegex.hasMatch(lower)) {
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: 'Turn volume down',
        actionSubtype: 'volume_down',
        originalInput: trimmed,
        universalAction: const UniversalAction(
          actionType: 'device.volume_down',
          target: 'phone',
          requiredCapability: 'media',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 0d. Timer Cancel intent ("Cancel my timer", "Stop timer")
    if (_timerCancelRegex.hasMatch(lower)) {
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: 'Cancel timer',
        actionSubtype: 'timer_cancel',
        originalInput: trimmed,
        universalAction: const UniversalAction(
          actionType: 'device.timer_cancel',
          target: 'phone',
          requiredCapability: 'timer',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 1. Planning intent ("Plan my day", "What is on my schedule today")
    if (_planningKeywords.hasMatch(lower)) {
      final isTomorrow = lower.contains('tomorrow');
      final targetDate = isTomorrow ? DateTime.now().add(const Duration(days: 1)) : DateTime.now();
      return VajraParsedCommand(
        type: VajraIntentType.planning,
        title: 'Daily Plan',
        dateTime: targetDate,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'planner.plan_my_day',
          parameters: {'date': targetDate.toIso8601String()},
          requiredCapability: 'planner',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 2. Recall Memory intent ("What is my project deadline?")
    if (_recallMemoryKeywords.hasMatch(lower)) {
      final query = _extractRecallQuery(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.recallMemory,
        title: query,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'memory.search',
          parameters: {'query': query},
          requiredCapability: 'memory',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 3. Save Memory intent ("Remember that my project deadline is Friday")
    if (_saveMemoryKeywords.hasMatch(lower)) {
      final memoryFact = _extractSaveFact(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.saveMemory,
        title: memoryFact,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'memory.save',
          parameters: {'content': memoryFact},
          requiredCapability: 'memory',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 4. Device control: Flashlight
    final flashMatch = _flashlightKeywords.firstMatch(lower);
    if (flashMatch != null) {
      final stateStr = (flashMatch.group(1) ?? flashMatch.group(2) ?? 'on').toLowerCase();
      final isTurnOn = stateStr == 'on';
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: isTurnOn ? 'Turn on flashlight' : 'Turn off flashlight',
        actionSubtype: isTurnOn ? 'flashlight_on' : 'flashlight_off',
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'device.flashlight',
          parameters: {'state': isTurnOn ? 'on' : 'off'},
          requiredCapability: 'flashlight',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 5. Device control: Timer
    final timerMatch = _timerKeywords.firstMatch(lower);
    if (timerMatch != null) {
      final numVal = int.tryParse(timerMatch.group(1) ?? '0') ?? 0;
      final unit = (timerMatch.group(2) ?? 'seconds').toLowerCase();
      int totalSeconds = numVal;
      if (unit.startsWith('min')) {
        totalSeconds = numVal * 60;
      } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
        totalSeconds = numVal * 3600;
      }
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: 'Timer for $numVal $unit',
        actionSubtype: 'timer',
        timerSeconds: totalSeconds,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'device.timer',
          parameters: {'seconds': totalSeconds, 'label': 'Timer for $numVal $unit'},
          requiredCapability: 'timer',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 6. Device control: Settings
    if (lower.contains('vajra') && (lower.contains('setting') || lower.contains('app'))) {
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: 'Open VAJRA app settings',
        actionSubtype: 'settings_vajraApp',
        originalInput: trimmed,
        universalAction: const UniversalAction(
          actionType: 'device.settings',
          parameters: {'setting': 'vajraApp'},
          requiredCapability: 'settings',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 6. Device control: Settings
    final settingsMatch = _settingsKeywords.firstMatch(lower);
    if (settingsMatch != null) {
      final rawSetting = (settingsMatch.group(1) ?? '').toLowerCase().replaceAll('-', '');
      final normalized = rawSetting == 'volume'
          ? 'sound'
          : (rawSetting == 'app settings'
              ? 'app'
              : (rawSetting.startsWith('notification') ? 'notifications' : rawSetting));
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: 'Open ${settingsMatch.group(1)} settings',
        actionSubtype: 'settings_$normalized',
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'device.settings',
          parameters: {'setting': normalized},
          requiredCapability: 'settings',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 7. Device control: Media
    final mediaMatch = _mediaKeywords.firstMatch(lower);
    if (mediaMatch != null) {
      final cmd = lower.split(' ').first;
      return VajraParsedCommand(
        type: VajraIntentType.deviceControl,
        title: 'Media $cmd',
        actionSubtype: 'media_$cmd',
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'device.media',
          parameters: {'command': cmd},
          requiredCapability: 'media',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 8. Notification query ("What did I miss?")
    if (_notificationKeywords.hasMatch(lower)) {
      return VajraParsedCommand(
        type: VajraIntentType.notificationQuery,
        title: 'Notification Summary',
        actionSubtype: 'summary',
        originalInput: trimmed,
        universalAction: const UniversalAction(
          actionType: 'notification.missed_summary',
          parameters: {},
          requiredCapability: 'notifications',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 9. Telephony Call ("Call Mom", "Dial 9876543210")
    if (!_calendarKeywords.hasMatch(lower)) {
      final callMatch = _callKeywords.firstMatch(trimmed);
      if (callMatch != null) {
        final target = callMatch.group(1)?.trim() ?? '';
        if (target.isNotEmpty &&
            !target.toLowerCase().contains('meeting') &&
            !target.toLowerCase().contains('event') &&
            !target.toLowerCase().contains('session')) {
          final isNumber = RegExp(r'^[+\d\s()-]+$').hasMatch(target);
          return VajraParsedCommand(
            type: VajraIntentType.call,
            title: 'Call $target',
            contactName: isNumber ? null : target,
            phoneNumber: isNumber ? target : null,
            originalInput: trimmed,
            universalAction: UniversalAction(
              actionType: 'call.make',
              parameters: {'target': target, if (isNumber) 'phoneNumber': target else 'contactName': target},
              requiredCapability: 'telephony',
              safetyLevel: ActionSafetyLevel.confirmationRequired,
              confirmationRequired: true,
              state: ActionLifecycleState.confirmationRequired,
            ),
          );
        }
      }
    }

    // 10. Messaging / SMS ("Text Alice that I will be late")
    final msgMatch = _messageKeywords.firstMatch(trimmed);
    if (msgMatch != null) {
      final recipient = msgMatch.group(1)?.trim() ?? '';
      final body = msgMatch.group(2)?.trim() ?? '';
      if (recipient.isNotEmpty &&
          !recipient.toLowerCase().startsWith('task') &&
          !recipient.toLowerCase().startsWith('reminder')) {
        final isNumber = RegExp(r'^[+\d\s()-]+$').hasMatch(recipient);
        return VajraParsedCommand(
          type: VajraIntentType.message,
          title: 'Message $recipient',
          contactName: isNumber ? null : recipient,
          phoneNumber: isNumber ? recipient : null,
          messageBody: body,
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'message.prepare_draft',
            parameters: {'recipient': recipient, 'body': body},
            requiredCapability: 'messaging',
            safetyLevel: ActionSafetyLevel.confirmationRequired,
            confirmationRequired: true,
            state: ActionLifecycleState.confirmationRequired,
          ),
        );
      }
    }

    // ==========================================
    // 11. Rich App Actions & Universal Launches
    // ==========================================

    // YouTube Search
    final ytMatch = _youtubeSearchRegex.firstMatch(stripped);
    if (ytMatch != null) {
      final query = (ytMatch.group(1) ?? ytMatch.group(2) ?? ytMatch.group(3) ?? ytMatch.group(4) ?? ytMatch.group(5) ?? ytMatch.group(6) ?? '').trim();
      if (query.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Search YouTube for "$query"',
          targetApp: 'youtube',
          appAction: 'youtube.search',
          extraParameters: {'query': query},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'youtube.search',
            target: 'phone',
            app: 'youtube',
            parameters: {'query': query},
            requiredCapability: 'media',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // YouTube Video
    final ytVideoMatch = _youtubeVideoRegex.firstMatch(stripped);
    if (ytVideoMatch != null) {
      final videoTarget = ytVideoMatch.group(1)?.trim() ?? '';
      return VajraParsedCommand(
        type: VajraIntentType.appAction,
        title: videoTarget.isNotEmpty ? 'Open YouTube video $videoTarget' : 'Open YouTube video',
        targetApp: 'youtube',
        appAction: 'youtube.open_video',
        extraParameters: {'videoId': videoTarget, 'uri': videoTarget},
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'youtube.open_video',
          target: 'phone',
          app: 'youtube',
          parameters: {'videoId': videoTarget},
          requiredCapability: 'media',
          safetyLevel: ActionSafetyLevel.lowRisk,
          confirmationRequired: false,
          executor: 'native_android',
          state: ActionLifecycleState.parsed,
        ),
      );
    }

    // YouTube Channel
    final ytChannelMatch = _youtubeChannelRegex.firstMatch(stripped);
    if (ytChannelMatch != null) {
      final channelTarget = (ytChannelMatch.group(1) ?? ytChannelMatch.group(2) ?? '').trim();
      return VajraParsedCommand(
        type: VajraIntentType.appAction,
        title: channelTarget.isNotEmpty ? 'Open YouTube channel $channelTarget' : 'Open YouTube channel',
        targetApp: 'youtube',
        appAction: 'youtube.open_channel',
        extraParameters: {'channel': channelTarget, 'channelName': channelTarget},
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'youtube.open_channel',
          target: 'phone',
          app: 'youtube',
          parameters: {'channel': channelTarget},
          requiredCapability: 'media',
          safetyLevel: ActionSafetyLevel.lowRisk,
          confirmationRequired: false,
          executor: 'native_android',
          state: ActionLifecycleState.parsed,
        ),
      );
    }

    // Maps Directions
    final mapsDirMatch = _mapsDirectionsRegex.firstMatch(stripped);
    if (mapsDirMatch != null) {
      final dest = mapsDirMatch.group(1)?.trim() ?? '';
      if (dest.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Directions to $dest',
          targetApp: 'maps',
          appAction: 'maps.directions',
          extraParameters: {'destination': dest},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'maps.directions',
            target: 'phone',
            app: 'maps',
            parameters: {'destination': dest},
            requiredCapability: 'navigation',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // Maps Navigate
    final mapsNavMatch = _mapsNavigateRegex.firstMatch(stripped);
    if (mapsNavMatch != null) {
      final dest = mapsNavMatch.group(1)?.trim() ?? '';
      if (dest.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Navigate to $dest',
          targetApp: 'maps',
          appAction: 'maps.navigate',
          extraParameters: {'destination': dest},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'maps.navigate',
            target: 'phone',
            app: 'maps',
            parameters: {'destination': dest},
            requiredCapability: 'navigation',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // Maps Search
    final mapsSearchMatch = _mapsSearchRegex.firstMatch(stripped);
    if (mapsSearchMatch != null) {
      final query = (mapsSearchMatch.group(1) ?? mapsSearchMatch.group(2) ?? mapsSearchMatch.group(3) ?? mapsSearchMatch.group(4) ?? mapsSearchMatch.group(5) ?? '').trim();
      if (query.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Search Maps for "$query"',
          targetApp: 'maps',
          appAction: 'maps.search',
          extraParameters: {'query': query},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'maps.search',
            target: 'phone',
            app: 'maps',
            parameters: {'query': query},
            requiredCapability: 'navigation',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // Browser Search
    final browserSearchMatch = _browserSearchRegex.firstMatch(stripped);
    if (browserSearchMatch != null) {
      final query = (browserSearchMatch.group(1) ?? browserSearchMatch.group(2) ?? browserSearchMatch.group(3) ?? browserSearchMatch.group(4) ?? browserSearchMatch.group(5) ?? browserSearchMatch.group(6) ?? '').trim();
      if (query.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Search the web for "$query"',
          targetApp: 'chrome',
          appAction: 'browser.search',
          extraParameters: {'query': query},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'browser.search',
            target: 'phone',
            app: 'chrome',
            parameters: {'query': query},
            requiredCapability: 'browser',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // Browser URL open
    if (lower.startsWith('open ') || lower.startsWith('http://') || lower.startsWith('https://')) {
      final urlMatch = _browserUrlRegex.firstMatch(stripped);
      if (urlMatch != null) {
        var rawUrl = urlMatch.group(1)?.trim() ?? '';
        if (rawUrl.contains('.') && !rawUrl.contains(' ')) {
          if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
            rawUrl = 'https://$rawUrl';
          }
          return VajraParsedCommand(
            type: VajraIntentType.appAction,
            title: 'Open $rawUrl in Chrome',
            targetApp: 'chrome',
            appAction: 'browser.open_url',
            extraParameters: {'url': rawUrl},
            originalInput: trimmed,
            universalAction: UniversalAction(
              actionType: 'browser.open_url',
              target: 'phone',
              app: 'chrome',
              parameters: {'url': rawUrl},
              requiredCapability: 'browser',
              safetyLevel: ActionSafetyLevel.lowRisk,
              confirmationRequired: false,
              executor: 'native_android',
              state: ActionLifecycleState.parsed,
            ),
          );
        }
      }
    }

    // Instagram Profile
    final instaProfMatch = _instagramProfileRegex.firstMatch(stripped);
    if (instaProfMatch != null) {
      final username = (instaProfMatch.group(1) ?? instaProfMatch.group(2) ?? instaProfMatch.group(3) ?? '').trim();
      if (username.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Open Instagram profile @$username',
          targetApp: 'instagram',
          appAction: 'instagram.profile',
          extraParameters: {'username': username},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'instagram.profile',
            target: 'phone',
            app: 'instagram',
            parameters: {'username': username},
            requiredCapability: 'social',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // Instagram URL
    final instaUrlMatch = _instagramUrlRegex.firstMatch(stripped);
    if (instaUrlMatch != null) {
      final url = instaUrlMatch.group(1)?.trim() ?? '';
      if (url.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Open Instagram post',
          targetApp: 'instagram',
          appAction: 'instagram.open_url',
          extraParameters: {'url': url},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'instagram.open_url',
            target: 'phone',
            app: 'instagram',
            parameters: {'url': url},
            requiredCapability: 'social',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // Instagram Post
    final instaPostMatch = _instagramPostRegex.firstMatch(stripped);
    if (instaPostMatch != null) {
      final postId = (instaPostMatch.group(1) ?? instaPostMatch.group(2) ?? '').trim();
      return VajraParsedCommand(
        type: VajraIntentType.appAction,
        title: postId.isNotEmpty ? 'Open Instagram post $postId' : 'Open Instagram post',
        targetApp: 'instagram',
        appAction: 'instagram.post',
        extraParameters: {'postId': postId},
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'instagram.post',
          target: 'phone',
          app: 'instagram',
          parameters: {'postId': postId},
          requiredCapability: 'social',
          safetyLevel: ActionSafetyLevel.lowRisk,
          confirmationRequired: false,
          executor: 'native_android',
          state: ActionLifecycleState.parsed,
        ),
      );
    }

    // Instagram Reel
    final instaReelMatch = _instagramReelRegex.firstMatch(stripped);
    if (instaReelMatch != null) {
      final reelId = (instaReelMatch.group(1) ?? instaReelMatch.group(2) ?? '').trim();
      return VajraParsedCommand(
        type: VajraIntentType.appAction,
        title: reelId.isNotEmpty ? 'Open Instagram reel $reelId' : 'Open Instagram reel',
        targetApp: 'instagram',
        appAction: 'instagram.reel',
        extraParameters: {'reelId': reelId},
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'instagram.reel',
          target: 'phone',
          app: 'instagram',
          parameters: {'reelId': reelId},
          requiredCapability: 'social',
          safetyLevel: ActionSafetyLevel.lowRisk,
          confirmationRequired: false,
          executor: 'native_android',
          state: ActionLifecycleState.parsed,
        ),
      );
    }

    // Instagram Blocked Actions (spam, mass messaging, automated bot actions)
    if (lower.contains('instagram') || lower.contains('insta')) {
      if (lower.contains('spam') ||
          lower.contains('bulk') ||
          lower.contains('mass dm') ||
          lower.contains('mass message') ||
          lower.contains('auto follow') ||
          lower.contains('auto like') ||
          lower.contains('bot')) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Blocked Instagram Action',
          targetApp: 'instagram',
          appAction: 'instagram.blocked_action',
          originalInput: trimmed,
          universalAction: const UniversalAction(
            actionType: 'instagram.blocked_action',
            target: 'phone',
            app: 'instagram',
            requiredCapability: 'social',
            safetyLevel: ActionSafetyLevel.blocked,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.unsupported,
            errorCode: 'UNSUPPORTED_ACTION',
          ),
        );
      }
    }

    // WhatsApp Message
    final waMsgMatch = _whatsappMessageRegex.firstMatch(stripped);
    if (waMsgMatch != null) {
      final recipient = waMsgMatch.group(1)?.trim() ?? '';
      final body = waMsgMatch.group(2)?.trim() ?? '';
      if (recipient.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Prepare WhatsApp message to $recipient',
          targetApp: 'whatsapp',
          appAction: 'whatsapp.prepare_message',
          extraParameters: {'contact': recipient, 'message': body},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'whatsapp.prepare_message',
            target: 'phone',
            app: 'whatsapp',
            parameters: {'contact': recipient, 'message': body},
            requiredCapability: 'messaging',
            safetyLevel: ActionSafetyLevel.confirmationRequired,
            confirmationRequired: true,
            executor: 'native_android',
            state: ActionLifecycleState.confirmationRequired,
          ),
        );
      }
    }

    // WhatsApp Chat
    final waChatMatch = _whatsappChatRegex.firstMatch(stripped);
    if (waChatMatch != null) {
      final contact = (waChatMatch.group(1) ?? waChatMatch.group(2) ?? '').trim();
      if (contact.isNotEmpty) {
        return VajraParsedCommand(
          type: VajraIntentType.appAction,
          title: 'Open WhatsApp chat with $contact',
          targetApp: 'whatsapp',
          appAction: 'whatsapp.chat',
          extraParameters: {'contact': contact},
          originalInput: trimmed,
          universalAction: UniversalAction(
            actionType: 'whatsapp.chat',
            target: 'phone',
            app: 'whatsapp',
            parameters: {'contact': contact},
            requiredCapability: 'messaging',
            safetyLevel: ActionSafetyLevel.lowRisk,
            confirmationRequired: false,
            executor: 'native_android',
            state: ActionLifecycleState.parsed,
          ),
        );
      }
    }

    // General Application Launch
    final appLaunchMatch = _appLaunchRegex.firstMatch(stripped);
    if (appLaunchMatch != null) {
      final rawAppName = appLaunchMatch.group(1)?.trim() ?? '';
      final lowerApp = rawAppName.toLowerCase();
      if (lowerApp.isNotEmpty &&
          !_settingsKeywords.hasMatch(stripped) &&
          !lowerApp.startsWith('task') &&
          !lowerApp.startsWith('calendar') &&
          !lowerApp.startsWith('reminder') &&
          !lowerApp.startsWith('study')) {
        final appDef = MobileAppRegistry.resolveApp(rawAppName);
        if (appDef != null) {
          return VajraParsedCommand(
            type: VajraIntentType.appAction,
            title: 'Open ${appDef.name}',
            targetApp: appDef.id,
            appAction: 'app.launch',
            extraParameters: {'package': appDef.defaultPackage},
            originalInput: trimmed,
            universalAction: UniversalAction(
              actionType: 'app.launch',
              target: 'phone',
              app: appDef.id,
              parameters: {'package': appDef.defaultPackage},
              requiredCapability: 'app_launch',
              safetyLevel: ActionSafetyLevel.lowRisk,
              confirmationRequired: false,
              executor: 'native_android',
              state: ActionLifecycleState.parsed,
            ),
          );
        } else {
          return VajraParsedCommand(
            type: VajraIntentType.appAction,
            title: 'Open $rawAppName',
            targetApp: rawAppName,
            appAction: 'app.launch',
            originalInput: trimmed,
            universalAction: UniversalAction(
              actionType: 'app.launch',
              target: 'phone',
              app: rawAppName,
              requiredCapability: 'app_launch',
              safetyLevel: ActionSafetyLevel.blocked,
              confirmationRequired: false,
              executor: 'native_android',
              state: ActionLifecycleState.unsupported,
              errorCode: 'UNAPPROVED_APP',
            ),
          );
        }
      }
    }

    // 12. Study Session intent ("Schedule my study session for tonight")
    if (_studySessionKeywords.hasMatch(lower)) {
      final parsedDate = _extractDateTime(lower);
      final subject = _extractSubjectFromText(trimmed);
      final title = subject != null ? '$subject Study Session' : 'Study Session';
      return VajraParsedCommand(
        type: VajraIntentType.studySession,
        title: title,
        subject: subject,
        dateTime: parsedDate ?? _defaultTonightOrFuture(),
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'study.create_session',
          parameters: {'subject': subject, 'date': (parsedDate ?? _defaultTonightOrFuture()).toIso8601String()},
          requiredCapability: 'study',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 13. Reminder intent ("Remind me to study at 7.")
    if (_reminderKeywords.hasMatch(lower)) {
      final parsedDate = _extractDateTime(lower);
      final title = _cleanReminderTitle(trimmed);
      final scheduled = parsedDate ?? DateTime.now().add(const Duration(hours: 1));
      return VajraParsedCommand(
        type: VajraIntentType.reminder,
        title: title,
        dateTime: scheduled,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'notification.create',
          parameters: {'title': title, 'scheduled': scheduled.toIso8601String()},
          requiredCapability: 'notifications',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 14. Task intent ("Create a task to finish my project tomorrow.")
    if (_taskKeywords.hasMatch(lower) || _looksLikeTask(lower)) {
      final parsedDate = _extractDateTime(lower);
      final isRecurring = hasExplicitRecurrence(lower);
      final title = _cleanTaskTitle(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.task,
        title: title,
        dateTime: parsedDate,
        isRecurring: isRecurring,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'planner.create',
          parameters: {'title': title, 'due': parsedDate?.toIso8601String(), 'recurring': isRecurring},
          requiredCapability: 'planner',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 15. Calendar event intent ("Schedule a meeting tomorrow at 4." / "from 4 PM to 5:30 PM")
    if (_calendarKeywords.hasMatch(lower)) {
      final baseDate = _extractBaseDate(lower) ?? DateTime.now();
      final range = _extractTimeRange(lower, baseDate);
      final duration = _extractDuration(lower);
      DateTime start;
      DateTime end;
      Duration finalDuration;

      if (range != null) {
        start = range.$1;
        end = range.$2;
        finalDuration = end.difference(start);
      } else {
        final parsedDate = _extractDateTime(lower);
        start = parsedDate ?? DateTime.now().add(const Duration(hours: 2));
        if (duration != null) {
          finalDuration = duration;
          end = start.add(duration);
        } else {
          finalDuration = const Duration(hours: 1);
          end = start.add(finalDuration);
        }
      }

      final title = _cleanCalendarTitle(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.calendar,
        title: title,
        dateTime: start,
        endDateTime: end,
        duration: finalDuration,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'calendar.create',
          parameters: {'title': title, 'start': start.toIso8601String(), 'end': end.toIso8601String()},
          requiredCapability: 'calendar',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 16. Assignment intent ("Add Physics assignment due Monday.")
    if (_assignmentKeywords.hasMatch(lower)) {
      final parsedDate = _extractDateTime(lower);
      final subject = _extractSubjectFromAssignment(trimmed);
      final title = _cleanAssignmentTitle(trimmed, subject);
      final due = parsedDate ?? DateTime.now().add(const Duration(days: 3));
      return VajraParsedCommand(
        type: VajraIntentType.assignment,
        title: title,
        subject: subject,
        dateTime: due,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'study.create_assignment',
          parameters: {'title': title, 'subject': subject, 'due': due.toIso8601String()},
          requiredCapability: 'study',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 17. Subject intent ("Add Mathematics subject")
    if (_subjectKeywords.hasMatch(lower)) {
      final title = _cleanSubjectTitle(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.subject,
        title: title,
        originalInput: trimmed,
        universalAction: UniversalAction(
          actionType: 'study.create_subject',
          parameters: {'name': title},
          requiredCapability: 'study',
          safetyLevel: ActionSafetyLevel.lowRisk,
        ),
      );
    }

    // 18. Default information / conversational
    return VajraParsedCommand(
      type: VajraIntentType.information,
      title: trimmed,
      originalInput: trimmed,
      universalAction: UniversalAction(
        actionType: 'conversation.respond',
        parameters: {'query': trimmed},
        requiredCapability: 'conversation',
        safetyLevel: ActionSafetyLevel.lowRisk,
      ),
    );
  }

  static DateTime _defaultTonightOrFuture() {
    final now = DateTime.now();
    if (now.hour < 20) {
      return DateTime(now.year, now.month, now.day, 20, 0);
    } else {
      return now.add(const Duration(hours: 1));
    }
  }

  static bool _looksLikeTask(String lower) {
    return lower.startsWith('todo:') ||
        lower.startsWith('task:') ||
        lower.startsWith('need to ') ||
        lower.startsWith('have to ') ||
        lower.startsWith('task due ') ||
        lower.startsWith('task for ') ||
        lower.startsWith('task on ');
  }

  static String _extractRecallQuery(String text) {
    return text
        .replaceAll(RegExp(r'^(what is my|what was my|what are my|do you remember my|recall my|tell me my)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\?+$'), '')
        .trim();
  }

  static String _extractSaveFact(String text) {
    return text
        .replaceAll(RegExp(r'^(remember that|remember my|don\x27t forget that|keep in mind that|note down that|note that|save\s+(?:this\s+.*?\s+)?to\s+(?:my\s+)?memory:?|save\s+memory:?)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(please\s+)', caseSensitive: false), '')
        .trim();
  }

  static String _cleanReminderTitle(String text) {
    var cleaned = text.replaceAll(RegExp(r'^(remind me to|set (a )?reminder to|set (a )?reminder for|reminder:\s*|alert me to)\s*', caseSensitive: false), '');
    cleaned = _stripTimePhrases(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'^[.,;!?\s]+|[.,;!?\s]+$'), '').trim();
    return cleaned.isNotEmpty ? cleaned : 'Reminder';
  }

  static String _cleanCalendarTitle(String text) {
    var cleaned = text.replaceAll(RegExp(r'^(schedule|book|create|add)\s+(a\s+)?(meeting|event|call|session|appointment)(\s+(for|with|about))?\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(add to calendar:\s*)', caseSensitive: false), '');
    cleaned = _stripTimePhrases(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'^[.,;!?\s]+|[.,;!?\s]+$'), '').trim();
    return cleaned.isNotEmpty ? cleaned : 'Meeting';
  }

  static String? _extractSubjectFromAssignment(String text) {
    // Check "Add [Subject] assignment"
    final match = RegExp(r'\b(?:add|create|new)\s+(?:an?\s+)?([a-zA-Z]+)\s+(?:assignment|homework|project)\b', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final candidate = match.group(1)?.trim();
      if (candidate != null &&
          candidate.toLowerCase() != 'new' &&
          candidate.toLowerCase() != 'an' &&
          candidate.toLowerCase() != 'a') {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }

    // Check "assignment for [Subject]"
    final matchFor = RegExp(r'\b(?:assignment|homework)\s+(?:for|in)\s+([a-zA-Z]+)\b', caseSensitive: false).firstMatch(text);
    if (matchFor != null) {
      final candidate = matchFor.group(1)?.trim();
      if (candidate != null) {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }

    return null;
  }

  static String? _extractSubjectFromText(String text) {
    final match = RegExp(r'\b([a-zA-Z]+)\s+study\s+session\b', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final candidate = match.group(1)?.trim();
      if (candidate != null && candidate.toLowerCase() != 'my' && candidate.toLowerCase() != 'a') {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
    return null;
  }

  static String _cleanAssignmentTitle(String text, String? subject) {
    var cleaned = text.replaceAll(RegExp(r'^(add|create|new)\s+(an?\s+)?', caseSensitive: false), '');
    if (subject != null) {
      cleaned = cleaned.replaceAll(RegExp('\\b$subject\\s+', caseSensitive: false), '');
    }
    cleaned = cleaned.replaceAll(RegExp(r'^(assignment|homework|project|submission)(\s+(for|called))?\s*', caseSensitive: false), '');
    cleaned = _stripTimePhrases(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'^[.,;!?\s]+|[.,;!?\s]+$'), '').trim();
    if (cleaned.isEmpty) {
      return subject != null ? '$subject Assignment' : 'Assignment';
    }
    return subject != null ? '$subject $cleaned' : cleaned;
  }

  static String _cleanSubjectTitle(String text) {
    var cleaned = text.replaceAll(RegExp(r'^(add|create|new)\s+(a\s+)?subject(\s+(called|named))?\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(subject:\s*)', caseSensitive: false), '');
    cleaned = _stripTimePhrases(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'^[.,;!?\s]+|[.,;!?\s]+$'), '').trim();
    return cleaned.isNotEmpty ? cleaned : 'New Subject';
  }

  static String _cleanTaskTitle(String text) {
    var cleaned = text.replaceAll(RegExp(r'^(create|add|new|make)\s+(a\s+)?(daily\s+|weekly\s+|recurring\s+)?task(\s+(to|for))?\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(task|todo|to-do):\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(task\s+(due|for|on)\s*)', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^(need to|have to)\s*', caseSensitive: false), '');
    cleaned = _stripTimePhrases(cleaned);
    cleaned = cleaned.replaceAll(RegExp(r'^[.,;!?\s]+|[.,;!?\s]+$'), '').trim();
    return cleaned.isNotEmpty ? cleaned : 'Action Task';
  }

  static bool hasExplicitRecurrence(String text) {
    final lower = text.toLowerCase();
    return RegExp(
      r'\b(every\s+(day|monday|tuesday|wednesday|thursday|friday|saturday|sunday|week|month|morning|evening|night)|daily|weekly|monthly|repeat\s+(daily|weekly|every|monthly))\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static String _stripTimePhrases(String text) {
    return text
        // Strip ranges: "from 4 PM to 5:30 PM", "4 to 5:30 PM", "4:00 PM - 5:30 PM"
        .replaceAll(RegExp(r'\b(?:from\s+)?\d{1,2}(?::\d{2})?\s*(?:am|pm)?\s*(?:to|-)\s*\d{1,2}(?::\d{2})?\s*(?:am|pm)\b', caseSensitive: false), '')
        // Strip durations: "for 1 hour and 30 minutes", "for 45 mins", "for 1.5 hours"
        .replaceAll(RegExp(r'\bfor\s+\d+\s*(?:hours?|hrs?|h)\s*(?:and\s+)?\d+\s*(?:minutes?|mins?|m)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfor\s+(?:\d+(?:\.\d+)?\s*(?:hours?|hrs?|h)|\d+\s*(?:minutes?|mins?|m)|half\s+an\s+hour|an\s+hour)\b', caseSensitive: false), '')
        // Strip month day phrases: "for September 20", "on Sep 20th, 2026", "20th of September"
        .replaceAll(RegExp(r'\b(?:on\s+|for\s+)?(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)\s+\d{1,2}(?:st|nd|rd|th)?(?:\s*,?\s*\d{4})?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(?:on\s+|for\s+)?\d{1,2}(?:st|nd|rd|th)?\s+(?:of\s+)?(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)(?:\s*,?\s*\d{4})?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(?:on\s+|for\s+)?\d{4}-\d{1,2}-\d{1,2}\b', caseSensitive: false), '')
        // Strip single times: "at 4 PM", "4:30 pm"
        .replaceAll(RegExp(r'\b(at\s+\d{1,2}(:\d{2})?\s*(am|pm)?)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{1,2}(:\d{2})?\s*(am|pm)\b', caseSensitive: false), '')
        // Strip relative dates
        .replaceAll(RegExp(r'\b(tomorrow|today|tonight|next monday|next tuesday|next wednesday|next thursday|next friday|next saturday|next sunday)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(due\s+(on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday|tomorrow|today))\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(due\s+next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday))\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+[.,;!?]'), '')
        .replaceAll(RegExp(r'^[.,;!?\s]+|[.,;!?\s]+$'), '')
        .replaceAll(RegExp(r'\s{2,}', caseSensitive: false), ' ')
        .trim();
  }

  static final Map<String, int> _months = {
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  static Duration? _extractDuration(String text) {
    // "for 1 hour and 30 minutes", "for 1 hr and 15 mins"
    final hrMinMatch = RegExp(
      r'\bfor\s+(\d+)\s*(?:hours?|hrs?|h)\s*(?:and\s+)?(\d+)\s*(?:minutes?|mins?|m)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (hrMinMatch != null) {
      final h = int.parse(hrMinMatch.group(1)!);
      final m = int.parse(hrMinMatch.group(2)!);
      return Duration(hours: h, minutes: m);
    }

    // "for 1.5 hours", "for 2 hours", "for 1 hour"
    final hrMatch = RegExp(
      r'\bfor\s+(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (hrMatch != null) {
      final h = double.parse(hrMatch.group(1)!);
      return Duration(minutes: (h * 60).round());
    }

    // "for 15 minutes", "for 30 mins", "for 45 minutes", "for 90 minutes"
    final minMatch = RegExp(
      r'\bfor\s+(\d+)\s*(?:minutes?|mins?|m)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (minMatch != null) {
      final m = int.parse(minMatch.group(1)!);
      return Duration(minutes: m);
    }

    if (RegExp(r'\bfor\s+half\s+an\s+hour\b', caseSensitive: false).hasMatch(text)) {
      return const Duration(minutes: 30);
    }
    if (RegExp(r'\bfor\s+an\s+hour\b', caseSensitive: false).hasMatch(text)) {
      return const Duration(hours: 1);
    }

    return null;
  }

  static int _to24Hour(int hour, String? amPm, {bool isStart = false, String? endAmPm, int? endHour}) {
    if (amPm != null) {
      final lower = amPm.toLowerCase();
      if (lower == 'pm') {
        return hour == 12 ? 12 : hour + 12;
      } else if (lower == 'am') {
        return hour == 12 ? 0 : hour;
      }
    }
    // amPm is null: infer from endAmPm
    if (isStart && endAmPm != null) {
      final lowerEnd = endAmPm.toLowerCase();
      if (lowerEnd == 'pm') {
        if (hour == 12) return 12;
        if (endHour != null && hour <= endHour && hour >= 1 && hour <= 11) {
          return hour + 12;
        }
        if (endHour != null && hour > endHour && hour >= 8 && hour <= 11) {
          return hour;
        }
      }
    }
    if (hour >= 1 && hour <= 7) return hour + 12;
    return hour;
  }

  static (DateTime, DateTime)? _extractTimeRange(String text, DateTime baseDate) {
    final rangeMatch = RegExp(
      r'\b(?:from\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:to|-)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (rangeMatch != null) {
      int startHour = int.parse(rangeMatch.group(1)!);
      int startMin = rangeMatch.group(2) != null ? int.parse(rangeMatch.group(2)!) : 0;
      final startAmPm = rangeMatch.group(3)?.toLowerCase();

      int endHour = int.parse(rangeMatch.group(4)!);
      int endMin = rangeMatch.group(5) != null ? int.parse(rangeMatch.group(5)!) : 0;
      final endAmPm = rangeMatch.group(6)?.toLowerCase();

      int start24 = _to24Hour(startHour, startAmPm, isStart: true, endAmPm: endAmPm, endHour: endHour);
      int end24 = _to24Hour(endHour, endAmPm);

      DateTime startDt = DateTime(baseDate.year, baseDate.month, baseDate.day, start24, startMin);
      DateTime endDt = DateTime(baseDate.year, baseDate.month, baseDate.day, end24, endMin);
      if (endDt.isBefore(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }
      return (startDt, endDt);
    }
    return null;
  }

  static DateTime? _extractBaseDate(String text) {
    final now = DateTime.now();

    // 1. ISO format: 2026-09-20
    final isoMatch = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b').firstMatch(text);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      return DateTime(y, m, d);
    }

    // 2. Pattern: "September 20", "Sep 20", "September 20th", "Sep 20, 2026"
    final mDayMatch = RegExp(
      r'\b(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s*,?\s*(\d{4}))?\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (mDayMatch != null) {
      final m = _months[mDayMatch.group(1)!.toLowerCase()]!;
      final d = int.parse(mDayMatch.group(2)!);
      int y = mDayMatch.group(3) != null ? int.parse(mDayMatch.group(3)!) : now.year;
      if (mDayMatch.group(3) == null) {
        if (m < now.month || (m == now.month && d < now.day)) {
          y = now.year + 1;
        }
      }
      return DateTime(y, m, d);
    }

    // 3. Pattern: "20th of September", "20 September", "20 Sep 2026"
    final dMonthMatch = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)(?:\s*,?\s*(\d{4}))?\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (dMonthMatch != null) {
      final d = int.parse(dMonthMatch.group(1)!);
      final m = _months[dMonthMatch.group(2)!.toLowerCase()]!;
      int y = dMonthMatch.group(3) != null ? int.parse(dMonthMatch.group(3)!) : now.year;
      if (dMonthMatch.group(3) == null) {
        if (m < now.month || (m == now.month && d < now.day)) {
          y = now.year + 1;
        }
      }
      return DateTime(y, m, d);
    }

    if (text.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }
    if (text.contains('tonight') || text.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }

    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (int i = 0; i < days.length; i++) {
      if (text.contains(days[i])) {
        int targetWeekday = i + 1;
        int daysUntil = (targetWeekday - now.weekday + 7) % 7;
        if (daysUntil == 0) daysUntil = 7;
        return DateTime(now.year, now.month, now.day).add(Duration(days: daysUntil));
      }
    }

    return null;
  }

  /// Attempts to parse date and time from user input text.
  static DateTime? _extractDateTime(String text) {
    final now = DateTime.now();
    final baseDate = _extractBaseDate(text);
    final effectiveBase = baseDate ?? DateTime(now.year, now.month, now.day);
    final hasDateMention = baseDate != null;

    // Check for explicit time range first
    final range = _extractTimeRange(text, effectiveBase);
    if (range != null) {
      return range.$1;
    }

    // Check for single time: "at 4", "4 PM", "4:30 pm", "16:00", "at 7"
    final timeMatch = RegExp(r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b', caseSensitive: false).firstMatch(text);
    if (timeMatch != null && (timeMatch.group(3) != null || text.contains('at ') || text.contains('pm') || text.contains('am'))) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      final amPm = timeMatch.group(3)?.toLowerCase();

      int h24 = _to24Hour(hour, amPm);
      if (h24 >= 0 && h24 < 24 && minute >= 0 && minute < 60) {
        return DateTime(effectiveBase.year, effectiveBase.month, effectiveBase.day, h24, minute);
      }
    }

    // Handle "tonight" specifically: default to 8:00 PM (20:00)
    if (text.contains('tonight')) {
      return DateTime(effectiveBase.year, effectiveBase.month, effectiveBase.day, 20, 0);
    }

    // Default time to 9:00 AM on base date if only date was specified
    if (hasDateMention) {
      return DateTime(effectiveBase.year, effectiveBase.month, effectiveBase.day, 9, 0);
    }

    return null;
  }
}

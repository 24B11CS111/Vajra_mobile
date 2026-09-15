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
  final String originalInput;

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
    required this.originalInput,
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

  /// Analyzes input text and classifies it into a parsed command.
  static VajraParsedCommand parse(String input) {
    final trimmed = input.trim();
    final lower = trimmed.toLowerCase();

    // 1. Planning intent ("Plan my day", "What is on my schedule today")
    if (_planningKeywords.hasMatch(lower)) {
      final isTomorrow = lower.contains('tomorrow');
      final targetDate = isTomorrow ? DateTime.now().add(const Duration(days: 1)) : DateTime.now();
      return VajraParsedCommand(
        type: VajraIntentType.planning,
        title: 'Daily Plan',
        dateTime: targetDate,
        originalInput: trimmed,
      );
    }

    // 2. Recall Memory intent ("What is my project deadline?")
    if (_recallMemoryKeywords.hasMatch(lower)) {
      final query = _extractRecallQuery(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.recallMemory,
        title: query,
        originalInput: trimmed,
      );
    }

    // 3. Save Memory intent ("Remember that my project deadline is Friday")
    if (_saveMemoryKeywords.hasMatch(lower)) {
      final memoryFact = _extractSaveFact(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.saveMemory,
        title: memoryFact,
        originalInput: trimmed,
      );
    }

    // 4. Study Session intent ("Schedule my study session for tonight")
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
      );
    }

    // 5. Reminder intent ("Remind me to study at 7.")
    if (_reminderKeywords.hasMatch(lower)) {
      final parsedDate = _extractDateTime(lower);
      final title = _cleanReminderTitle(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.reminder,
        title: title,
        dateTime: parsedDate ?? DateTime.now().add(const Duration(hours: 1)),
        originalInput: trimmed,
      );
    }

    // 6. Task intent ("Create a task to finish my project tomorrow.")
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
      );
    }

    // 7. Calendar event intent ("Schedule a meeting tomorrow at 4." / "from 4 PM to 5:30 PM")
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
      );
    }

    // 8. Assignment intent ("Add Physics assignment due Monday.")
    if (_assignmentKeywords.hasMatch(lower)) {
      final parsedDate = _extractDateTime(lower);
      final subject = _extractSubjectFromAssignment(trimmed);
      final title = _cleanAssignmentTitle(trimmed, subject);
      return VajraParsedCommand(
        type: VajraIntentType.assignment,
        title: title,
        subject: subject,
        dateTime: parsedDate ?? DateTime.now().add(const Duration(days: 3)),
        originalInput: trimmed,
      );
    }

    // 9. Subject intent ("Add Mathematics subject")
    if (_subjectKeywords.hasMatch(lower)) {
      final title = _cleanSubjectTitle(trimmed);
      return VajraParsedCommand(
        type: VajraIntentType.subject,
        title: title,
        originalInput: trimmed,
      );
    }

    // 10. Default information / conversational
    return VajraParsedCommand(
      type: VajraIntentType.information,
      title: trimmed,
      originalInput: trimmed,
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

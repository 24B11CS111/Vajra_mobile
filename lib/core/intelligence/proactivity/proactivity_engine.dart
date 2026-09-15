import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type of proactive trigger outputted by ProactivityEngine.
enum ProactivityType {
  noAction,
  suggestion,
  reminder,
  briefing,
  followUp,
  actionRequest,
}

/// A structured proactive proposal generated for the user.
class ProactivityEvent {
  final String id;
  final ProactivityType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const ProactivityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.payload = const {},
  });
}

/// State for the ProactivityEngine.
class ProactivityState {
  final List<ProactivityEvent> activeEvents;
  final String proactivityLevel; // 'quiet', 'balanced', 'proactive'
  final bool isQuietHours;

  const ProactivityState({
    this.activeEvents = const [],
    this.proactivityLevel = 'balanced',
    this.isQuietHours = false,
  });

  ProactivityState copyWith({
    List<ProactivityEvent>? activeEvents,
    String? proactivityLevel,
    bool? isQuietHours,
  }) {
    return ProactivityState(
      activeEvents: activeEvents ?? this.activeEvents,
      proactivityLevel: proactivityLevel ?? this.proactivityLevel,
      isQuietHours: isQuietHours ?? this.isQuietHours,
    );
  }
}

/// ProactivityEngine analyzes time, tasks, study habits, and deadlines
/// to provide intelligent, non-intrusive proactive assistance.
class ProactivityEngine extends StateNotifier<ProactivityState> {
  ProactivityEngine() : super(const ProactivityState());

  /// Checks if the current time falls into quiet hours (e.g. 23:00 to 07:00).
  bool checkQuietHours(DateTime now) {
    final hour = now.hour;
    return hour >= 23 || hour < 7;
  }

  /// Generates a morning briefing from real task and memory data.
  ProactivityEvent generateMorningBriefing({
    required int pendingTasksCount,
    required String upcomingExam,
  }) {
    return ProactivityEvent(
      id: 'morning_briefing_${DateTime.now().day}',
      type: ProactivityType.briefing,
      title: 'Morning Briefing',
      message: 'You have $pendingTasksCount priorities today. Upcoming milestone: $upcomingExam.',
      timestamp: DateTime.now(),
    );
  }

  /// Generates an evening briefing summarizing daily accomplishment.
  ProactivityEvent generateEveningBriefing({
    required int completedTasksCount,
    required int remainingTasksCount,
  }) {
    return ProactivityEvent(
      id: 'evening_briefing_${DateTime.now().day}',
      type: ProactivityType.briefing,
      title: 'Daily Accomplishment',
      message: 'Great focus! You finished $completedTasksCount tasks today with $remainingTasksCount left.',
      timestamp: DateTime.now(),
    );
  }

  /// Evaluates study schedule and suggests timely starting reminders.
  ProactivityEvent? evaluateStudyReminder(String subject, DateTime scheduledTime) {
    final diff = scheduledTime.difference(DateTime.now()).inMinutes;
    if (diff > 0 && diff <= 15) {
      return ProactivityEvent(
        id: 'study_remind_${subject.toLowerCase()}',
        type: ProactivityType.reminder,
        title: 'Study Session Approaching',
        message: 'Your $subject study block starts in $diff minutes. Ready to begin?',
        timestamp: DateTime.now(),
      );
    }
    return null;
  }
}

/// Provider for ProactivityEngine.
final proactivityEngineProvider = StateNotifierProvider<ProactivityEngine, ProactivityState>((ref) {
  return ProactivityEngine();
});

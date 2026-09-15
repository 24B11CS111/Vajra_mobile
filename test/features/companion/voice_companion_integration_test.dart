import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vajra_mobile/core/integrations/device_calendar_service.dart';
import 'package:vajra_mobile/core/integrations/device_permission_service.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';
import 'package:vajra_mobile/core/intelligence/voice/voice_engine.dart';
import 'package:vajra_mobile/core/network/api_response.dart';
import 'package:vajra_mobile/features/companion/models/stream_event.dart';
import 'package:vajra_mobile/features/companion/presentation/companion_screen.dart';
import 'package:vajra_mobile/features/companion/providers/companion_provider.dart';
import 'package:vajra_mobile/features/companion/services/companion_repository.dart';
import 'package:vajra_mobile/features/memory/models/memory_model.dart';
import 'package:vajra_mobile/features/memory/services/memory_repository.dart';
import 'package:vajra_mobile/features/planner/models/calendar_event_model.dart';
import 'package:vajra_mobile/features/planner/models/planner_model.dart';
import 'package:vajra_mobile/features/planner/services/planner_local_data_source.dart';
import 'package:vajra_mobile/features/planner/services/planner_repository.dart';

class _FakePlannerRepository implements PlannerRepository {
  final List<PlannerTask> tasks = [];
  final List<CalendarEventModel> events = [];

  @override
  Future<ApiResponse<PlannerTask>> createTask(Map<String, dynamic> data) async {
    final task = PlannerTask(
      id: 'task_${tasks.length + 1}',
      title: data['title'] as String,
      category: 'Action',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      isCompleted: false,
    );
    tasks.add(task);
    return ApiResponse.success(task);
  }

  @override
  Future<ApiResponse<CalendarEventModel>> createCalendarEvent(Map<String, dynamic> data) async {
    final event = CalendarEventModel(
      id: 'event_${events.length + 1}',
      userId: 'u1',
      title: data['title'] as String,
      startTime: DateTime.tryParse(data['start_time'].toString()) ?? DateTime.now(),
      eventType: data['event_type']?.toString() ?? 'meeting',
    );
    events.add(event);
    return ApiResponse.success(event);
  }

  @override
  Future<ApiResponse<List<PlannerTask>>> getTasks(DateTime date) async => ApiResponse.success(tasks);

  @override
  Future<ApiResponse<List<CalendarEventModel>>> getCalendarEvents({DateTime? startDate, DateTime? endDate, String? eventType}) async =>
      ApiResponse.success(events);

  @override
  Future<ApiResponse<void>> deleteCalendarEvent(String id) async => ApiResponse.success(null);
  @override
  Future<ApiResponse<void>> deleteTask(String id) async => ApiResponse.success(null);
  @override
  Future<ApiResponse<void>> reorderTasks(List<String> taskIds) async => ApiResponse.success(null);
  @override
  Future<ApiResponse<bool>> toggleTaskCompletion(String id, bool isCompleted) async => ApiResponse.success(true);
  @override
  Future<ApiResponse<CalendarEventModel>> updateCalendarEvent(String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  PlannerLocalDataSource get localDataSource => PlannerLocalDataSourceImpl();
}

class _FakeMemoryRepository implements MemoryRepository {
  final List<MemoryModel> memories = [];

  @override
  Future<ApiResponse<bool>> saveFact(String content, {String category = 'fact'}) async {
    memories.add(MemoryModel(
      id: 'm_${memories.length + 1}',
      content: content,
      category: category,
      importanceScore: 0.8,
      isPinned: false,
      createdAt: DateTime.now(),
      source: 'VoiceTest',
    ));
    return ApiResponse.success(true);
  }

  @override
  Future<ApiResponse<List<MemoryModel>>> getMemories({String? category}) async => ApiResponse.success(memories);
  @override
  Future<ApiResponse<bool>> archiveMemory(String id) async => ApiResponse.success(true);
  @override
  Future<ApiResponse<bool>> deleteMemory(String id) async => ApiResponse.success(true);
  @override
  Future<ApiResponse<String>> exportMemories() async => ApiResponse.success('[]');
  @override
  Future<ApiResponse<bool>> importMemories(String jsonString) async => ApiResponse.success(true);
  @override
  Future<ApiResponse<bool>> syncPinStatus(String id, bool isPinned) async => ApiResponse.success(true);
}

class _FakeDeviceCalendarService extends DeviceCalendarService {
  final List<Map<String, dynamic>> createdEvents = [];

  _FakeDeviceCalendarService(super.permissionService);

  @override
  Future<CalendarActionResult> createCalendarEventDetailed({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? location,
    String? userEmail,
  }) async {
    createdEvents.add({
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
    });
    return CalendarActionResult.success('native_event_123', calendarId: '1');
  }

  @override
  Future<List<DeviceCalendarEvent>> getTodayEvents() async => [];

  @override
  Future<List<DeviceCalendarEvent>> getEventsRange({required DateTime start, required DateTime end}) async => [];
}

class _FakeCompanionRepository implements CompanionRepository {
  @override
  Stream<BackendStreamEvent> processConversation(String sessionId, String userMessage) async* {
    yield BackendStreamEvent(
      eventType: EventType.token,
      payload: {'text': 'I understand: $userMessage'},
    );
    yield BackendStreamEvent(
      eventType: EventType.complete,
      payload: {'text': 'I understand: $userMessage'},
    );
  }

  @override
  void resetActiveConversation() {}
}

class _IntegrationMockVoiceService extends VoiceService {
  final StreamController<VoicePlatformEvent> _controller = StreamController<VoicePlatformEvent>.broadcast();
  bool cancelCalled = false;
  bool startCalled = false;

  @override
  Stream<VoicePlatformEvent> get events => _controller.stream;

  @override
  Future<VoiceAvailability> checkAvailability() async =>
      const VoiceAvailability(available: true, onDeviceAvailable: true);

  @override
  Future<bool> startListening({String? locale}) async {
    startCalled = true;
    return true;
  }

  @override
  Future<bool> stopListening() async => true;

  @override
  Future<bool> cancelListening() async {
    cancelCalled = true;
    return true;
  }

  void emit(VoicePlatformEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

class _IntegrationMockTtsService extends TtsService {
  final StreamController<TtsPlatformEvent> _ttsController = StreamController<TtsPlatformEvent>.broadcast();
  int speakCount = 0;
  int stopCount = 0;
  String? lastSpokenText;

  @override
  Stream<TtsPlatformEvent> get events => _ttsController.stream;

  @override
  Future<TtsAvailability> initialize() async => const TtsAvailability(available: true);

  @override
  Future<TtsAvailability> checkAvailability() async => const TtsAvailability(available: true);

  @override
  Future<bool> speak(String text, {String? utteranceId}) async {
    speakCount++;
    lastSpokenText = text;
    return true;
  }

  @override
  Future<bool> stop() async {
    stopCount++;
    return true;
  }

  void emit(TtsPlatformEvent event) {
    _ttsController.add(event);
  }

  void dispose() {
    _ttsController.close();
  }
}

class _AlwaysGrantedPermissionService extends DevicePermissionService {
  @override
  Future<DevicePermissionState> checkStatus(DevicePermissionType type) async => DevicePermissionState.granted;
  @override
  Future<DevicePermissionState> request(DevicePermissionType type) async => DevicePermissionState.granted;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePlannerRepository fakePlanner;
  late _FakeMemoryRepository fakeMemory;
  late _FakeDeviceCalendarService fakeCalendar;
  late _AlwaysGrantedPermissionService permService;
  late _FakeCompanionRepository fakeCompanionRepo;
  late ActionEngine actionEngine;
  late _IntegrationMockVoiceService mockVoiceService;
  late _IntegrationMockTtsService mockTtsService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakePlanner = _FakePlannerRepository();
    fakeMemory = _FakeMemoryRepository();
    permService = _AlwaysGrantedPermissionService();
    fakeCalendar = _FakeDeviceCalendarService(permService);
    fakeCompanionRepo = _FakeCompanionRepository();

    actionEngine = ActionEngine(
      plannerRepository: fakePlanner,
      memoryRepository: fakeMemory,
      deviceCalendarService: fakeCalendar,
    );

    mockVoiceService = _IntegrationMockVoiceService();
    mockTtsService = _IntegrationMockTtsService();
  });

  tearDown(() {
    mockVoiceService.dispose();
    mockTtsService.dispose();
  });

  group('Voice to Companion Pipeline Integration Tests', () {
    test('1. Recognized speech routes through CompanionNotifier to create a Task', () async {
      final companionNotifier = CompanionNotifier(fakeCompanionRepo, actionEngine);

      const recognizedText = 'Create a task to finish the project.';
      companionNotifier.sendMessage(recognizedText);
      await pumpEventQueue();

      expect(companionNotifier.state.messages.any((m) => m.isUser && m.text == recognizedText), isTrue);
      expect(fakePlanner.tasks.length, 1);
      expect(fakePlanner.tasks.first.title, 'finish the project');

      final lastMsg = companionNotifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text, contains('finish the project'));
    });

    test('2. Recognized speech routes to Calendar action with native device verification', () async {
      final companionNotifier = CompanionNotifier(fakeCompanionRepo, actionEngine);

      const recognizedText = 'Schedule a meeting tomorrow at 4 PM.';
      companionNotifier.sendMessage(recognizedText);
      await pumpEventQueue();

      expect(fakeCalendar.createdEvents.length, 1);
      expect(fakeCalendar.createdEvents.first['title'], 'Meeting');
      expect(fakePlanner.events.length, 1);
      expect(fakePlanner.events.first.title, 'Meeting');

      final lastMsg = companionNotifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text, contains('Done — I\'ve scheduled your meeting'));
    });

    test('3. Recognized speech routes to Memory save with actual vault persistence', () async {
      final companionNotifier = CompanionNotifier(fakeCompanionRepo, actionEngine);

      const recognizedText = 'Save this idea to my memory: build VAJRA into a personal AI companion.';
      companionNotifier.sendMessage(recognizedText);
      await pumpEventQueue();

      expect(fakeMemory.memories.length, 1);
      expect(fakeMemory.memories.first.content, 'build VAJRA into a personal AI companion.');

      final lastMsg = companionNotifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text, contains('build VAJRA into a personal AI companion.'));
    });

    test('4. Recognized speech routes to Planning engine for "What do I have planned tomorrow?"', () async {
      final companionNotifier = CompanionNotifier(fakeCompanionRepo, actionEngine);

      const recognizedText = 'What do I have planned tomorrow?';
      companionNotifier.sendMessage(recognizedText);
      await pumpEventQueue();

      final lastMsg = companionNotifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text.isNotEmpty, isTrue);
    });

    test('5. General conversational speech streams through backend AI pipeline', () async {
      final companionNotifier = CompanionNotifier(fakeCompanionRepo, actionEngine);

      const recognizedText = 'What is quantum mechanics?';
      companionNotifier.sendMessage(recognizedText);

      await pumpEventQueue();

      final lastMsg = companionNotifier.state.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text, contains('I understand: What is quantum mechanics?'));
    });
  });

  group('CompanionScreen Voice UI Widget Tests', () {
    testWidgets('Mic button renders with accessibility semantics and toggles listening', (tester) async {
      final voiceEngine = VoiceEngine(permService, mockVoiceService);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceEngineProvider.overrideWith((ref) => voiceEngine),
            companionRepositoryProvider.overrideWithValue(fakeCompanionRepo),
          ],
          child: const MaterialApp(
            home: CompanionScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final micFinder = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.label != null &&
          widget.properties.label!.contains('voice recognition'));

      expect(micFinder, findsOneWidget);

      await tester.tap(micFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(voiceEngine.state.isListening, isTrue);
      expect(find.text('LISTENING'), findsWidgets);

      final stopMicFinder = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.label != null &&
          widget.properties.label!.contains('Stop listening'));

      expect(stopMicFinder, findsOneWidget);

      await tester.tap(stopMicFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(voiceEngine.state.isListening, isFalse);
      expect(voiceEngine.state.isIdle, isTrue);
    });

    testWidgets('Voice recognition triggers assistant response and speaks via TTS', (tester) async {
      final voiceEngine = VoiceEngine(permService, mockVoiceService, mockTtsService);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceEngineProvider.overrideWith((ref) => voiceEngine),
            companionRepositoryProvider.overrideWithValue(fakeCompanionRepo),
          ],
          child: const MaterialApp(
            home: CompanionScreen(),
          ),
        ),
      );
      await tester.pump();

      // Emit recognized voice input
      await voiceEngine.startListening();
      await tester.pump();

      mockVoiceService.emit(const VoiceFinalResultEvent('What is quantum mechanics?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify TTS was invoked to speak the response
      expect(mockTtsService.speakCount, greaterThanOrEqualTo(1));
      expect(mockTtsService.lastSpokenText, contains('quantum mechanics'));
      expect(voiceEngine.state.isSpeaking, isTrue);
      expect(find.text('SPEAKING...'), findsWidgets);
      expect(find.text('VAJRA is speaking... Tap button to stop'), findsOneWidget);
    });

    testWidgets('Typed chat message does NOT invoke TTS speak', (tester) async {
      final voiceEngine = VoiceEngine(permService, mockVoiceService, mockTtsService);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceEngineProvider.overrideWith((ref) => voiceEngine),
            companionRepositoryProvider.overrideWithValue(fakeCompanionRepo),
          ],
          child: const MaterialApp(
            home: CompanionScreen(),
          ),
        ),
      );
      await tester.pump();

      // Enter typed text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'What is quantum mechanics?');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify TTS was NEVER called for typed messages
      expect(mockTtsService.speakCount, 0);
      expect(voiceEngine.state.isSpeaking, isFalse);
    });

    testWidgets('Tapping voice button while speaking immediately stops TTS', (tester) async {
      final voiceEngine = VoiceEngine(permService, mockVoiceService, mockTtsService);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceEngineProvider.overrideWith((ref) => voiceEngine),
            companionRepositoryProvider.overrideWithValue(fakeCompanionRepo),
          ],
          child: const MaterialApp(
            home: CompanionScreen(),
          ),
        ),
      );
      await tester.pump();

      // Trigger speaking state
      final speakFuture = voiceEngine.speak('VAJRA is currently explaining a concept to you.');
      await tester.pump();

      expect(voiceEngine.state.isSpeaking, isTrue);

      final stopSpeakingFinder = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.label != null &&
          widget.properties.label!.contains('Stop speaking'));

      expect(stopSpeakingFinder, findsOneWidget);

      await tester.tap(stopSpeakingFinder);
      await tester.pump();
      await speakFuture;

      expect(voiceEngine.state.isSpeaking, isFalse);
      expect(voiceEngine.state.isIdle, isTrue);
      expect(mockTtsService.stopCount, greaterThanOrEqualTo(1));
    });
  });
}

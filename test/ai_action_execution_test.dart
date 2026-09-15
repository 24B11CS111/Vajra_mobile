import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vajra_mobile/core/intelligence/action/vajra_command_router.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';
import 'package:vajra_mobile/core/network/api_response.dart';
import 'package:vajra_mobile/features/planner/models/planner_model.dart';
import 'package:vajra_mobile/features/planner/models/calendar_event_model.dart';
import 'package:vajra_mobile/features/planner/services/planner_repository.dart';
import 'package:vajra_mobile/features/planner/services/planner_local_data_source.dart';
import 'package:vajra_mobile/features/study/models/study_models.dart';
import 'package:vajra_mobile/features/study/models/study_session_model.dart';
import 'package:vajra_mobile/features/study/services/study_repository.dart';
import 'package:vajra_mobile/features/study/services/study_local_data_source.dart';
import 'package:vajra_mobile/features/memory/models/memory_model.dart';
import 'package:vajra_mobile/features/memory/services/memory_repository.dart';

class _FakePlannerRepository implements PlannerRepository {
  final List<PlannerTask> tasks = [];
  final List<CalendarEventModel> events = [];

  @override
  Future<ApiResponse<PlannerTask>> createTask(Map<String, dynamic> data) async {
    final task = PlannerTask(
      id: 'task_',
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
      id: 'event_',
      userId: 'u1',
      title: data['title'] as String,
      startTime: DateTime.tryParse(data['start_time'].toString()) ?? DateTime.now(),
      eventType: data['event_type']?.toString() ?? 'study_session',
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

class _FakeStudyRepository implements StudyRepository {
  final List<AssignmentModel> assignments = [];
  final List<SubjectModel> subjects = [];

  @override
  Future<ApiResponse<AssignmentModel>> createAssignment(Map<String, dynamic> data) async {
    final a = AssignmentModel(
      id: 'a_',
      userId: 'u1',
      title: data['title'] as String,
      subjectName: data['subject']?.toString() ?? 'General',
    );
    assignments.add(a);
    return ApiResponse.success(a);
  }

  @override
  Future<ApiResponse<SubjectModel>> createSubject(Map<String, dynamic> data) async {
    final s = SubjectModel(
      id: 's_',
      userId: 'u1',
      name: data['name'] as String,
    );
    subjects.add(s);
    return ApiResponse.success(s);
  }

  @override
  Future<ApiResponse<AssignmentModel>> updateAssignment(String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<SubjectModel>> updateSubject(String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<ApiResponse<List<AssignmentModel>>> getAssignments({String? status, String? subjectId}) async =>
      ApiResponse.success(assignments);

  @override
  Future<ApiResponse<List<SubjectModel>>> getSubjects() async => ApiResponse.success(subjects);
  @override
  Future<ApiResponse<List<StudySessionModel>>> getUpcomingSessions() async => ApiResponse.success([]);

  @override
  Future<ApiResponse<StudySessionModel>> createStudySession(Map<String, dynamic> data) async {
    final s = StudySessionModel(
      id: 'session_test',
      subject: data['subject']?.toString() ?? 'General Study',
      topic: data['topic']?.toString() ?? 'Focus',
      scheduledTime: DateTime.tryParse(data['scheduled_time']?.toString() ?? '') ?? DateTime.now(),
      progress: 0.0,
      durationMinutes: 45,
    );
    return ApiResponse.success(s);
  }
  @override
  Future<ApiResponse<bool>> deleteAssignment(String id) async => ApiResponse.success(true);
  @override
  Future<ApiResponse<bool>> deleteSubject(String id) async => ApiResponse.success(true);
  @override
  Future<ApiResponse<AssignmentModel>> toggleAssignment(String id) async {
    final a = assignments.firstWhere((e) => e.id == id);
    return ApiResponse.success(a);
  }

  @override
  StudyLocalDataSource get localDataSource => StudyLocalDataSourceImpl();
}

class _FakeMemoryRepository implements MemoryRepository {
  final List<MemoryModel> memories = [];

  @override
  Future<ApiResponse<bool>> saveFact(String content, {String category = 'fact'}) async {
    memories.add(MemoryModel(
      id: 'm_',
      content: content,
      category: category,
      importanceScore: 0.8,
      isPinned: false,
      createdAt: DateTime.now(),
      source: 'Test',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VajraCommandRouter Intent Classification', () {
    test('Correctly parses Task creation intent', () {
      final cmd = VajraCommandRouter.parse('Create a task to complete my ML project tomorrow');
      expect(cmd.type, VajraIntentType.task);
      expect(cmd.title.toLowerCase(), contains('complete my ml project'));
    });

    test('Correctly parses Calendar Event scheduling intent', () {
      final cmd = VajraCommandRouter.parse('Schedule a meeting tomorrow at 4 PM');
      expect(cmd.type, VajraIntentType.calendar);
      expect(cmd.dateTime, isNotNull);
      expect(cmd.dateTime!.hour, 16);
    });

    test('Correctly parses Assignment creation intent', () {
      final cmd = VajraCommandRouter.parse('Add an assignment for Computer Networks due Monday');
      expect(cmd.type, VajraIntentType.assignment);
      expect(cmd.dateTime, isNotNull);
    });

    test('Correctly parses Subject creation intent', () {
      final cmd = VajraCommandRouter.parse('Add a subject called Cloud Computing');
      expect(cmd.type, VajraIntentType.subject);
      expect(cmd.title.toLowerCase(), contains('cloud computing'));
    });

    test('Correctly parses Reminder intent', () {
      final cmd = VajraCommandRouter.parse('Remind me to study Physics at 7 PM');
      expect(cmd.type, VajraIntentType.reminder);
      expect(cmd.dateTime, isNotNull);
      expect(cmd.dateTime!.hour, 19);
    });

    test('Correctly parses Save Memory intent', () {
      final cmd = VajraCommandRouter.parse('Remember that my car registration number is MH12AB1234');
      expect(cmd.type, VajraIntentType.saveMemory);
      expect(cmd.title, contains('MH12AB1234'));
    });

    test('Correctly parses Recall Memory intent', () {
      final cmd = VajraCommandRouter.parse('What is my car registration number?');
      expect(cmd.type, VajraIntentType.recallMemory);
      expect(cmd.title.toLowerCase(), contains('car registration number'));
    });

    test('Correctly parses Planning intent', () {
      final cmd = VajraCommandRouter.parse('Plan my day tomorrow');
      expect(cmd.type, VajraIntentType.planning);
      expect(cmd.dateTime, isNotNull);
    });

    test('Defaults general knowledge queries to Information', () {
      final cmd = VajraCommandRouter.parse('Explain the theory of relativity');
      expect(cmd.type, VajraIntentType.information);
    });
  });

  group('ActionEngine Real Execution Layer', () {
    late _FakePlannerRepository plannerRepo;
    late _FakeStudyRepository studyRepo;
    late _FakeMemoryRepository memoryRepo;
    late ActionEngine actionEngine;

    setUp(() {
      plannerRepo = _FakePlannerRepository();
      studyRepo = _FakeStudyRepository();
      memoryRepo = _FakeMemoryRepository();

      actionEngine = ActionEngine(
        plannerRepository: plannerRepo,
        studyRepository: studyRepo,
        memoryRepository: memoryRepo,
      );
    });

    test('Executes task creation and actually persists it in repository', () async {
      final cmd = VajraCommandRouter.parse('Create a task: Review Operating Systems');
      final result = await actionEngine.executeParsedCommand(cmd);

      expect(result.isSuccess, true);
      expect(plannerRepo.tasks.length, 1);
      expect(plannerRepo.tasks.first.title, contains('Review Operating Systems'));
    });

    test('Executes calendar scheduling and persists event in repository', () async {
      final cmd = VajraCommandRouter.parse('Schedule a meeting with Professor at 3 PM');
      final result = await actionEngine.executeParsedCommand(cmd);

      expect(result.isSuccess, true);
      expect(plannerRepo.events.length, 1);
    });

    test('Executes assignment creation and persists in study hub', () async {
      final cmd = VajraCommandRouter.parse('Add an assignment for Database Lab');
      final result = await actionEngine.executeParsedCommand(cmd);

      expect(result.isSuccess, true);
      expect(studyRepo.assignments.length, 1);
      expect(studyRepo.assignments.first.title, contains('Database Lab'));
    });

    test('Saves memory fact and recalls it truthfully', () async {
      // 1. Save
      final saveCmd = VajraCommandRouter.parse('Remember that my locker code is 9876');
      final saveResult = await actionEngine.executeParsedCommand(saveCmd);

      expect(saveResult.isSuccess, true);
      expect(memoryRepo.memories.length, 1);
      expect(memoryRepo.memories.first.content, contains('9876'));

      // 2. Recall
      final recallCmd = VajraCommandRouter.parse('What is my locker code?');
      final recallResult = await actionEngine.executeParsedCommand(recallCmd);

      expect(recallResult.isSuccess, true);
      expect(recallResult.message, contains('9876'));
    });

    test('Executes planning and retrieves current tasks and schedule', () async {
      // Add a task
      await plannerRepo.createTask({'title': 'Complete Homework'});
      final planCmd = VajraCommandRouter.parse('Plan my day today');
      final planResult = await actionEngine.executeParsedCommand(planCmd);

      expect(planResult.isSuccess, true);
      expect(planResult.message, contains('Complete Homework'));
    });

    test('Command 1: "Schedule a meeting tomorrow at 4." schedules meeting at 4 PM and confirms properly', () async {
      final cmd = VajraCommandRouter.parse('Schedule a meeting tomorrow at 4.');
      expect(cmd.type, VajraIntentType.calendar);
      expect(cmd.dateTime, isNotNull);
      expect(cmd.dateTime!.hour, 16); // 4 PM

      final result = await actionEngine.executeParsedCommand(cmd);
      expect(result.status, ActionStatus.success);
      expect(result.message, "Done — I've scheduled your meeting for tomorrow at 4 PM.");
      expect(plannerRepo.events.length, 1);
      expect(plannerRepo.events.first.title, 'Meeting');
    });

    test('Command 2: "Remind me to study at 7." schedules reminder at 7 PM and confirms properly', () async {
      final cmd = VajraCommandRouter.parse('Remind me to study at 7.');
      expect(cmd.type, VajraIntentType.reminder);
      expect(cmd.dateTime, isNotNull);
      expect(cmd.dateTime!.hour, 19); // 7 PM

      final result = await actionEngine.executeParsedCommand(cmd);
      expect(result.status, ActionStatus.success);
      expect(result.message, "Done — I'll remind you to study at 7 PM.");
    });

    test('Command 3: "Add Physics assignment due Monday." extracts subject and due date', () async {
      final cmd = VajraCommandRouter.parse('Add Physics assignment due Monday.');
      expect(cmd.type, VajraIntentType.assignment);
      expect(cmd.subject, 'Physics');
      expect(cmd.dateTime, isNotNull);

      final result = await actionEngine.executeParsedCommand(cmd);
      expect(result.status, ActionStatus.success);
      expect(result.message, 'Added — Physics assignment is due Monday.');
      expect(studyRepo.assignments.any((a) => a.title.contains('Physics')), true);
    });

    test('Command 4: "Plan my day." when empty honestly reports no scheduled items', () async {
      final emptyPlanner = _FakePlannerRepository();
      final emptyStudy = _FakeStudyRepository();
      final engine = ActionEngine(
        plannerRepository: emptyPlanner,
        studyRepository: emptyStudy,
      );

      final cmd = VajraCommandRouter.parse('Plan my day.');
      expect(cmd.type, VajraIntentType.planning);

      final result = await engine.executeParsedCommand(cmd);
      expect(result.status, ActionStatus.success);
      expect(result.message, contains("You don't have any scheduled events, pending tasks, or upcoming assignments"));
    });

    test('Command 5: "Create a task to finish my project tomorrow." creates task with due date', () async {
      final cmd = VajraCommandRouter.parse('Create a task to finish my project tomorrow.');
      expect(cmd.type, VajraIntentType.task);
      expect(cmd.title.toLowerCase(), 'finish my project');

      final result = await actionEngine.executeParsedCommand(cmd);
      expect(result.status, ActionStatus.success);
      expect(result.message, 'Added to your planner — finish my project tomorrow.');
      expect(plannerRepo.tasks.any((t) => t.title == 'finish my project'), true);
    });

    test('Command 6: "Schedule my study session for tonight." creates study session', () async {
      final cmd = VajraCommandRouter.parse('Schedule my study session for tonight.');
      expect(cmd.type, VajraIntentType.studySession);
      expect(cmd.dateTime, isNotNull);

      final result = await actionEngine.executeParsedCommand(cmd);
      expect(result.status, ActionStatus.success);
      expect(result.message, contains('Scheduled your study session for'));
    });

    test('Command 7: "Remember that my project deadline is Friday." persists and recalls', () async {
      final saveCmd = VajraCommandRouter.parse('Remember that my project deadline is Friday.');
      expect(saveCmd.type, VajraIntentType.saveMemory);
      expect(saveCmd.title, 'my project deadline is Friday.');

      final saveResult = await actionEngine.executeParsedCommand(saveCmd);
      expect(saveResult.status, ActionStatus.success);
      expect(saveResult.message, "Got it — I'll remember that my project deadline is Friday..");

      // Recall
      final recallCmd = VajraCommandRouter.parse('What is my project deadline?');
      expect(recallCmd.type, VajraIntentType.recallMemory);

      final recallResult = await actionEngine.executeParsedCommand(recallCmd);
      expect(recallResult.status, ActionStatus.success);
      expect(recallResult.message.toLowerCase(), contains('friday'));
    });

    test('Rule #1: No fake confirmations when underlying operation fails', () async {
      final brokenPlanner = _BrokenPlannerRepository();
      final engine = ActionEngine(plannerRepository: brokenPlanner);

      final cmd = VajraCommandRouter.parse('Create a task to buy groceries');
      final result = await engine.executeParsedCommand(cmd);

      expect(result.status, ActionStatus.failure);
      expect(result.isSuccess, false);
      expect(result.message, isNot(contains('Added to your planner')));
    });

    test('Multi-User Isolation: User A data is not visible to User B', () async {
      final userALocal = PlannerLocalDataSourceImpl(userId: 'user_a');
      final userBLocal = PlannerLocalDataSourceImpl(userId: 'user_b');

      await userALocal.saveTask(PlannerTask(
        id: 'task_user_a_1',
        title: 'User A Secret Task',
        category: 'Study',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        isCompleted: false,
      ));

      // User B inspects cache
      final userBTasks = await userBLocal.getCachedTasks();
      expect(userBTasks, isNull);

      // User B saves their task
      await userBLocal.saveTask(PlannerTask(
        id: 'task_user_b_1',
        title: 'User B Task',
        category: 'Work',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        isCompleted: false,
      ));

      // User A inspects cache again -> User A only sees User A task
      final userATasks = await userALocal.getCachedTasks();
      expect(userATasks, isNotNull);
      expect(userATasks!.length, 1);
      expect(userATasks.first.title, 'User A Secret Task');
      expect(userATasks.any((t) => t.id == 'task_user_b_1'), false);
    });
  });
}

class _BrokenPlannerRepository extends _FakePlannerRepository {
  @override
  Future<ApiResponse<PlannerTask>> createTask(Map<String, dynamic> data) async {
    return ApiResponse.error('Database write failed');
  }
}

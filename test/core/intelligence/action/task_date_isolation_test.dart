import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vajra_mobile/core/intelligence/action/action_engine.dart';
import 'package:vajra_mobile/core/intelligence/action/vajra_command_router.dart';
import 'package:vajra_mobile/core/network/api_response.dart';
import 'package:vajra_mobile/features/planner/models/planner_model.dart';
import 'package:vajra_mobile/features/planner/models/calendar_event_model.dart';
import 'package:vajra_mobile/features/planner/services/planner_repository.dart';
import 'package:vajra_mobile/features/planner/services/planner_local_data_source.dart';

class _FakePlannerRepository implements PlannerRepository {
  final List<PlannerTask> tasks = [];
  final List<CalendarEventModel> events = [];

  @override
  Future<ApiResponse<PlannerTask>> createTask(Map<String, dynamic> data) async {
    final startRaw = data['start_time'] ?? data['due_date'] ?? DateTime.now().toIso8601String();
    final endRaw = data['end_time'] ?? data['due_date'] ?? DateTime.now().add(const Duration(hours: 1)).toIso8601String();
    final task = PlannerTask(
      id: 'task_${tasks.length + 1}',
      title: data['title'] as String,
      category: data['category'] as String? ?? 'Task',
      startTime: DateTime.parse(startRaw.toString()),
      endTime: DateTime.parse(endRaw.toString()),
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
      startTime: DateTime.parse(data['start_time'].toString()),
      endTime: data['end_time'] != null ? DateTime.parse(data['end_time'].toString()) : null,
      eventType: data['event_type']?.toString() ?? 'meeting',
    );
    events.add(event);
    return ApiResponse.success(event);
  }

  @override
  Future<ApiResponse<List<PlannerTask>>> getTasks(DateTime date) async =>
      ApiResponse.success(tasks.where((t) => DateUtils.isSameDay(t.startTime, date)).toList());

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task Date Isolation - VajraCommandRouter & Recurrence', () {
    test('parses "Create a task for September 20" with strict date and no recurrence', () {
      final cmd = VajraCommandRouter.parse('Create a task for September 20');
      expect(cmd.type, VajraIntentType.task);
      expect(cmd.dateTime, isNotNull);
      expect(cmd.dateTime!.month, 9);
      expect(cmd.dateTime!.day, 20);
      expect(cmd.isRecurring, isFalse);

      // Verify date isolation: matches ONLY Sep 20
      final targetYear = cmd.dateTime!.year;
      expect(DateUtils.isSameDay(cmd.dateTime!, DateTime(targetYear, 9, 20)), isTrue);
      expect(DateUtils.isSameDay(cmd.dateTime!, DateTime(targetYear, 9, 19)), isFalse);
      expect(DateUtils.isSameDay(cmd.dateTime!, DateTime(targetYear, 9, 21)), isFalse);
      expect(DateUtils.isSameDay(cmd.dateTime!, DateTime(targetYear, 8, 20)), isFalse);
      expect(DateUtils.isSameDay(cmd.dateTime!, DateTime(targetYear, 10, 20)), isFalse);
    });

    test('parses various month date formats accurately', () {
      final cmd1 = VajraCommandRouter.parse('Task due October 15 finish lab report');
      expect(cmd1.dateTime?.month, 10);
      expect(cmd1.dateTime?.day, 15);
      expect(cmd1.isRecurring, isFalse);

      final cmd2 = VajraCommandRouter.parse('Add a task for 25th December');
      expect(cmd2.dateTime?.month, 12);
      expect(cmd2.dateTime?.day, 25);
      expect(cmd2.isRecurring, isFalse);

      final cmd3 = VajraCommandRouter.parse('Task due 2026-11-05');
      expect(cmd3.dateTime?.year, 2026);
      expect(cmd3.dateTime?.month, 11);
      expect(cmd3.dateTime?.day, 5);
      expect(cmd3.isRecurring, isFalse);
    });

    test('strict recurrence: regular task commands do NOT create recurrence', () {
      final regularQueries = [
        'Create a task for September 20',
        'Add a task to submit homework tomorrow',
        'Add a task to buy groceries on Friday',
        'Create a task to finish math assignment next Monday',
      ];

      for (final query in regularQueries) {
        final cmd = VajraCommandRouter.parse(query);
        expect(cmd.isRecurring, isFalse, reason: 'Failed for query: "$query"');
      }
    });

    test('strict recurrence: ONLY explicit recurrence phrases create recurring tasks', () {
      final recurringQueries = [
        'Create a daily task to drink water',
        'Add a task to study math every day',
        'Add a task for weekly review every Sunday',
        'Create a task: workout routine every morning',
      ];

      for (final query in recurringQueries) {
        final cmd = VajraCommandRouter.parse(query);
        expect(cmd.isRecurring, isTrue, reason: 'Failed for query: "$query"');
      }
    });
  });

  group('Task Date Isolation - ActionEngine & Planner Filtering', () {
    late _FakePlannerRepository plannerRepo;
    late ActionEngine actionEngine;

    setUp(() {
      plannerRepo = _FakePlannerRepository();
      actionEngine = ActionEngine(plannerRepository: plannerRepo);
    });

    test('ActionEngine creates task on exact requested date and isolates to that day', () async {
      final cmd = VajraCommandRouter.parse('Create a task for September 20 finish physics homework');
      final result = await actionEngine.executeParsedCommand(cmd);

      expect(result.status, ActionStatus.success);
      expect(result.message, contains('September 20'));

      expect(plannerRepo.tasks, isNotEmpty);
      final task = plannerRepo.tasks.last;

      expect(task.title, contains('finish physics homework'));
      expect(task.startTime.month, 9);
      expect(task.startTime.day, 20);

      // Verify task isolation in simulated Day/Week planner filtering
      final year = task.startTime.year;
      final sep19 = DateTime(year, 9, 19);
      final sep20 = DateTime(year, 9, 20);
      final sep21 = DateTime(year, 9, 21);

      // Filter simulation: same logic as PlannerScreen._buildTimelineAndTasks
      bool appearsOn(PlannerTask t, DateTime date) => DateUtils.isSameDay(t.startTime, date);

      expect(appearsOn(task, sep20), isTrue);
      expect(appearsOn(task, sep19), isFalse);
      expect(appearsOn(task, sep21), isFalse);

      // Verify repository level filtering
      final sep20Tasks = await plannerRepo.getTasks(sep20);
      expect(sep20Tasks.data?.length, 1);

      final sep19Tasks = await plannerRepo.getTasks(sep19);
      expect(sep19Tasks.data?.length, 0);

      final sep21Tasks = await plannerRepo.getTasks(sep21);
      expect(sep21Tasks.data?.length, 0);
    });
  });
}

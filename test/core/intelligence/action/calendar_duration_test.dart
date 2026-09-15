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
    final task = PlannerTask(
      id: 'task_${tasks.length + 1}',
      title: data['title'] as String,
      category: data['category'] as String? ?? 'Task',
      startTime: DateTime.parse(data['start_time'].toString()),
      endTime: DateTime.parse(data['end_time'].toString()),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Calendar Event Time Range & Duration Parsing', () {
    test('parses explicit time ranges with start-time AM/PM inference', () {
      final cmd1 = VajraCommandRouter.parse('Schedule a meeting tomorrow from 4 PM to 5:30 PM');
      expect(cmd1.type, VajraIntentType.calendar);
      expect(cmd1.dateTime?.hour, 16);
      expect(cmd1.dateTime?.minute, 0);
      expect(cmd1.endDateTime?.hour, 17);
      expect(cmd1.endDateTime?.minute, 30);
      expect(cmd1.duration?.inMinutes, 90);

      // "4 to 5:30 PM" should infer 4 PM based on 5:30 PM
      final cmd2 = VajraCommandRouter.parse('Schedule a meeting tomorrow from 4 to 5:30 PM');
      expect(cmd2.dateTime?.hour, 16);
      expect(cmd2.dateTime?.minute, 0);
      expect(cmd2.endDateTime?.hour, 17);
      expect(cmd2.endDateTime?.minute, 30);
      expect(cmd2.duration?.inMinutes, 90);
    });

    test('parses 12 AM (midnight) and 12 PM (noon) accurately', () {
      final midnight = VajraCommandRouter.parse('Schedule a meeting tomorrow from 12 AM to 1:30 AM');
      expect(midnight.dateTime?.hour, 0);
      expect(midnight.dateTime?.minute, 0);
      expect(midnight.endDateTime?.hour, 1);
      expect(midnight.endDateTime?.minute, 30);
      expect(midnight.duration?.inMinutes, 90);

      final noon = VajraCommandRouter.parse('Schedule a meeting tomorrow from 12 PM to 1:30 PM');
      expect(noon.dateTime?.hour, 12);
      expect(noon.dateTime?.minute, 0);
      expect(noon.endDateTime?.hour, 13);
      expect(noon.endDateTime?.minute, 30);
      expect(noon.duration?.inMinutes, 90);
    });

    test('parses various duration expressions', () {
      // 15 minutes
      final cmd15 = VajraCommandRouter.parse('Schedule a meeting at 3 PM for 15 minutes');
      expect(cmd15.duration?.inMinutes, 15);
      expect(cmd15.endDateTime?.difference(cmd15.dateTime!).inMinutes, 15);

      // 30 minutes
      final cmd30 = VajraCommandRouter.parse('Schedule a meeting tomorrow at 2 PM for 30 minutes');
      expect(cmd30.duration?.inMinutes, 30);
      expect(cmd30.endDateTime?.difference(cmd30.dateTime!).inMinutes, 30);

      // 45 mins
      final cmd45 = VajraCommandRouter.parse('Schedule a meeting at 10 AM for 45 mins');
      expect(cmd45.duration?.inMinutes, 45);

      // 1 hour
      final cmd1h = VajraCommandRouter.parse('Schedule a meeting at 9 AM for 1 hour');
      expect(cmd1h.duration?.inMinutes, 60);

      // 1.5 hours
      final cmd1_5h = VajraCommandRouter.parse('Schedule a meeting at 4 PM for 1.5 hours');
      expect(cmd1_5h.duration?.inMinutes, 90);

      // 2 hours
      final cmd2h = VajraCommandRouter.parse('Schedule a meeting at 2 PM for 2 hours');
      expect(cmd2h.duration?.inMinutes, 120);
    });
  });

  group('Calendar Event Execution via ActionEngine', () {
    late _FakePlannerRepository plannerRepo;
    late ActionEngine actionEngine;

    setUp(() {
      plannerRepo = _FakePlannerRepository();
      actionEngine = ActionEngine(plannerRepository: plannerRepo);
    });

    test('ActionEngine computes accurate end timestamp and confirms friendly range', () async {
      final cmd = VajraCommandRouter.parse('Schedule a meeting tomorrow from 3 PM to 4:30 PM');
      final result = await actionEngine.executeParsedCommand(cmd);

      expect(result.status, ActionStatus.success);
      expect(result.message, contains('from 3 PM to 4:30 PM'));

      expect(plannerRepo.events, isNotEmpty);
      final event = plannerRepo.events.last;

      expect(event.startTime.hour, 15);
      expect(event.startTime.minute, 0);
      expect(event.endTime?.hour, 16);
      expect(event.endTime?.minute, 30);
      expect(event.endTime?.difference(event.startTime).inMinutes, 90);
    });

    test('ActionEngine respects "for 30 minutes" duration over default 1 hour', () async {
      final cmd = VajraCommandRouter.parse('Schedule a meeting tomorrow at 10 AM for 30 minutes');
      final result = await actionEngine.executeParsedCommand(cmd);

      expect(result.status, ActionStatus.success);
      expect(result.message, contains('from 10 AM to 10:30 AM'));

      expect(plannerRepo.events, isNotEmpty);
      final event = plannerRepo.events.last;

      expect(event.startTime.hour, 10);
      expect(event.startTime.minute, 0);
      expect(event.endTime?.hour, 10);
      expect(event.endTime?.minute, 30);
      expect(event.endTime?.difference(event.startTime).inMinutes, 30);
    });

    test('Default 1 hour is preserved when no duration is specified', () async {
      final cmd = VajraCommandRouter.parse('Schedule a meeting tomorrow at 4 PM');
      final result = await actionEngine.executeParsedCommand(cmd);

      expect(result.status, ActionStatus.success);
      expect(result.message, contains('tomorrow at 4 PM'));

      expect(plannerRepo.events, isNotEmpty);
      final event = plannerRepo.events.last;

      expect(event.startTime.hour, 16);
      expect(event.endTime?.hour, 17);
      expect(event.endTime?.difference(event.startTime).inMinutes, 60);
    });
  });
}

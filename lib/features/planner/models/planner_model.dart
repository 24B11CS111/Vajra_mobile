import 'package:freezed_annotation/freezed_annotation.dart';

part 'planner_model.freezed.dart';
part 'planner_model.g.dart';

@freezed
abstract class PlannerTask with _$PlannerTask {
  const factory PlannerTask({
    required String id,
    required String title,
    required String category,
    required DateTime startTime,
    required DateTime endTime,
    required bool isCompleted,
    String? aiSuggestion,
  }) = _PlannerTask;

  factory PlannerTask.fromJson(Map<String, dynamic> json) => _$PlannerTaskFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'briefing_model.freezed.dart';
part 'briefing_model.g.dart';

@freezed
abstract class BriefingModel with _$BriefingModel {
  const factory BriefingModel({
    required String title,
    required String message,
    required String weatherContext,
    required String priorityTaskTitle,
    required String priorityTaskSubtitle,
    required String eveningWrapUp,
  }) = _BriefingModel;

  factory BriefingModel.fromJson(Map<String, dynamic> json) => _$BriefingModelFromJson(json);
}

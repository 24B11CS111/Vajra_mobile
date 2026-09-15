import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_session_model.freezed.dart';
part 'study_session_model.g.dart';

@freezed
abstract class StudySessionModel with _$StudySessionModel {
  const factory StudySessionModel({
    required String id,
    required String subject,
    required String topic,
    required int durationMinutes,
    required double progress,
    required DateTime scheduledTime,
  }) = _StudySessionModel;

  factory StudySessionModel.fromJson(Map<String, dynamic> json) => _$StudySessionModelFromJson(json);
}

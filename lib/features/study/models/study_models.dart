import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_models.freezed.dart';
part 'study_models.g.dart';

@freezed
abstract class SubjectModel with _$SubjectModel {
  const factory SubjectModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    String? description,
    @Default('#2563EB') String color,
    @Default('medium') String priority,
    @JsonKey(name: 'exam_date') DateTime? examDate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SubjectModel;

  factory SubjectModel.fromJson(Map<String, dynamic> json) => _$SubjectModelFromJson(json);
}

@freezed
abstract class AssignmentModel with _$AssignmentModel {
  const factory AssignmentModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'subject_id') String? subjectId,
    @JsonKey(name: 'subject_name') @Default('General') String subjectName,
    required String title,
    String? description,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'due_time') String? dueTime,
    @Default('medium') String priority,
    @Default('NOT_STARTED') String status,
    @JsonKey(name: 'attachment_url') String? attachmentUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AssignmentModel;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) => _$AssignmentModelFromJson(json);
}

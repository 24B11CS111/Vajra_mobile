import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_model.freezed.dart';
part 'calendar_event_model.g.dart';

@freezed
abstract class CalendarEventModel with _$CalendarEventModel {
  const factory CalendarEventModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    String? description,
    @JsonKey(name: 'event_type') @Default('study_session') String eventType,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') DateTime? endTime,
    @JsonKey(name: 'is_all_day') @Default(false) bool isAllDay,
    String? location,
    @Default('#8B5CF6') String color,
    @Default('scheduled') String status,
    @JsonKey(name: 'related_id') String? relatedId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CalendarEventModel;

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) => _$CalendarEventModelFromJson(json);
}

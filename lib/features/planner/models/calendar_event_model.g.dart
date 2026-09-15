// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarEventModel _$CalendarEventModelFromJson(Map<String, dynamic> json) =>
    _CalendarEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['event_type'] as String? ?? 'study_session',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      isAllDay: json['is_all_day'] as bool? ?? false,
      location: json['location'] as String?,
      color: json['color'] as String? ?? '#8B5CF6',
      status: json['status'] as String? ?? 'scheduled',
      relatedId: json['related_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CalendarEventModelToJson(_CalendarEventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'event_type': instance.eventType,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'is_all_day': instance.isAllDay,
      'location': instance.location,
      'color': instance.color,
      'status': instance.status,
      'related_id': instance.relatedId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

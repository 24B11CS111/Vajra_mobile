// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudySessionModel _$StudySessionModelFromJson(Map<String, dynamic> json) =>
    _StudySessionModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      progress: (json['progress'] as num).toDouble(),
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
    );

Map<String, dynamic> _$StudySessionModelToJson(_StudySessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subject': instance.subject,
      'topic': instance.topic,
      'durationMinutes': instance.durationMinutes,
      'progress': instance.progress,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
    };

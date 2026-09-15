// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubjectModel _$SubjectModelFromJson(Map<String, dynamic> json) =>
    _SubjectModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#2563EB',
      priority: json['priority'] as String? ?? 'medium',
      examDate: json['exam_date'] == null
          ? null
          : DateTime.parse(json['exam_date'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SubjectModelToJson(_SubjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'color': instance.color,
      'priority': instance.priority,
      'exam_date': instance.examDate?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_AssignmentModel _$AssignmentModelFromJson(Map<String, dynamic> json) =>
    _AssignmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String? ?? 'General',
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      dueTime: json['due_time'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'NOT_STARTED',
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AssignmentModelToJson(_AssignmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'subject_id': instance.subjectId,
      'subject_name': instance.subjectName,
      'title': instance.title,
      'description': instance.description,
      'due_date': instance.dueDate?.toIso8601String(),
      'due_time': instance.dueTime,
      'priority': instance.priority,
      'status': instance.status,
      'attachment_url': instance.attachmentUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlannerTask _$PlannerTaskFromJson(Map<String, dynamic> json) => _PlannerTask(
  id: json['id'] as String,
  title: json['title'] as String,
  category: json['category'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  isCompleted: json['isCompleted'] as bool,
  aiSuggestion: json['aiSuggestion'] as String?,
);

Map<String, dynamic> _$PlannerTaskToJson(_PlannerTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'aiSuggestion': instance.aiSuggestion,
    };

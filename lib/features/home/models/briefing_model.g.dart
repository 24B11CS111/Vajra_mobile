// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'briefing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BriefingModel _$BriefingModelFromJson(Map<String, dynamic> json) =>
    _BriefingModel(
      title: json['title'] as String,
      message: json['message'] as String,
      weatherContext: json['weatherContext'] as String,
      priorityTaskTitle: json['priorityTaskTitle'] as String,
      priorityTaskSubtitle: json['priorityTaskSubtitle'] as String,
      eveningWrapUp: json['eveningWrapUp'] as String,
    );

Map<String, dynamic> _$BriefingModelToJson(_BriefingModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'message': instance.message,
      'weatherContext': instance.weatherContext,
      'priorityTaskTitle': instance.priorityTaskTitle,
      'priorityTaskSubtitle': instance.priorityTaskSubtitle,
      'eveningWrapUp': instance.eveningWrapUp,
    };

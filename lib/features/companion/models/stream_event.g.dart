// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackendStreamEvent _$BackendStreamEventFromJson(Map<String, dynamic> json) =>
    _BackendStreamEvent(
      eventType: $enumDecode(_$EventTypeEnumMap, json['event_type']),
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$BackendStreamEventToJson(_BackendStreamEvent instance) =>
    <String, dynamic>{
      'event_type': _$EventTypeEnumMap[instance.eventType]!,
      'payload': instance.payload,
      'timestamp': instance.timestamp,
    };

const _$EventTypeEnumMap = {
  EventType.thinking: 'THINKING',
  EventType.token: 'TOKEN',
  EventType.toolStarted: 'TOOL_STARTED',
  EventType.toolFinished: 'TOOL_FINISHED',
  EventType.memorySaved: 'MEMORY_SAVED',
  EventType.complete: 'COMPLETE',
  EventType.error: 'ERROR',
};

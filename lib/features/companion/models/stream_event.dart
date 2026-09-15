import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_event.freezed.dart';
part 'stream_event.g.dart';

enum EventType {
  @JsonValue("THINKING") thinking,
  @JsonValue("TOKEN") token,
  @JsonValue("TOOL_STARTED") toolStarted,
  @JsonValue("TOOL_FINISHED") toolFinished,
  @JsonValue("MEMORY_SAVED") memorySaved,
  @JsonValue("COMPLETE") complete,
  @JsonValue("ERROR") error,
}

@freezed
abstract class BackendStreamEvent with _$BackendStreamEvent {
  const factory BackendStreamEvent({
    @JsonKey(name: 'event_type') required EventType eventType,
    required Map<String, dynamic> payload,
    String? timestamp,
  }) = _BackendStreamEvent;

  factory BackendStreamEvent.fromJson(Map<String, dynamic> json) => _$BackendStreamEventFromJson(json);
}

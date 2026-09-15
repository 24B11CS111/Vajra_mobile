// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackendStreamEvent {

@JsonKey(name: 'event_type') EventType get eventType; Map<String, dynamic> get payload; String? get timestamp;
/// Create a copy of BackendStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackendStreamEventCopyWith<BackendStreamEvent> get copyWith => _$BackendStreamEventCopyWithImpl<BackendStreamEvent>(this as BackendStreamEvent, _$identity);

  /// Serializes this BackendStreamEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackendStreamEvent&&(identical(other.eventType, eventType) || other.eventType == eventType)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventType,const DeepCollectionEquality().hash(payload),timestamp);

@override
String toString() {
  return 'BackendStreamEvent(eventType: $eventType, payload: $payload, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $BackendStreamEventCopyWith<$Res>  {
  factory $BackendStreamEventCopyWith(BackendStreamEvent value, $Res Function(BackendStreamEvent) _then) = _$BackendStreamEventCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_type') EventType eventType, Map<String, dynamic> payload, String? timestamp
});




}
/// @nodoc
class _$BackendStreamEventCopyWithImpl<$Res>
    implements $BackendStreamEventCopyWith<$Res> {
  _$BackendStreamEventCopyWithImpl(this._self, this._then);

  final BackendStreamEvent _self;
  final $Res Function(BackendStreamEvent) _then;

/// Create a copy of BackendStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventType = null,Object? payload = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BackendStreamEvent].
extension BackendStreamEventPatterns on BackendStreamEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackendStreamEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackendStreamEvent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackendStreamEvent value)  $default,){
final _that = this;
switch (_that) {
case _BackendStreamEvent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackendStreamEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BackendStreamEvent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_type')  EventType eventType,  Map<String, dynamic> payload,  String? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackendStreamEvent() when $default != null:
return $default(_that.eventType,_that.payload,_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_type')  EventType eventType,  Map<String, dynamic> payload,  String? timestamp)  $default,) {final _that = this;
switch (_that) {
case _BackendStreamEvent():
return $default(_that.eventType,_that.payload,_that.timestamp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_type')  EventType eventType,  Map<String, dynamic> payload,  String? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _BackendStreamEvent() when $default != null:
return $default(_that.eventType,_that.payload,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BackendStreamEvent implements BackendStreamEvent {
  const _BackendStreamEvent({@JsonKey(name: 'event_type') required this.eventType, required final  Map<String, dynamic> payload, this.timestamp}): _payload = payload;
  factory _BackendStreamEvent.fromJson(Map<String, dynamic> json) => _$BackendStreamEventFromJson(json);

@override@JsonKey(name: 'event_type') final  EventType eventType;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  String? timestamp;

/// Create a copy of BackendStreamEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackendStreamEventCopyWith<_BackendStreamEvent> get copyWith => __$BackendStreamEventCopyWithImpl<_BackendStreamEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BackendStreamEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackendStreamEvent&&(identical(other.eventType, eventType) || other.eventType == eventType)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventType,const DeepCollectionEquality().hash(_payload),timestamp);

@override
String toString() {
  return 'BackendStreamEvent(eventType: $eventType, payload: $payload, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$BackendStreamEventCopyWith<$Res> implements $BackendStreamEventCopyWith<$Res> {
  factory _$BackendStreamEventCopyWith(_BackendStreamEvent value, $Res Function(_BackendStreamEvent) _then) = __$BackendStreamEventCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_type') EventType eventType, Map<String, dynamic> payload, String? timestamp
});




}
/// @nodoc
class __$BackendStreamEventCopyWithImpl<$Res>
    implements _$BackendStreamEventCopyWith<$Res> {
  __$BackendStreamEventCopyWithImpl(this._self, this._then);

  final _BackendStreamEvent _self;
  final $Res Function(_BackendStreamEvent) _then;

/// Create a copy of BackendStreamEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventType = null,Object? payload = null,Object? timestamp = freezed,}) {
  return _then(_BackendStreamEvent(
eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarEventModel {

 String get id;@JsonKey(name: 'user_id') String get userId; String get title; String? get description;@JsonKey(name: 'event_type') String get eventType;@JsonKey(name: 'start_time') DateTime get startTime;@JsonKey(name: 'end_time') DateTime? get endTime;@JsonKey(name: 'is_all_day') bool get isAllDay; String? get location; String get color; String get status;@JsonKey(name: 'related_id') String? get relatedId;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of CalendarEventModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventModelCopyWith<CalendarEventModel> get copyWith => _$CalendarEventModelCopyWithImpl<CalendarEventModel>(this as CalendarEventModel, _$identity);

  /// Serializes this CalendarEventModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEventModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.location, location) || other.location == location)&&(identical(other.color, color) || other.color == color)&&(identical(other.status, status) || other.status == status)&&(identical(other.relatedId, relatedId) || other.relatedId == relatedId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,description,eventType,startTime,endTime,isAllDay,location,color,status,relatedId,createdAt,updatedAt);

@override
String toString() {
  return 'CalendarEventModel(id: $id, userId: $userId, title: $title, description: $description, eventType: $eventType, startTime: $startTime, endTime: $endTime, isAllDay: $isAllDay, location: $location, color: $color, status: $status, relatedId: $relatedId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CalendarEventModelCopyWith<$Res>  {
  factory $CalendarEventModelCopyWith(CalendarEventModel value, $Res Function(CalendarEventModel) _then) = _$CalendarEventModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String title, String? description,@JsonKey(name: 'event_type') String eventType,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'is_all_day') bool isAllDay, String? location, String color, String status,@JsonKey(name: 'related_id') String? relatedId,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$CalendarEventModelCopyWithImpl<$Res>
    implements $CalendarEventModelCopyWith<$Res> {
  _$CalendarEventModelCopyWithImpl(this._self, this._then);

  final CalendarEventModel _self;
  final $Res Function(CalendarEventModel) _then;

/// Create a copy of CalendarEventModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? description = freezed,Object? eventType = null,Object? startTime = null,Object? endTime = freezed,Object? isAllDay = null,Object? location = freezed,Object? color = null,Object? status = null,Object? relatedId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,relatedId: freezed == relatedId ? _self.relatedId : relatedId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEventModel].
extension CalendarEventModelPatterns on CalendarEventModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEventModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEventModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEventModel value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEventModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEventModel value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEventModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String title,  String? description, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'is_all_day')  bool isAllDay,  String? location,  String color,  String status, @JsonKey(name: 'related_id')  String? relatedId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEventModel() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.description,_that.eventType,_that.startTime,_that.endTime,_that.isAllDay,_that.location,_that.color,_that.status,_that.relatedId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String title,  String? description, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'is_all_day')  bool isAllDay,  String? location,  String color,  String status, @JsonKey(name: 'related_id')  String? relatedId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CalendarEventModel():
return $default(_that.id,_that.userId,_that.title,_that.description,_that.eventType,_that.startTime,_that.endTime,_that.isAllDay,_that.location,_that.color,_that.status,_that.relatedId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String title,  String? description, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'is_all_day')  bool isAllDay,  String? location,  String color,  String status, @JsonKey(name: 'related_id')  String? relatedId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEventModel() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.description,_that.eventType,_that.startTime,_that.endTime,_that.isAllDay,_that.location,_that.color,_that.status,_that.relatedId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEventModel implements CalendarEventModel {
  const _CalendarEventModel({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.title, this.description, @JsonKey(name: 'event_type') this.eventType = 'study_session', @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') this.endTime, @JsonKey(name: 'is_all_day') this.isAllDay = false, this.location, this.color = '#8B5CF6', this.status = 'scheduled', @JsonKey(name: 'related_id') this.relatedId, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _CalendarEventModel.fromJson(Map<String, dynamic> json) => _$CalendarEventModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String title;
@override final  String? description;
@override@JsonKey(name: 'event_type') final  String eventType;
@override@JsonKey(name: 'start_time') final  DateTime startTime;
@override@JsonKey(name: 'end_time') final  DateTime? endTime;
@override@JsonKey(name: 'is_all_day') final  bool isAllDay;
@override final  String? location;
@override@JsonKey() final  String color;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'related_id') final  String? relatedId;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of CalendarEventModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventModelCopyWith<_CalendarEventModel> get copyWith => __$CalendarEventModelCopyWithImpl<_CalendarEventModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarEventModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEventModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.location, location) || other.location == location)&&(identical(other.color, color) || other.color == color)&&(identical(other.status, status) || other.status == status)&&(identical(other.relatedId, relatedId) || other.relatedId == relatedId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,description,eventType,startTime,endTime,isAllDay,location,color,status,relatedId,createdAt,updatedAt);

@override
String toString() {
  return 'CalendarEventModel(id: $id, userId: $userId, title: $title, description: $description, eventType: $eventType, startTime: $startTime, endTime: $endTime, isAllDay: $isAllDay, location: $location, color: $color, status: $status, relatedId: $relatedId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventModelCopyWith<$Res> implements $CalendarEventModelCopyWith<$Res> {
  factory _$CalendarEventModelCopyWith(_CalendarEventModel value, $Res Function(_CalendarEventModel) _then) = __$CalendarEventModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String title, String? description,@JsonKey(name: 'event_type') String eventType,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'is_all_day') bool isAllDay, String? location, String color, String status,@JsonKey(name: 'related_id') String? relatedId,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$CalendarEventModelCopyWithImpl<$Res>
    implements _$CalendarEventModelCopyWith<$Res> {
  __$CalendarEventModelCopyWithImpl(this._self, this._then);

  final _CalendarEventModel _self;
  final $Res Function(_CalendarEventModel) _then;

/// Create a copy of CalendarEventModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? description = freezed,Object? eventType = null,Object? startTime = null,Object? endTime = freezed,Object? isAllDay = null,Object? location = freezed,Object? color = null,Object? status = null,Object? relatedId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CalendarEventModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,relatedId: freezed == relatedId ? _self.relatedId : relatedId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

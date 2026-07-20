// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudySessionModel {

 String get id; String get subject; String get topic; int get durationMinutes; double get progress; DateTime get scheduledTime;
/// Create a copy of StudySessionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudySessionModelCopyWith<StudySessionModel> get copyWith => _$StudySessionModelCopyWithImpl<StudySessionModel>(this as StudySessionModel, _$identity);

  /// Serializes this StudySessionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudySessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,durationMinutes,progress,scheduledTime);

@override
String toString() {
  return 'StudySessionModel(id: $id, subject: $subject, topic: $topic, durationMinutes: $durationMinutes, progress: $progress, scheduledTime: $scheduledTime)';
}


}

/// @nodoc
abstract mixin class $StudySessionModelCopyWith<$Res>  {
  factory $StudySessionModelCopyWith(StudySessionModel value, $Res Function(StudySessionModel) _then) = _$StudySessionModelCopyWithImpl;
@useResult
$Res call({
 String id, String subject, String topic, int durationMinutes, double progress, DateTime scheduledTime
});




}
/// @nodoc
class _$StudySessionModelCopyWithImpl<$Res>
    implements $StudySessionModelCopyWith<$Res> {
  _$StudySessionModelCopyWithImpl(this._self, this._then);

  final StudySessionModel _self;
  final $Res Function(StudySessionModel) _then;

/// Create a copy of StudySessionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? durationMinutes = null,Object? progress = null,Object? scheduledTime = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StudySessionModel].
extension StudySessionModelPatterns on StudySessionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudySessionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudySessionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudySessionModel value)  $default,){
final _that = this;
switch (_that) {
case _StudySessionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudySessionModel value)?  $default,){
final _that = this;
switch (_that) {
case _StudySessionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subject,  String topic,  int durationMinutes,  double progress,  DateTime scheduledTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudySessionModel() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.durationMinutes,_that.progress,_that.scheduledTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subject,  String topic,  int durationMinutes,  double progress,  DateTime scheduledTime)  $default,) {final _that = this;
switch (_that) {
case _StudySessionModel():
return $default(_that.id,_that.subject,_that.topic,_that.durationMinutes,_that.progress,_that.scheduledTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subject,  String topic,  int durationMinutes,  double progress,  DateTime scheduledTime)?  $default,) {final _that = this;
switch (_that) {
case _StudySessionModel() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.durationMinutes,_that.progress,_that.scheduledTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudySessionModel implements StudySessionModel {
  const _StudySessionModel({required this.id, required this.subject, required this.topic, required this.durationMinutes, required this.progress, required this.scheduledTime});
  factory _StudySessionModel.fromJson(Map<String, dynamic> json) => _$StudySessionModelFromJson(json);

@override final  String id;
@override final  String subject;
@override final  String topic;
@override final  int durationMinutes;
@override final  double progress;
@override final  DateTime scheduledTime;

/// Create a copy of StudySessionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudySessionModelCopyWith<_StudySessionModel> get copyWith => __$StudySessionModelCopyWithImpl<_StudySessionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudySessionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudySessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,durationMinutes,progress,scheduledTime);

@override
String toString() {
  return 'StudySessionModel(id: $id, subject: $subject, topic: $topic, durationMinutes: $durationMinutes, progress: $progress, scheduledTime: $scheduledTime)';
}


}

/// @nodoc
abstract mixin class _$StudySessionModelCopyWith<$Res> implements $StudySessionModelCopyWith<$Res> {
  factory _$StudySessionModelCopyWith(_StudySessionModel value, $Res Function(_StudySessionModel) _then) = __$StudySessionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String subject, String topic, int durationMinutes, double progress, DateTime scheduledTime
});




}
/// @nodoc
class __$StudySessionModelCopyWithImpl<$Res>
    implements _$StudySessionModelCopyWith<$Res> {
  __$StudySessionModelCopyWithImpl(this._self, this._then);

  final _StudySessionModel _self;
  final $Res Function(_StudySessionModel) _then;

/// Create a copy of StudySessionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? durationMinutes = null,Object? progress = null,Object? scheduledTime = null,}) {
  return _then(_StudySessionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

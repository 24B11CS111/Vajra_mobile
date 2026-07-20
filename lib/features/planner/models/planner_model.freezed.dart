// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planner_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlannerTask {

 String get id; String get title; String get category; DateTime get startTime; DateTime get endTime; bool get isCompleted; String? get aiSuggestion;
/// Create a copy of PlannerTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannerTaskCopyWith<PlannerTask> get copyWith => _$PlannerTaskCopyWithImpl<PlannerTask>(this as PlannerTask, _$identity);

  /// Serializes this PlannerTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannerTask&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.aiSuggestion, aiSuggestion) || other.aiSuggestion == aiSuggestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,startTime,endTime,isCompleted,aiSuggestion);

@override
String toString() {
  return 'PlannerTask(id: $id, title: $title, category: $category, startTime: $startTime, endTime: $endTime, isCompleted: $isCompleted, aiSuggestion: $aiSuggestion)';
}


}

/// @nodoc
abstract mixin class $PlannerTaskCopyWith<$Res>  {
  factory $PlannerTaskCopyWith(PlannerTask value, $Res Function(PlannerTask) _then) = _$PlannerTaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, String category, DateTime startTime, DateTime endTime, bool isCompleted, String? aiSuggestion
});




}
/// @nodoc
class _$PlannerTaskCopyWithImpl<$Res>
    implements $PlannerTaskCopyWith<$Res> {
  _$PlannerTaskCopyWithImpl(this._self, this._then);

  final PlannerTask _self;
  final $Res Function(PlannerTask) _then;

/// Create a copy of PlannerTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? startTime = null,Object? endTime = null,Object? isCompleted = null,Object? aiSuggestion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,aiSuggestion: freezed == aiSuggestion ? _self.aiSuggestion : aiSuggestion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlannerTask].
extension PlannerTaskPatterns on PlannerTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlannerTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlannerTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlannerTask value)  $default,){
final _that = this;
switch (_that) {
case _PlannerTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlannerTask value)?  $default,){
final _that = this;
switch (_that) {
case _PlannerTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String category,  DateTime startTime,  DateTime endTime,  bool isCompleted,  String? aiSuggestion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlannerTask() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.startTime,_that.endTime,_that.isCompleted,_that.aiSuggestion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String category,  DateTime startTime,  DateTime endTime,  bool isCompleted,  String? aiSuggestion)  $default,) {final _that = this;
switch (_that) {
case _PlannerTask():
return $default(_that.id,_that.title,_that.category,_that.startTime,_that.endTime,_that.isCompleted,_that.aiSuggestion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String category,  DateTime startTime,  DateTime endTime,  bool isCompleted,  String? aiSuggestion)?  $default,) {final _that = this;
switch (_that) {
case _PlannerTask() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.startTime,_that.endTime,_that.isCompleted,_that.aiSuggestion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlannerTask implements PlannerTask {
  const _PlannerTask({required this.id, required this.title, required this.category, required this.startTime, required this.endTime, required this.isCompleted, this.aiSuggestion});
  factory _PlannerTask.fromJson(Map<String, dynamic> json) => _$PlannerTaskFromJson(json);

@override final  String id;
@override final  String title;
@override final  String category;
@override final  DateTime startTime;
@override final  DateTime endTime;
@override final  bool isCompleted;
@override final  String? aiSuggestion;

/// Create a copy of PlannerTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlannerTaskCopyWith<_PlannerTask> get copyWith => __$PlannerTaskCopyWithImpl<_PlannerTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannerTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlannerTask&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.aiSuggestion, aiSuggestion) || other.aiSuggestion == aiSuggestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,startTime,endTime,isCompleted,aiSuggestion);

@override
String toString() {
  return 'PlannerTask(id: $id, title: $title, category: $category, startTime: $startTime, endTime: $endTime, isCompleted: $isCompleted, aiSuggestion: $aiSuggestion)';
}


}

/// @nodoc
abstract mixin class _$PlannerTaskCopyWith<$Res> implements $PlannerTaskCopyWith<$Res> {
  factory _$PlannerTaskCopyWith(_PlannerTask value, $Res Function(_PlannerTask) _then) = __$PlannerTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String category, DateTime startTime, DateTime endTime, bool isCompleted, String? aiSuggestion
});




}
/// @nodoc
class __$PlannerTaskCopyWithImpl<$Res>
    implements _$PlannerTaskCopyWith<$Res> {
  __$PlannerTaskCopyWithImpl(this._self, this._then);

  final _PlannerTask _self;
  final $Res Function(_PlannerTask) _then;

/// Create a copy of PlannerTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? startTime = null,Object? endTime = null,Object? isCompleted = null,Object? aiSuggestion = freezed,}) {
  return _then(_PlannerTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,aiSuggestion: freezed == aiSuggestion ? _self.aiSuggestion : aiSuggestion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'briefing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BriefingModel {

 String get title; String get message; String get weatherContext; String get priorityTaskTitle; String get priorityTaskSubtitle; String get eveningWrapUp;
/// Create a copy of BriefingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefingModelCopyWith<BriefingModel> get copyWith => _$BriefingModelCopyWithImpl<BriefingModel>(this as BriefingModel, _$identity);

  /// Serializes this BriefingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefingModel&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.weatherContext, weatherContext) || other.weatherContext == weatherContext)&&(identical(other.priorityTaskTitle, priorityTaskTitle) || other.priorityTaskTitle == priorityTaskTitle)&&(identical(other.priorityTaskSubtitle, priorityTaskSubtitle) || other.priorityTaskSubtitle == priorityTaskSubtitle)&&(identical(other.eveningWrapUp, eveningWrapUp) || other.eveningWrapUp == eveningWrapUp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,message,weatherContext,priorityTaskTitle,priorityTaskSubtitle,eveningWrapUp);

@override
String toString() {
  return 'BriefingModel(title: $title, message: $message, weatherContext: $weatherContext, priorityTaskTitle: $priorityTaskTitle, priorityTaskSubtitle: $priorityTaskSubtitle, eveningWrapUp: $eveningWrapUp)';
}


}

/// @nodoc
abstract mixin class $BriefingModelCopyWith<$Res>  {
  factory $BriefingModelCopyWith(BriefingModel value, $Res Function(BriefingModel) _then) = _$BriefingModelCopyWithImpl;
@useResult
$Res call({
 String title, String message, String weatherContext, String priorityTaskTitle, String priorityTaskSubtitle, String eveningWrapUp
});




}
/// @nodoc
class _$BriefingModelCopyWithImpl<$Res>
    implements $BriefingModelCopyWith<$Res> {
  _$BriefingModelCopyWithImpl(this._self, this._then);

  final BriefingModel _self;
  final $Res Function(BriefingModel) _then;

/// Create a copy of BriefingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? message = null,Object? weatherContext = null,Object? priorityTaskTitle = null,Object? priorityTaskSubtitle = null,Object? eveningWrapUp = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,weatherContext: null == weatherContext ? _self.weatherContext : weatherContext // ignore: cast_nullable_to_non_nullable
as String,priorityTaskTitle: null == priorityTaskTitle ? _self.priorityTaskTitle : priorityTaskTitle // ignore: cast_nullable_to_non_nullable
as String,priorityTaskSubtitle: null == priorityTaskSubtitle ? _self.priorityTaskSubtitle : priorityTaskSubtitle // ignore: cast_nullable_to_non_nullable
as String,eveningWrapUp: null == eveningWrapUp ? _self.eveningWrapUp : eveningWrapUp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BriefingModel].
extension BriefingModelPatterns on BriefingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefingModel value)  $default,){
final _that = this;
switch (_that) {
case _BriefingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefingModel value)?  $default,){
final _that = this;
switch (_that) {
case _BriefingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String message,  String weatherContext,  String priorityTaskTitle,  String priorityTaskSubtitle,  String eveningWrapUp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefingModel() when $default != null:
return $default(_that.title,_that.message,_that.weatherContext,_that.priorityTaskTitle,_that.priorityTaskSubtitle,_that.eveningWrapUp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String message,  String weatherContext,  String priorityTaskTitle,  String priorityTaskSubtitle,  String eveningWrapUp)  $default,) {final _that = this;
switch (_that) {
case _BriefingModel():
return $default(_that.title,_that.message,_that.weatherContext,_that.priorityTaskTitle,_that.priorityTaskSubtitle,_that.eveningWrapUp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String message,  String weatherContext,  String priorityTaskTitle,  String priorityTaskSubtitle,  String eveningWrapUp)?  $default,) {final _that = this;
switch (_that) {
case _BriefingModel() when $default != null:
return $default(_that.title,_that.message,_that.weatherContext,_that.priorityTaskTitle,_that.priorityTaskSubtitle,_that.eveningWrapUp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefingModel implements BriefingModel {
  const _BriefingModel({required this.title, required this.message, required this.weatherContext, required this.priorityTaskTitle, required this.priorityTaskSubtitle, required this.eveningWrapUp});
  factory _BriefingModel.fromJson(Map<String, dynamic> json) => _$BriefingModelFromJson(json);

@override final  String title;
@override final  String message;
@override final  String weatherContext;
@override final  String priorityTaskTitle;
@override final  String priorityTaskSubtitle;
@override final  String eveningWrapUp;

/// Create a copy of BriefingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefingModelCopyWith<_BriefingModel> get copyWith => __$BriefingModelCopyWithImpl<_BriefingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefingModel&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.weatherContext, weatherContext) || other.weatherContext == weatherContext)&&(identical(other.priorityTaskTitle, priorityTaskTitle) || other.priorityTaskTitle == priorityTaskTitle)&&(identical(other.priorityTaskSubtitle, priorityTaskSubtitle) || other.priorityTaskSubtitle == priorityTaskSubtitle)&&(identical(other.eveningWrapUp, eveningWrapUp) || other.eveningWrapUp == eveningWrapUp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,message,weatherContext,priorityTaskTitle,priorityTaskSubtitle,eveningWrapUp);

@override
String toString() {
  return 'BriefingModel(title: $title, message: $message, weatherContext: $weatherContext, priorityTaskTitle: $priorityTaskTitle, priorityTaskSubtitle: $priorityTaskSubtitle, eveningWrapUp: $eveningWrapUp)';
}


}

/// @nodoc
abstract mixin class _$BriefingModelCopyWith<$Res> implements $BriefingModelCopyWith<$Res> {
  factory _$BriefingModelCopyWith(_BriefingModel value, $Res Function(_BriefingModel) _then) = __$BriefingModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String message, String weatherContext, String priorityTaskTitle, String priorityTaskSubtitle, String eveningWrapUp
});




}
/// @nodoc
class __$BriefingModelCopyWithImpl<$Res>
    implements _$BriefingModelCopyWith<$Res> {
  __$BriefingModelCopyWithImpl(this._self, this._then);

  final _BriefingModel _self;
  final $Res Function(_BriefingModel) _then;

/// Create a copy of BriefingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? message = null,Object? weatherContext = null,Object? priorityTaskTitle = null,Object? priorityTaskSubtitle = null,Object? eveningWrapUp = null,}) {
  return _then(_BriefingModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,weatherContext: null == weatherContext ? _self.weatherContext : weatherContext // ignore: cast_nullable_to_non_nullable
as String,priorityTaskTitle: null == priorityTaskTitle ? _self.priorityTaskTitle : priorityTaskTitle // ignore: cast_nullable_to_non_nullable
as String,priorityTaskSubtitle: null == priorityTaskSubtitle ? _self.priorityTaskSubtitle : priorityTaskSubtitle // ignore: cast_nullable_to_non_nullable
as String,eveningWrapUp: null == eveningWrapUp ? _self.eveningWrapUp : eveningWrapUp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

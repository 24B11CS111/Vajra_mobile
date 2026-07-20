// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'companion_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompanionProfileModel {

 CommunicationStyle get communicationStyle; ProactivityLevel get proactivityLevel; bool get requirePermissionForPlanner; bool get memoryTransparencyEnabled; bool get dailyBriefingEnabled;
/// Create a copy of CompanionProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanionProfileModelCopyWith<CompanionProfileModel> get copyWith => _$CompanionProfileModelCopyWithImpl<CompanionProfileModel>(this as CompanionProfileModel, _$identity);

  /// Serializes this CompanionProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanionProfileModel&&(identical(other.communicationStyle, communicationStyle) || other.communicationStyle == communicationStyle)&&(identical(other.proactivityLevel, proactivityLevel) || other.proactivityLevel == proactivityLevel)&&(identical(other.requirePermissionForPlanner, requirePermissionForPlanner) || other.requirePermissionForPlanner == requirePermissionForPlanner)&&(identical(other.memoryTransparencyEnabled, memoryTransparencyEnabled) || other.memoryTransparencyEnabled == memoryTransparencyEnabled)&&(identical(other.dailyBriefingEnabled, dailyBriefingEnabled) || other.dailyBriefingEnabled == dailyBriefingEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,communicationStyle,proactivityLevel,requirePermissionForPlanner,memoryTransparencyEnabled,dailyBriefingEnabled);

@override
String toString() {
  return 'CompanionProfileModel(communicationStyle: $communicationStyle, proactivityLevel: $proactivityLevel, requirePermissionForPlanner: $requirePermissionForPlanner, memoryTransparencyEnabled: $memoryTransparencyEnabled, dailyBriefingEnabled: $dailyBriefingEnabled)';
}


}

/// @nodoc
abstract mixin class $CompanionProfileModelCopyWith<$Res>  {
  factory $CompanionProfileModelCopyWith(CompanionProfileModel value, $Res Function(CompanionProfileModel) _then) = _$CompanionProfileModelCopyWithImpl;
@useResult
$Res call({
 CommunicationStyle communicationStyle, ProactivityLevel proactivityLevel, bool requirePermissionForPlanner, bool memoryTransparencyEnabled, bool dailyBriefingEnabled
});




}
/// @nodoc
class _$CompanionProfileModelCopyWithImpl<$Res>
    implements $CompanionProfileModelCopyWith<$Res> {
  _$CompanionProfileModelCopyWithImpl(this._self, this._then);

  final CompanionProfileModel _self;
  final $Res Function(CompanionProfileModel) _then;

/// Create a copy of CompanionProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? communicationStyle = null,Object? proactivityLevel = null,Object? requirePermissionForPlanner = null,Object? memoryTransparencyEnabled = null,Object? dailyBriefingEnabled = null,}) {
  return _then(_self.copyWith(
communicationStyle: null == communicationStyle ? _self.communicationStyle : communicationStyle // ignore: cast_nullable_to_non_nullable
as CommunicationStyle,proactivityLevel: null == proactivityLevel ? _self.proactivityLevel : proactivityLevel // ignore: cast_nullable_to_non_nullable
as ProactivityLevel,requirePermissionForPlanner: null == requirePermissionForPlanner ? _self.requirePermissionForPlanner : requirePermissionForPlanner // ignore: cast_nullable_to_non_nullable
as bool,memoryTransparencyEnabled: null == memoryTransparencyEnabled ? _self.memoryTransparencyEnabled : memoryTransparencyEnabled // ignore: cast_nullable_to_non_nullable
as bool,dailyBriefingEnabled: null == dailyBriefingEnabled ? _self.dailyBriefingEnabled : dailyBriefingEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CompanionProfileModel].
extension CompanionProfileModelPatterns on CompanionProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompanionProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompanionProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompanionProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _CompanionProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompanionProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _CompanionProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CommunicationStyle communicationStyle,  ProactivityLevel proactivityLevel,  bool requirePermissionForPlanner,  bool memoryTransparencyEnabled,  bool dailyBriefingEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompanionProfileModel() when $default != null:
return $default(_that.communicationStyle,_that.proactivityLevel,_that.requirePermissionForPlanner,_that.memoryTransparencyEnabled,_that.dailyBriefingEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CommunicationStyle communicationStyle,  ProactivityLevel proactivityLevel,  bool requirePermissionForPlanner,  bool memoryTransparencyEnabled,  bool dailyBriefingEnabled)  $default,) {final _that = this;
switch (_that) {
case _CompanionProfileModel():
return $default(_that.communicationStyle,_that.proactivityLevel,_that.requirePermissionForPlanner,_that.memoryTransparencyEnabled,_that.dailyBriefingEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CommunicationStyle communicationStyle,  ProactivityLevel proactivityLevel,  bool requirePermissionForPlanner,  bool memoryTransparencyEnabled,  bool dailyBriefingEnabled)?  $default,) {final _that = this;
switch (_that) {
case _CompanionProfileModel() when $default != null:
return $default(_that.communicationStyle,_that.proactivityLevel,_that.requirePermissionForPlanner,_that.memoryTransparencyEnabled,_that.dailyBriefingEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompanionProfileModel implements CompanionProfileModel {
  const _CompanionProfileModel({this.communicationStyle = CommunicationStyle.reflective, this.proactivityLevel = ProactivityLevel.balanced, this.requirePermissionForPlanner = true, this.memoryTransparencyEnabled = true, this.dailyBriefingEnabled = true});
  factory _CompanionProfileModel.fromJson(Map<String, dynamic> json) => _$CompanionProfileModelFromJson(json);

@override@JsonKey() final  CommunicationStyle communicationStyle;
@override@JsonKey() final  ProactivityLevel proactivityLevel;
@override@JsonKey() final  bool requirePermissionForPlanner;
@override@JsonKey() final  bool memoryTransparencyEnabled;
@override@JsonKey() final  bool dailyBriefingEnabled;

/// Create a copy of CompanionProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanionProfileModelCopyWith<_CompanionProfileModel> get copyWith => __$CompanionProfileModelCopyWithImpl<_CompanionProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanionProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanionProfileModel&&(identical(other.communicationStyle, communicationStyle) || other.communicationStyle == communicationStyle)&&(identical(other.proactivityLevel, proactivityLevel) || other.proactivityLevel == proactivityLevel)&&(identical(other.requirePermissionForPlanner, requirePermissionForPlanner) || other.requirePermissionForPlanner == requirePermissionForPlanner)&&(identical(other.memoryTransparencyEnabled, memoryTransparencyEnabled) || other.memoryTransparencyEnabled == memoryTransparencyEnabled)&&(identical(other.dailyBriefingEnabled, dailyBriefingEnabled) || other.dailyBriefingEnabled == dailyBriefingEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,communicationStyle,proactivityLevel,requirePermissionForPlanner,memoryTransparencyEnabled,dailyBriefingEnabled);

@override
String toString() {
  return 'CompanionProfileModel(communicationStyle: $communicationStyle, proactivityLevel: $proactivityLevel, requirePermissionForPlanner: $requirePermissionForPlanner, memoryTransparencyEnabled: $memoryTransparencyEnabled, dailyBriefingEnabled: $dailyBriefingEnabled)';
}


}

/// @nodoc
abstract mixin class _$CompanionProfileModelCopyWith<$Res> implements $CompanionProfileModelCopyWith<$Res> {
  factory _$CompanionProfileModelCopyWith(_CompanionProfileModel value, $Res Function(_CompanionProfileModel) _then) = __$CompanionProfileModelCopyWithImpl;
@override @useResult
$Res call({
 CommunicationStyle communicationStyle, ProactivityLevel proactivityLevel, bool requirePermissionForPlanner, bool memoryTransparencyEnabled, bool dailyBriefingEnabled
});




}
/// @nodoc
class __$CompanionProfileModelCopyWithImpl<$Res>
    implements _$CompanionProfileModelCopyWith<$Res> {
  __$CompanionProfileModelCopyWithImpl(this._self, this._then);

  final _CompanionProfileModel _self;
  final $Res Function(_CompanionProfileModel) _then;

/// Create a copy of CompanionProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? communicationStyle = null,Object? proactivityLevel = null,Object? requirePermissionForPlanner = null,Object? memoryTransparencyEnabled = null,Object? dailyBriefingEnabled = null,}) {
  return _then(_CompanionProfileModel(
communicationStyle: null == communicationStyle ? _self.communicationStyle : communicationStyle // ignore: cast_nullable_to_non_nullable
as CommunicationStyle,proactivityLevel: null == proactivityLevel ? _self.proactivityLevel : proactivityLevel // ignore: cast_nullable_to_non_nullable
as ProactivityLevel,requirePermissionForPlanner: null == requirePermissionForPlanner ? _self.requirePermissionForPlanner : requirePermissionForPlanner // ignore: cast_nullable_to_non_nullable
as bool,memoryTransparencyEnabled: null == memoryTransparencyEnabled ? _self.memoryTransparencyEnabled : memoryTransparencyEnabled // ignore: cast_nullable_to_non_nullable
as bool,dailyBriefingEnabled: null == dailyBriefingEnabled ? _self.dailyBriefingEnabled : dailyBriefingEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

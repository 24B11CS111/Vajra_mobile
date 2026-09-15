// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memory_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemoryModel {

 String get id; String get content; String get category; double get importanceScore; bool get isPinned; DateTime get createdAt; String get source;
/// Create a copy of MemoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryModelCopyWith<MemoryModel> get copyWith => _$MemoryModelCopyWithImpl<MemoryModel>(this as MemoryModel, _$identity);

  /// Serializes this MemoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category)&&(identical(other.importanceScore, importanceScore) || other.importanceScore == importanceScore)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,category,importanceScore,isPinned,createdAt,source);

@override
String toString() {
  return 'MemoryModel(id: $id, content: $content, category: $category, importanceScore: $importanceScore, isPinned: $isPinned, createdAt: $createdAt, source: $source)';
}


}

/// @nodoc
abstract mixin class $MemoryModelCopyWith<$Res>  {
  factory $MemoryModelCopyWith(MemoryModel value, $Res Function(MemoryModel) _then) = _$MemoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String content, String category, double importanceScore, bool isPinned, DateTime createdAt, String source
});




}
/// @nodoc
class _$MemoryModelCopyWithImpl<$Res>
    implements $MemoryModelCopyWith<$Res> {
  _$MemoryModelCopyWithImpl(this._self, this._then);

  final MemoryModel _self;
  final $Res Function(MemoryModel) _then;

/// Create a copy of MemoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? category = null,Object? importanceScore = null,Object? isPinned = null,Object? createdAt = null,Object? source = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,importanceScore: null == importanceScore ? _self.importanceScore : importanceScore // ignore: cast_nullable_to_non_nullable
as double,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryModel].
extension MemoryModelPatterns on MemoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryModel value)  $default,){
final _that = this;
switch (_that) {
case _MemoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String content,  String category,  double importanceScore,  bool isPinned,  DateTime createdAt,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryModel() when $default != null:
return $default(_that.id,_that.content,_that.category,_that.importanceScore,_that.isPinned,_that.createdAt,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String content,  String category,  double importanceScore,  bool isPinned,  DateTime createdAt,  String source)  $default,) {final _that = this;
switch (_that) {
case _MemoryModel():
return $default(_that.id,_that.content,_that.category,_that.importanceScore,_that.isPinned,_that.createdAt,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String content,  String category,  double importanceScore,  bool isPinned,  DateTime createdAt,  String source)?  $default,) {final _that = this;
switch (_that) {
case _MemoryModel() when $default != null:
return $default(_that.id,_that.content,_that.category,_that.importanceScore,_that.isPinned,_that.createdAt,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemoryModel implements MemoryModel {
  const _MemoryModel({required this.id, required this.content, required this.category, required this.importanceScore, required this.isPinned, required this.createdAt, this.source = 'VAJRA Core'});
  factory _MemoryModel.fromJson(Map<String, dynamic> json) => _$MemoryModelFromJson(json);

@override final  String id;
@override final  String content;
@override final  String category;
@override final  double importanceScore;
@override final  bool isPinned;
@override final  DateTime createdAt;
@override@JsonKey() final  String source;

/// Create a copy of MemoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryModelCopyWith<_MemoryModel> get copyWith => __$MemoryModelCopyWithImpl<_MemoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category)&&(identical(other.importanceScore, importanceScore) || other.importanceScore == importanceScore)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,category,importanceScore,isPinned,createdAt,source);

@override
String toString() {
  return 'MemoryModel(id: $id, content: $content, category: $category, importanceScore: $importanceScore, isPinned: $isPinned, createdAt: $createdAt, source: $source)';
}


}

/// @nodoc
abstract mixin class _$MemoryModelCopyWith<$Res> implements $MemoryModelCopyWith<$Res> {
  factory _$MemoryModelCopyWith(_MemoryModel value, $Res Function(_MemoryModel) _then) = __$MemoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String content, String category, double importanceScore, bool isPinned, DateTime createdAt, String source
});




}
/// @nodoc
class __$MemoryModelCopyWithImpl<$Res>
    implements _$MemoryModelCopyWith<$Res> {
  __$MemoryModelCopyWithImpl(this._self, this._then);

  final _MemoryModel _self;
  final $Res Function(_MemoryModel) _then;

/// Create a copy of MemoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? category = null,Object? importanceScore = null,Object? isPinned = null,Object? createdAt = null,Object? source = null,}) {
  return _then(_MemoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,importanceScore: null == importanceScore ? _self.importanceScore : importanceScore // ignore: cast_nullable_to_non_nullable
as double,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

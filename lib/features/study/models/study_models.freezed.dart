// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubjectModel {

 String get id;@JsonKey(name: 'user_id') String get userId; String get name; String? get description; String get color; String get priority;@JsonKey(name: 'exam_date') DateTime? get examDate;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of SubjectModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubjectModelCopyWith<SubjectModel> get copyWith => _$SubjectModelCopyWithImpl<SubjectModel>(this as SubjectModel, _$identity);

  /// Serializes this SubjectModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubjectModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.examDate, examDate) || other.examDate == examDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,description,color,priority,examDate,createdAt,updatedAt);

@override
String toString() {
  return 'SubjectModel(id: $id, userId: $userId, name: $name, description: $description, color: $color, priority: $priority, examDate: $examDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SubjectModelCopyWith<$Res>  {
  factory $SubjectModelCopyWith(SubjectModel value, $Res Function(SubjectModel) _then) = _$SubjectModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, String? description, String color, String priority,@JsonKey(name: 'exam_date') DateTime? examDate,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$SubjectModelCopyWithImpl<$Res>
    implements $SubjectModelCopyWith<$Res> {
  _$SubjectModelCopyWithImpl(this._self, this._then);

  final SubjectModel _self;
  final $Res Function(SubjectModel) _then;

/// Create a copy of SubjectModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? description = freezed,Object? color = null,Object? priority = null,Object? examDate = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,examDate: freezed == examDate ? _self.examDate : examDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubjectModel].
extension SubjectModelPatterns on SubjectModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubjectModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubjectModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubjectModel value)  $default,){
final _that = this;
switch (_that) {
case _SubjectModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubjectModel value)?  $default,){
final _that = this;
switch (_that) {
case _SubjectModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String? description,  String color,  String priority, @JsonKey(name: 'exam_date')  DateTime? examDate, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubjectModel() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.description,_that.color,_that.priority,_that.examDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String? description,  String color,  String priority, @JsonKey(name: 'exam_date')  DateTime? examDate, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SubjectModel():
return $default(_that.id,_that.userId,_that.name,_that.description,_that.color,_that.priority,_that.examDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String name,  String? description,  String color,  String priority, @JsonKey(name: 'exam_date')  DateTime? examDate, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SubjectModel() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.description,_that.color,_that.priority,_that.examDate,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubjectModel implements SubjectModel {
  const _SubjectModel({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.name, this.description, this.color = '#2563EB', this.priority = 'medium', @JsonKey(name: 'exam_date') this.examDate, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _SubjectModel.fromJson(Map<String, dynamic> json) => _$SubjectModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String name;
@override final  String? description;
@override@JsonKey() final  String color;
@override@JsonKey() final  String priority;
@override@JsonKey(name: 'exam_date') final  DateTime? examDate;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of SubjectModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubjectModelCopyWith<_SubjectModel> get copyWith => __$SubjectModelCopyWithImpl<_SubjectModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubjectModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubjectModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.examDate, examDate) || other.examDate == examDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,description,color,priority,examDate,createdAt,updatedAt);

@override
String toString() {
  return 'SubjectModel(id: $id, userId: $userId, name: $name, description: $description, color: $color, priority: $priority, examDate: $examDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SubjectModelCopyWith<$Res> implements $SubjectModelCopyWith<$Res> {
  factory _$SubjectModelCopyWith(_SubjectModel value, $Res Function(_SubjectModel) _then) = __$SubjectModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name, String? description, String color, String priority,@JsonKey(name: 'exam_date') DateTime? examDate,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$SubjectModelCopyWithImpl<$Res>
    implements _$SubjectModelCopyWith<$Res> {
  __$SubjectModelCopyWithImpl(this._self, this._then);

  final _SubjectModel _self;
  final $Res Function(_SubjectModel) _then;

/// Create a copy of SubjectModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? description = freezed,Object? color = null,Object? priority = null,Object? examDate = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SubjectModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,examDate: freezed == examDate ? _self.examDate : examDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AssignmentModel {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'subject_id') String? get subjectId;@JsonKey(name: 'subject_name') String get subjectName; String get title; String? get description;@JsonKey(name: 'due_date') DateTime? get dueDate;@JsonKey(name: 'due_time') String? get dueTime; String get priority; String get status;@JsonKey(name: 'attachment_url') String? get attachmentUrl;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of AssignmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignmentModelCopyWith<AssignmentModel> get copyWith => _$AssignmentModelCopyWithImpl<AssignmentModel>(this as AssignmentModel, _$identity);

  /// Serializes this AssignmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.dueTime, dueTime) || other.dueTime == dueTime)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,subjectId,subjectName,title,description,dueDate,dueTime,priority,status,attachmentUrl,createdAt,updatedAt);

@override
String toString() {
  return 'AssignmentModel(id: $id, userId: $userId, subjectId: $subjectId, subjectName: $subjectName, title: $title, description: $description, dueDate: $dueDate, dueTime: $dueTime, priority: $priority, status: $status, attachmentUrl: $attachmentUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AssignmentModelCopyWith<$Res>  {
  factory $AssignmentModelCopyWith(AssignmentModel value, $Res Function(AssignmentModel) _then) = _$AssignmentModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'subject_id') String? subjectId,@JsonKey(name: 'subject_name') String subjectName, String title, String? description,@JsonKey(name: 'due_date') DateTime? dueDate,@JsonKey(name: 'due_time') String? dueTime, String priority, String status,@JsonKey(name: 'attachment_url') String? attachmentUrl,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$AssignmentModelCopyWithImpl<$Res>
    implements $AssignmentModelCopyWith<$Res> {
  _$AssignmentModelCopyWithImpl(this._self, this._then);

  final AssignmentModel _self;
  final $Res Function(AssignmentModel) _then;

/// Create a copy of AssignmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? subjectId = freezed,Object? subjectName = null,Object? title = null,Object? description = freezed,Object? dueDate = freezed,Object? dueTime = freezed,Object? priority = null,Object? status = null,Object? attachmentUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dueTime: freezed == dueTime ? _self.dueTime : dueTime // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssignmentModel].
extension AssignmentModelPatterns on AssignmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssignmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssignmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssignmentModel value)  $default,){
final _that = this;
switch (_that) {
case _AssignmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssignmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _AssignmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'subject_id')  String? subjectId, @JsonKey(name: 'subject_name')  String subjectName,  String title,  String? description, @JsonKey(name: 'due_date')  DateTime? dueDate, @JsonKey(name: 'due_time')  String? dueTime,  String priority,  String status, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssignmentModel() when $default != null:
return $default(_that.id,_that.userId,_that.subjectId,_that.subjectName,_that.title,_that.description,_that.dueDate,_that.dueTime,_that.priority,_that.status,_that.attachmentUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'subject_id')  String? subjectId, @JsonKey(name: 'subject_name')  String subjectName,  String title,  String? description, @JsonKey(name: 'due_date')  DateTime? dueDate, @JsonKey(name: 'due_time')  String? dueTime,  String priority,  String status, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AssignmentModel():
return $default(_that.id,_that.userId,_that.subjectId,_that.subjectName,_that.title,_that.description,_that.dueDate,_that.dueTime,_that.priority,_that.status,_that.attachmentUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'subject_id')  String? subjectId, @JsonKey(name: 'subject_name')  String subjectName,  String title,  String? description, @JsonKey(name: 'due_date')  DateTime? dueDate, @JsonKey(name: 'due_time')  String? dueTime,  String priority,  String status, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AssignmentModel() when $default != null:
return $default(_that.id,_that.userId,_that.subjectId,_that.subjectName,_that.title,_that.description,_that.dueDate,_that.dueTime,_that.priority,_that.status,_that.attachmentUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssignmentModel implements AssignmentModel {
  const _AssignmentModel({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'subject_id') this.subjectId, @JsonKey(name: 'subject_name') this.subjectName = 'General', required this.title, this.description, @JsonKey(name: 'due_date') this.dueDate, @JsonKey(name: 'due_time') this.dueTime, this.priority = 'medium', this.status = 'NOT_STARTED', @JsonKey(name: 'attachment_url') this.attachmentUrl, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _AssignmentModel.fromJson(Map<String, dynamic> json) => _$AssignmentModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'subject_id') final  String? subjectId;
@override@JsonKey(name: 'subject_name') final  String subjectName;
@override final  String title;
@override final  String? description;
@override@JsonKey(name: 'due_date') final  DateTime? dueDate;
@override@JsonKey(name: 'due_time') final  String? dueTime;
@override@JsonKey() final  String priority;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'attachment_url') final  String? attachmentUrl;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of AssignmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignmentModelCopyWith<_AssignmentModel> get copyWith => __$AssignmentModelCopyWithImpl<_AssignmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssignmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssignmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.dueTime, dueTime) || other.dueTime == dueTime)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,subjectId,subjectName,title,description,dueDate,dueTime,priority,status,attachmentUrl,createdAt,updatedAt);

@override
String toString() {
  return 'AssignmentModel(id: $id, userId: $userId, subjectId: $subjectId, subjectName: $subjectName, title: $title, description: $description, dueDate: $dueDate, dueTime: $dueTime, priority: $priority, status: $status, attachmentUrl: $attachmentUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AssignmentModelCopyWith<$Res> implements $AssignmentModelCopyWith<$Res> {
  factory _$AssignmentModelCopyWith(_AssignmentModel value, $Res Function(_AssignmentModel) _then) = __$AssignmentModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'subject_id') String? subjectId,@JsonKey(name: 'subject_name') String subjectName, String title, String? description,@JsonKey(name: 'due_date') DateTime? dueDate,@JsonKey(name: 'due_time') String? dueTime, String priority, String status,@JsonKey(name: 'attachment_url') String? attachmentUrl,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$AssignmentModelCopyWithImpl<$Res>
    implements _$AssignmentModelCopyWith<$Res> {
  __$AssignmentModelCopyWithImpl(this._self, this._then);

  final _AssignmentModel _self;
  final $Res Function(_AssignmentModel) _then;

/// Create a copy of AssignmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? subjectId = freezed,Object? subjectName = null,Object? title = null,Object? description = freezed,Object? dueDate = freezed,Object? dueTime = freezed,Object? priority = null,Object? status = null,Object? attachmentUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_AssignmentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dueTime: freezed == dueTime ? _self.dueTime : dueTime // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

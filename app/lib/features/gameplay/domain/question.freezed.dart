// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Question {

 String get id; String get textAr; String get textEn; String get packId;// ── Added in Mission 3: Question Engine V2 ────────────────────────────
/// Lifecycle status. Defaults to 'active' so existing Firestore docs
/// without this field are treated as active (backward compatible).
/// See [QuestionStatus] for valid values.
 String get status;/// Content intensity level. Defaults to 'medium'.
/// See [IntensityLevel] for valid values.
 String get intensity;/// Audience age rating. Defaults to 'all' (no restriction).
/// See [AgeRating] for valid values.
 String get ageRating;/// Semantic version of the question text (for future re-seeding audits).
 int get version;
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCopyWith<Question> get copyWith => _$QuestionCopyWithImpl<Question>(this as Question, _$identity);

  /// Serializes this Question to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Question&&(identical(other.id, id) || other.id == id)&&(identical(other.textAr, textAr) || other.textAr == textAr)&&(identical(other.textEn, textEn) || other.textEn == textEn)&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.status, status) || other.status == status)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.ageRating, ageRating) || other.ageRating == ageRating)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,textAr,textEn,packId,status,intensity,ageRating,version);

@override
String toString() {
  return 'Question(id: $id, textAr: $textAr, textEn: $textEn, packId: $packId, status: $status, intensity: $intensity, ageRating: $ageRating, version: $version)';
}


}

/// @nodoc
abstract mixin class $QuestionCopyWith<$Res>  {
  factory $QuestionCopyWith(Question value, $Res Function(Question) _then) = _$QuestionCopyWithImpl;
@useResult
$Res call({
 String id, String textAr, String textEn, String packId, String status, String intensity, String ageRating, int version
});




}
/// @nodoc
class _$QuestionCopyWithImpl<$Res>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._self, this._then);

  final Question _self;
  final $Res Function(Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? textAr = null,Object? textEn = null,Object? packId = null,Object? status = null,Object? intensity = null,Object? ageRating = null,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textAr: null == textAr ? _self.textAr : textAr // ignore: cast_nullable_to_non_nullable
as String,textEn: null == textEn ? _self.textEn : textEn // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as String,ageRating: null == ageRating ? _self.ageRating : ageRating // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Question].
extension QuestionPatterns on Question {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Question value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Question value)  $default,){
final _that = this;
switch (_that) {
case _Question():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Question value)?  $default,){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String textAr,  String textEn,  String packId,  String status,  String intensity,  String ageRating,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.textAr,_that.textEn,_that.packId,_that.status,_that.intensity,_that.ageRating,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String textAr,  String textEn,  String packId,  String status,  String intensity,  String ageRating,  int version)  $default,) {final _that = this;
switch (_that) {
case _Question():
return $default(_that.id,_that.textAr,_that.textEn,_that.packId,_that.status,_that.intensity,_that.ageRating,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String textAr,  String textEn,  String packId,  String status,  String intensity,  String ageRating,  int version)?  $default,) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.textAr,_that.textEn,_that.packId,_that.status,_that.intensity,_that.ageRating,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Question implements Question {
  const _Question({required this.id, required this.textAr, required this.textEn, required this.packId, this.status = 'active', this.intensity = 'medium', this.ageRating = 'all', this.version = 1});
  factory _Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);

@override final  String id;
@override final  String textAr;
@override final  String textEn;
@override final  String packId;
// ── Added in Mission 3: Question Engine V2 ────────────────────────────
/// Lifecycle status. Defaults to 'active' so existing Firestore docs
/// without this field are treated as active (backward compatible).
/// See [QuestionStatus] for valid values.
@override@JsonKey() final  String status;
/// Content intensity level. Defaults to 'medium'.
/// See [IntensityLevel] for valid values.
@override@JsonKey() final  String intensity;
/// Audience age rating. Defaults to 'all' (no restriction).
/// See [AgeRating] for valid values.
@override@JsonKey() final  String ageRating;
/// Semantic version of the question text (for future re-seeding audits).
@override@JsonKey() final  int version;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionCopyWith<_Question> get copyWith => __$QuestionCopyWithImpl<_Question>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Question&&(identical(other.id, id) || other.id == id)&&(identical(other.textAr, textAr) || other.textAr == textAr)&&(identical(other.textEn, textEn) || other.textEn == textEn)&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.status, status) || other.status == status)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.ageRating, ageRating) || other.ageRating == ageRating)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,textAr,textEn,packId,status,intensity,ageRating,version);

@override
String toString() {
  return 'Question(id: $id, textAr: $textAr, textEn: $textEn, packId: $packId, status: $status, intensity: $intensity, ageRating: $ageRating, version: $version)';
}


}

/// @nodoc
abstract mixin class _$QuestionCopyWith<$Res> implements $QuestionCopyWith<$Res> {
  factory _$QuestionCopyWith(_Question value, $Res Function(_Question) _then) = __$QuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String textAr, String textEn, String packId, String status, String intensity, String ageRating, int version
});




}
/// @nodoc
class __$QuestionCopyWithImpl<$Res>
    implements _$QuestionCopyWith<$Res> {
  __$QuestionCopyWithImpl(this._self, this._then);

  final _Question _self;
  final $Res Function(_Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? textAr = null,Object? textEn = null,Object? packId = null,Object? status = null,Object? intensity = null,Object? ageRating = null,Object? version = null,}) {
  return _then(_Question(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textAr: null == textAr ? _self.textAr : textAr // ignore: cast_nullable_to_non_nullable
as String,textEn: null == textEn ? _self.textEn : textEn // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as String,ageRating: null == ageRating ? _self.ageRating : ageRating // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionQuestion {

 String get id; String get textAr; String get textEn; String get packId;
/// Create a copy of SessionQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionQuestionCopyWith<SessionQuestion> get copyWith => _$SessionQuestionCopyWithImpl<SessionQuestion>(this as SessionQuestion, _$identity);

  /// Serializes this SessionQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.textAr, textAr) || other.textAr == textAr)&&(identical(other.textEn, textEn) || other.textEn == textEn)&&(identical(other.packId, packId) || other.packId == packId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,textAr,textEn,packId);

@override
String toString() {
  return 'SessionQuestion(id: $id, textAr: $textAr, textEn: $textEn, packId: $packId)';
}


}

/// @nodoc
abstract mixin class $SessionQuestionCopyWith<$Res>  {
  factory $SessionQuestionCopyWith(SessionQuestion value, $Res Function(SessionQuestion) _then) = _$SessionQuestionCopyWithImpl;
@useResult
$Res call({
 String id, String textAr, String textEn, String packId
});




}
/// @nodoc
class _$SessionQuestionCopyWithImpl<$Res>
    implements $SessionQuestionCopyWith<$Res> {
  _$SessionQuestionCopyWithImpl(this._self, this._then);

  final SessionQuestion _self;
  final $Res Function(SessionQuestion) _then;

/// Create a copy of SessionQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? textAr = null,Object? textEn = null,Object? packId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textAr: null == textAr ? _self.textAr : textAr // ignore: cast_nullable_to_non_nullable
as String,textEn: null == textEn ? _self.textEn : textEn // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionQuestion].
extension SessionQuestionPatterns on SessionQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionQuestion value)  $default,){
final _that = this;
switch (_that) {
case _SessionQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _SessionQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String textAr,  String textEn,  String packId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionQuestion() when $default != null:
return $default(_that.id,_that.textAr,_that.textEn,_that.packId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String textAr,  String textEn,  String packId)  $default,) {final _that = this;
switch (_that) {
case _SessionQuestion():
return $default(_that.id,_that.textAr,_that.textEn,_that.packId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String textAr,  String textEn,  String packId)?  $default,) {final _that = this;
switch (_that) {
case _SessionQuestion() when $default != null:
return $default(_that.id,_that.textAr,_that.textEn,_that.packId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionQuestion implements SessionQuestion {
  const _SessionQuestion({required this.id, required this.textAr, this.textEn = '', this.packId = ''});
  factory _SessionQuestion.fromJson(Map<String, dynamic> json) => _$SessionQuestionFromJson(json);

@override final  String id;
@override final  String textAr;
@override@JsonKey() final  String textEn;
@override@JsonKey() final  String packId;

/// Create a copy of SessionQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionQuestionCopyWith<_SessionQuestion> get copyWith => __$SessionQuestionCopyWithImpl<_SessionQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.textAr, textAr) || other.textAr == textAr)&&(identical(other.textEn, textEn) || other.textEn == textEn)&&(identical(other.packId, packId) || other.packId == packId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,textAr,textEn,packId);

@override
String toString() {
  return 'SessionQuestion(id: $id, textAr: $textAr, textEn: $textEn, packId: $packId)';
}


}

/// @nodoc
abstract mixin class _$SessionQuestionCopyWith<$Res> implements $SessionQuestionCopyWith<$Res> {
  factory _$SessionQuestionCopyWith(_SessionQuestion value, $Res Function(_SessionQuestion) _then) = __$SessionQuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String textAr, String textEn, String packId
});




}
/// @nodoc
class __$SessionQuestionCopyWithImpl<$Res>
    implements _$SessionQuestionCopyWith<$Res> {
  __$SessionQuestionCopyWithImpl(this._self, this._then);

  final _SessionQuestion _self;
  final $Res Function(_SessionQuestion) _then;

/// Create a copy of SessionQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? textAr = null,Object? textEn = null,Object? packId = null,}) {
  return _then(_SessionQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textAr: null == textAr ? _self.textAr : textAr // ignore: cast_nullable_to_non_nullable
as String,textEn: null == textEn ? _self.textEn : textEn // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

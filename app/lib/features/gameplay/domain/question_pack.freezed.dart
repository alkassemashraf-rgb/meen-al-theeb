// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuestionPack {

 String get packId; String get name; String get description; String get language; int get questionCount; String get icon; bool get isPremium; DateTime? get createdAt;
/// Create a copy of QuestionPack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionPackCopyWith<QuestionPack> get copyWith => _$QuestionPackCopyWithImpl<QuestionPack>(this as QuestionPack, _$identity);

  /// Serializes this QuestionPack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionPack&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.language, language) || other.language == language)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packId,name,description,language,questionCount,icon,isPremium,createdAt);

@override
String toString() {
  return 'QuestionPack(packId: $packId, name: $name, description: $description, language: $language, questionCount: $questionCount, icon: $icon, isPremium: $isPremium, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $QuestionPackCopyWith<$Res>  {
  factory $QuestionPackCopyWith(QuestionPack value, $Res Function(QuestionPack) _then) = _$QuestionPackCopyWithImpl;
@useResult
$Res call({
 String packId, String name, String description, String language, int questionCount, String icon, bool isPremium, DateTime? createdAt
});




}
/// @nodoc
class _$QuestionPackCopyWithImpl<$Res>
    implements $QuestionPackCopyWith<$Res> {
  _$QuestionPackCopyWithImpl(this._self, this._then);

  final QuestionPack _self;
  final $Res Function(QuestionPack) _then;

/// Create a copy of QuestionPack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? packId = null,Object? name = null,Object? description = null,Object? language = null,Object? questionCount = null,Object? icon = null,Object? isPremium = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionPack].
extension QuestionPackPatterns on QuestionPack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionPack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionPack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionPack value)  $default,){
final _that = this;
switch (_that) {
case _QuestionPack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionPack value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionPack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String packId,  String name,  String description,  String language,  int questionCount,  String icon,  bool isPremium,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionPack() when $default != null:
return $default(_that.packId,_that.name,_that.description,_that.language,_that.questionCount,_that.icon,_that.isPremium,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String packId,  String name,  String description,  String language,  int questionCount,  String icon,  bool isPremium,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _QuestionPack():
return $default(_that.packId,_that.name,_that.description,_that.language,_that.questionCount,_that.icon,_that.isPremium,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String packId,  String name,  String description,  String language,  int questionCount,  String icon,  bool isPremium,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _QuestionPack() when $default != null:
return $default(_that.packId,_that.name,_that.description,_that.language,_that.questionCount,_that.icon,_that.isPremium,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionPack implements QuestionPack {
  const _QuestionPack({required this.packId, required this.name, this.description = '', this.language = 'ar', this.questionCount = 0, this.icon = '🐺', this.isPremium = false, this.createdAt});
  factory _QuestionPack.fromJson(Map<String, dynamic> json) => _$QuestionPackFromJson(json);

@override final  String packId;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String language;
@override@JsonKey() final  int questionCount;
@override@JsonKey() final  String icon;
@override@JsonKey() final  bool isPremium;
@override final  DateTime? createdAt;

/// Create a copy of QuestionPack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionPackCopyWith<_QuestionPack> get copyWith => __$QuestionPackCopyWithImpl<_QuestionPack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionPackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionPack&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.language, language) || other.language == language)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packId,name,description,language,questionCount,icon,isPremium,createdAt);

@override
String toString() {
  return 'QuestionPack(packId: $packId, name: $name, description: $description, language: $language, questionCount: $questionCount, icon: $icon, isPremium: $isPremium, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$QuestionPackCopyWith<$Res> implements $QuestionPackCopyWith<$Res> {
  factory _$QuestionPackCopyWith(_QuestionPack value, $Res Function(_QuestionPack) _then) = __$QuestionPackCopyWithImpl;
@override @useResult
$Res call({
 String packId, String name, String description, String language, int questionCount, String icon, bool isPremium, DateTime? createdAt
});




}
/// @nodoc
class __$QuestionPackCopyWithImpl<$Res>
    implements _$QuestionPackCopyWith<$Res> {
  __$QuestionPackCopyWithImpl(this._self, this._then);

  final _QuestionPack _self;
  final $Res Function(_QuestionPack) _then;

/// Create a copy of QuestionPack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? packId = null,Object? name = null,Object? description = null,Object? language = null,Object? questionCount = null,Object? icon = null,Object? isPremium = null,Object? createdAt = freezed,}) {
  return _then(_QuestionPack(
packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

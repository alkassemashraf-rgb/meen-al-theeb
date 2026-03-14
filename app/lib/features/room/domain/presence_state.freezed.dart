// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presence_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PresenceState {

 bool get isPresent; DateTime? get lastActiveAt;
/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresenceStateCopyWith<PresenceState> get copyWith => _$PresenceStateCopyWithImpl<PresenceState>(this as PresenceState, _$identity);

  /// Serializes this PresenceState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresenceState&&(identical(other.isPresent, isPresent) || other.isPresent == isPresent)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPresent,lastActiveAt);

@override
String toString() {
  return 'PresenceState(isPresent: $isPresent, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $PresenceStateCopyWith<$Res>  {
  factory $PresenceStateCopyWith(PresenceState value, $Res Function(PresenceState) _then) = _$PresenceStateCopyWithImpl;
@useResult
$Res call({
 bool isPresent, DateTime? lastActiveAt
});




}
/// @nodoc
class _$PresenceStateCopyWithImpl<$Res>
    implements $PresenceStateCopyWith<$Res> {
  _$PresenceStateCopyWithImpl(this._self, this._then);

  final PresenceState _self;
  final $Res Function(PresenceState) _then;

/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPresent = null,Object? lastActiveAt = freezed,}) {
  return _then(_self.copyWith(
isPresent: null == isPresent ? _self.isPresent : isPresent // ignore: cast_nullable_to_non_nullable
as bool,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PresenceState].
extension PresenceStatePatterns on PresenceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresenceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresenceState value)  $default,){
final _that = this;
switch (_that) {
case _PresenceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresenceState value)?  $default,){
final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isPresent,  DateTime? lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
return $default(_that.isPresent,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isPresent,  DateTime? lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _PresenceState():
return $default(_that.isPresent,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isPresent,  DateTime? lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
return $default(_that.isPresent,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresenceState implements PresenceState {
  const _PresenceState({required this.isPresent, this.lastActiveAt = null});
  factory _PresenceState.fromJson(Map<String, dynamic> json) => _$PresenceStateFromJson(json);

@override final  bool isPresent;
@override@JsonKey() final  DateTime? lastActiveAt;

/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresenceStateCopyWith<_PresenceState> get copyWith => __$PresenceStateCopyWithImpl<_PresenceState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresenceStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresenceState&&(identical(other.isPresent, isPresent) || other.isPresent == isPresent)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPresent,lastActiveAt);

@override
String toString() {
  return 'PresenceState(isPresent: $isPresent, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$PresenceStateCopyWith<$Res> implements $PresenceStateCopyWith<$Res> {
  factory _$PresenceStateCopyWith(_PresenceState value, $Res Function(_PresenceState) _then) = __$PresenceStateCopyWithImpl;
@override @useResult
$Res call({
 bool isPresent, DateTime? lastActiveAt
});




}
/// @nodoc
class __$PresenceStateCopyWithImpl<$Res>
    implements _$PresenceStateCopyWith<$Res> {
  __$PresenceStateCopyWithImpl(this._self, this._then);

  final _PresenceState _self;
  final $Res Function(_PresenceState) _then;

/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isPresent = null,Object? lastActiveAt = freezed,}) {
  return _then(_PresenceState(
isPresent: null == isPresent ? _self.isPresent : isPresent // ignore: cast_nullable_to_non_nullable
as bool,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

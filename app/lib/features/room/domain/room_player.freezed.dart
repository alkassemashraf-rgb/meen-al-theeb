// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomPlayer {

 String get playerId; String get displayName; String get avatarId; bool get isHost; bool get isPresent; DateTime get joinedAt;
/// Create a copy of RoomPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomPlayerCopyWith<RoomPlayer> get copyWith => _$RoomPlayerCopyWithImpl<RoomPlayer>(this as RoomPlayer, _$identity);

  /// Serializes this RoomPlayer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomPlayer&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isPresent, isPresent) || other.isPresent == isPresent)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,displayName,avatarId,isHost,isPresent,joinedAt);

@override
String toString() {
  return 'RoomPlayer(playerId: $playerId, displayName: $displayName, avatarId: $avatarId, isHost: $isHost, isPresent: $isPresent, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $RoomPlayerCopyWith<$Res>  {
  factory $RoomPlayerCopyWith(RoomPlayer value, $Res Function(RoomPlayer) _then) = _$RoomPlayerCopyWithImpl;
@useResult
$Res call({
 String playerId, String displayName, String avatarId, bool isHost, bool isPresent, DateTime joinedAt
});




}
/// @nodoc
class _$RoomPlayerCopyWithImpl<$Res>
    implements $RoomPlayerCopyWith<$Res> {
  _$RoomPlayerCopyWithImpl(this._self, this._then);

  final RoomPlayer _self;
  final $Res Function(RoomPlayer) _then;

/// Create a copy of RoomPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? displayName = null,Object? avatarId = null,Object? isHost = null,Object? isPresent = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isPresent: null == isPresent ? _self.isPresent : isPresent // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomPlayer].
extension RoomPlayerPatterns on RoomPlayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomPlayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomPlayer value)  $default,){
final _that = this;
switch (_that) {
case _RoomPlayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _RoomPlayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  String displayName,  String avatarId,  bool isHost,  bool isPresent,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomPlayer() when $default != null:
return $default(_that.playerId,_that.displayName,_that.avatarId,_that.isHost,_that.isPresent,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  String displayName,  String avatarId,  bool isHost,  bool isPresent,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _RoomPlayer():
return $default(_that.playerId,_that.displayName,_that.avatarId,_that.isHost,_that.isPresent,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  String displayName,  String avatarId,  bool isHost,  bool isPresent,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoomPlayer() when $default != null:
return $default(_that.playerId,_that.displayName,_that.avatarId,_that.isHost,_that.isPresent,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomPlayer implements RoomPlayer {
  const _RoomPlayer({required this.playerId, required this.displayName, required this.avatarId, required this.isHost, required this.isPresent, required this.joinedAt});
  factory _RoomPlayer.fromJson(Map<String, dynamic> json) => _$RoomPlayerFromJson(json);

@override final  String playerId;
@override final  String displayName;
@override final  String avatarId;
@override final  bool isHost;
@override final  bool isPresent;
@override final  DateTime joinedAt;

/// Create a copy of RoomPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomPlayerCopyWith<_RoomPlayer> get copyWith => __$RoomPlayerCopyWithImpl<_RoomPlayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomPlayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomPlayer&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarId, avatarId) || other.avatarId == avatarId)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isPresent, isPresent) || other.isPresent == isPresent)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,displayName,avatarId,isHost,isPresent,joinedAt);

@override
String toString() {
  return 'RoomPlayer(playerId: $playerId, displayName: $displayName, avatarId: $avatarId, isHost: $isHost, isPresent: $isPresent, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$RoomPlayerCopyWith<$Res> implements $RoomPlayerCopyWith<$Res> {
  factory _$RoomPlayerCopyWith(_RoomPlayer value, $Res Function(_RoomPlayer) _then) = __$RoomPlayerCopyWithImpl;
@override @useResult
$Res call({
 String playerId, String displayName, String avatarId, bool isHost, bool isPresent, DateTime joinedAt
});




}
/// @nodoc
class __$RoomPlayerCopyWithImpl<$Res>
    implements _$RoomPlayerCopyWith<$Res> {
  __$RoomPlayerCopyWithImpl(this._self, this._then);

  final _RoomPlayer _self;
  final $Res Function(_RoomPlayer) _then;

/// Create a copy of RoomPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? displayName = null,Object? avatarId = null,Object? isHost = null,Object? isPresent = null,Object? joinedAt = null,}) {
  return _then(_RoomPlayer(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarId: null == avatarId ? _self.avatarId : avatarId // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isPresent: null == isPresent ? _self.isPresent : isPresent // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

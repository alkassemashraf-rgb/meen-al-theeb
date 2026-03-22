// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_round.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameRound {

 String get roundId; String get questionId; String get questionAr; String get questionEn; String get packId; String get phase;// preparing | voting | vote_locked | result_ready
 DateTime get startedAt; DateTime get expiresAt; List<String> get eligiblePlayerIds; Map<String, String> get votes;// VoterId -> TargetPlayerId
 RoundResult? get result; int get roundNumber;
/// Create a copy of GameRound
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameRoundCopyWith<GameRound> get copyWith => _$GameRoundCopyWithImpl<GameRound>(this as GameRound, _$identity);

  /// Serializes this GameRound to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameRound&&(identical(other.roundId, roundId) || other.roundId == roundId)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.questionAr, questionAr) || other.questionAr == questionAr)&&(identical(other.questionEn, questionEn) || other.questionEn == questionEn)&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other.eligiblePlayerIds, eligiblePlayerIds)&&const DeepCollectionEquality().equals(other.votes, votes)&&(identical(other.result, result) || other.result == result)&&(identical(other.roundNumber, roundNumber) || other.roundNumber == roundNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roundId,questionId,questionAr,questionEn,packId,phase,startedAt,expiresAt,const DeepCollectionEquality().hash(eligiblePlayerIds),const DeepCollectionEquality().hash(votes),result,roundNumber);

@override
String toString() {
  return 'GameRound(roundId: $roundId, questionId: $questionId, questionAr: $questionAr, questionEn: $questionEn, packId: $packId, phase: $phase, startedAt: $startedAt, expiresAt: $expiresAt, eligiblePlayerIds: $eligiblePlayerIds, votes: $votes, result: $result, roundNumber: $roundNumber)';
}


}

/// @nodoc
abstract mixin class $GameRoundCopyWith<$Res>  {
  factory $GameRoundCopyWith(GameRound value, $Res Function(GameRound) _then) = _$GameRoundCopyWithImpl;
@useResult
$Res call({
 String roundId, String questionId, String questionAr, String questionEn, String packId, String phase, DateTime startedAt, DateTime expiresAt, List<String> eligiblePlayerIds, Map<String, String> votes, RoundResult? result, int roundNumber
});


$RoundResultCopyWith<$Res>? get result;

}
/// @nodoc
class _$GameRoundCopyWithImpl<$Res>
    implements $GameRoundCopyWith<$Res> {
  _$GameRoundCopyWithImpl(this._self, this._then);

  final GameRound _self;
  final $Res Function(GameRound) _then;

/// Create a copy of GameRound
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roundId = null,Object? questionId = null,Object? questionAr = null,Object? questionEn = null,Object? packId = null,Object? phase = null,Object? startedAt = null,Object? expiresAt = null,Object? eligiblePlayerIds = null,Object? votes = null,Object? result = freezed,Object? roundNumber = null,}) {
  return _then(_self.copyWith(
roundId: null == roundId ? _self.roundId : roundId // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,questionAr: null == questionAr ? _self.questionAr : questionAr // ignore: cast_nullable_to_non_nullable
as String,questionEn: null == questionEn ? _self.questionEn : questionEn // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,eligiblePlayerIds: null == eligiblePlayerIds ? _self.eligiblePlayerIds : eligiblePlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as RoundResult?,roundNumber: null == roundNumber ? _self.roundNumber : roundNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of GameRound
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoundResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $RoundResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameRound].
extension GameRoundPatterns on GameRound {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameRound value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameRound() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameRound value)  $default,){
final _that = this;
switch (_that) {
case _GameRound():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameRound value)?  $default,){
final _that = this;
switch (_that) {
case _GameRound() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roundId,  String questionId,  String questionAr,  String questionEn,  String packId,  String phase,  DateTime startedAt,  DateTime expiresAt,  List<String> eligiblePlayerIds,  Map<String, String> votes,  RoundResult? result,  int roundNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameRound() when $default != null:
return $default(_that.roundId,_that.questionId,_that.questionAr,_that.questionEn,_that.packId,_that.phase,_that.startedAt,_that.expiresAt,_that.eligiblePlayerIds,_that.votes,_that.result,_that.roundNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roundId,  String questionId,  String questionAr,  String questionEn,  String packId,  String phase,  DateTime startedAt,  DateTime expiresAt,  List<String> eligiblePlayerIds,  Map<String, String> votes,  RoundResult? result,  int roundNumber)  $default,) {final _that = this;
switch (_that) {
case _GameRound():
return $default(_that.roundId,_that.questionId,_that.questionAr,_that.questionEn,_that.packId,_that.phase,_that.startedAt,_that.expiresAt,_that.eligiblePlayerIds,_that.votes,_that.result,_that.roundNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roundId,  String questionId,  String questionAr,  String questionEn,  String packId,  String phase,  DateTime startedAt,  DateTime expiresAt,  List<String> eligiblePlayerIds,  Map<String, String> votes,  RoundResult? result,  int roundNumber)?  $default,) {final _that = this;
switch (_that) {
case _GameRound() when $default != null:
return $default(_that.roundId,_that.questionId,_that.questionAr,_that.questionEn,_that.packId,_that.phase,_that.startedAt,_that.expiresAt,_that.eligiblePlayerIds,_that.votes,_that.result,_that.roundNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameRound implements GameRound {
  const _GameRound({required this.roundId, required this.questionId, required this.questionAr, required this.questionEn, this.packId = '', required this.phase, required this.startedAt, required this.expiresAt, final  List<String> eligiblePlayerIds = const [], final  Map<String, String> votes = const {}, this.result, this.roundNumber = 0}): _eligiblePlayerIds = eligiblePlayerIds,_votes = votes;
  factory _GameRound.fromJson(Map<String, dynamic> json) => _$GameRoundFromJson(json);

@override final  String roundId;
@override final  String questionId;
@override final  String questionAr;
@override final  String questionEn;
@override@JsonKey() final  String packId;
@override final  String phase;
// preparing | voting | vote_locked | result_ready
@override final  DateTime startedAt;
@override final  DateTime expiresAt;
 final  List<String> _eligiblePlayerIds;
@override@JsonKey() List<String> get eligiblePlayerIds {
  if (_eligiblePlayerIds is EqualUnmodifiableListView) return _eligiblePlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eligiblePlayerIds);
}

 final  Map<String, String> _votes;
@override@JsonKey() Map<String, String> get votes {
  if (_votes is EqualUnmodifiableMapView) return _votes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_votes);
}

// VoterId -> TargetPlayerId
@override final  RoundResult? result;
@override@JsonKey() final  int roundNumber;

/// Create a copy of GameRound
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameRoundCopyWith<_GameRound> get copyWith => __$GameRoundCopyWithImpl<_GameRound>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameRoundToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameRound&&(identical(other.roundId, roundId) || other.roundId == roundId)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.questionAr, questionAr) || other.questionAr == questionAr)&&(identical(other.questionEn, questionEn) || other.questionEn == questionEn)&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other._eligiblePlayerIds, _eligiblePlayerIds)&&const DeepCollectionEquality().equals(other._votes, _votes)&&(identical(other.result, result) || other.result == result)&&(identical(other.roundNumber, roundNumber) || other.roundNumber == roundNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roundId,questionId,questionAr,questionEn,packId,phase,startedAt,expiresAt,const DeepCollectionEquality().hash(_eligiblePlayerIds),const DeepCollectionEquality().hash(_votes),result,roundNumber);

@override
String toString() {
  return 'GameRound(roundId: $roundId, questionId: $questionId, questionAr: $questionAr, questionEn: $questionEn, packId: $packId, phase: $phase, startedAt: $startedAt, expiresAt: $expiresAt, eligiblePlayerIds: $eligiblePlayerIds, votes: $votes, result: $result, roundNumber: $roundNumber)';
}


}

/// @nodoc
abstract mixin class _$GameRoundCopyWith<$Res> implements $GameRoundCopyWith<$Res> {
  factory _$GameRoundCopyWith(_GameRound value, $Res Function(_GameRound) _then) = __$GameRoundCopyWithImpl;
@override @useResult
$Res call({
 String roundId, String questionId, String questionAr, String questionEn, String packId, String phase, DateTime startedAt, DateTime expiresAt, List<String> eligiblePlayerIds, Map<String, String> votes, RoundResult? result, int roundNumber
});


@override $RoundResultCopyWith<$Res>? get result;

}
/// @nodoc
class __$GameRoundCopyWithImpl<$Res>
    implements _$GameRoundCopyWith<$Res> {
  __$GameRoundCopyWithImpl(this._self, this._then);

  final _GameRound _self;
  final $Res Function(_GameRound) _then;

/// Create a copy of GameRound
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roundId = null,Object? questionId = null,Object? questionAr = null,Object? questionEn = null,Object? packId = null,Object? phase = null,Object? startedAt = null,Object? expiresAt = null,Object? eligiblePlayerIds = null,Object? votes = null,Object? result = freezed,Object? roundNumber = null,}) {
  return _then(_GameRound(
roundId: null == roundId ? _self.roundId : roundId // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,questionAr: null == questionAr ? _self.questionAr : questionAr // ignore: cast_nullable_to_non_nullable
as String,questionEn: null == questionEn ? _self.questionEn : questionEn // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,eligiblePlayerIds: null == eligiblePlayerIds ? _self._eligiblePlayerIds : eligiblePlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,votes: null == votes ? _self._votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, String>,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as RoundResult?,roundNumber: null == roundNumber ? _self.roundNumber : roundNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of GameRound
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoundResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $RoundResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on

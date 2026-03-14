// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'round_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoundResult {

 List<String> get winningPlayerIds; Map<String, int> get voteCounts;// playerId -> count
 String get resultType;// normal | tie | insufficient_votes
 int get totalValidVotes; DateTime get computedAt;
/// Create a copy of RoundResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoundResultCopyWith<RoundResult> get copyWith => _$RoundResultCopyWithImpl<RoundResult>(this as RoundResult, _$identity);

  /// Serializes this RoundResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoundResult&&const DeepCollectionEquality().equals(other.winningPlayerIds, winningPlayerIds)&&const DeepCollectionEquality().equals(other.voteCounts, voteCounts)&&(identical(other.resultType, resultType) || other.resultType == resultType)&&(identical(other.totalValidVotes, totalValidVotes) || other.totalValidVotes == totalValidVotes)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(winningPlayerIds),const DeepCollectionEquality().hash(voteCounts),resultType,totalValidVotes,computedAt);

@override
String toString() {
  return 'RoundResult(winningPlayerIds: $winningPlayerIds, voteCounts: $voteCounts, resultType: $resultType, totalValidVotes: $totalValidVotes, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class $RoundResultCopyWith<$Res>  {
  factory $RoundResultCopyWith(RoundResult value, $Res Function(RoundResult) _then) = _$RoundResultCopyWithImpl;
@useResult
$Res call({
 List<String> winningPlayerIds, Map<String, int> voteCounts, String resultType, int totalValidVotes, DateTime computedAt
});




}
/// @nodoc
class _$RoundResultCopyWithImpl<$Res>
    implements $RoundResultCopyWith<$Res> {
  _$RoundResultCopyWithImpl(this._self, this._then);

  final RoundResult _self;
  final $Res Function(RoundResult) _then;

/// Create a copy of RoundResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? winningPlayerIds = null,Object? voteCounts = null,Object? resultType = null,Object? totalValidVotes = null,Object? computedAt = null,}) {
  return _then(_self.copyWith(
winningPlayerIds: null == winningPlayerIds ? _self.winningPlayerIds : winningPlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,voteCounts: null == voteCounts ? _self.voteCounts : voteCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as String,totalValidVotes: null == totalValidVotes ? _self.totalValidVotes : totalValidVotes // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RoundResult].
extension RoundResultPatterns on RoundResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoundResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoundResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoundResult value)  $default,){
final _that = this;
switch (_that) {
case _RoundResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoundResult value)?  $default,){
final _that = this;
switch (_that) {
case _RoundResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> winningPlayerIds,  Map<String, int> voteCounts,  String resultType,  int totalValidVotes,  DateTime computedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoundResult() when $default != null:
return $default(_that.winningPlayerIds,_that.voteCounts,_that.resultType,_that.totalValidVotes,_that.computedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> winningPlayerIds,  Map<String, int> voteCounts,  String resultType,  int totalValidVotes,  DateTime computedAt)  $default,) {final _that = this;
switch (_that) {
case _RoundResult():
return $default(_that.winningPlayerIds,_that.voteCounts,_that.resultType,_that.totalValidVotes,_that.computedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> winningPlayerIds,  Map<String, int> voteCounts,  String resultType,  int totalValidVotes,  DateTime computedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoundResult() when $default != null:
return $default(_that.winningPlayerIds,_that.voteCounts,_that.resultType,_that.totalValidVotes,_that.computedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoundResult implements RoundResult {
  const _RoundResult({required final  List<String> winningPlayerIds, required final  Map<String, int> voteCounts, required this.resultType, required this.totalValidVotes, required this.computedAt}): _winningPlayerIds = winningPlayerIds,_voteCounts = voteCounts;
  factory _RoundResult.fromJson(Map<String, dynamic> json) => _$RoundResultFromJson(json);

 final  List<String> _winningPlayerIds;
@override List<String> get winningPlayerIds {
  if (_winningPlayerIds is EqualUnmodifiableListView) return _winningPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_winningPlayerIds);
}

 final  Map<String, int> _voteCounts;
@override Map<String, int> get voteCounts {
  if (_voteCounts is EqualUnmodifiableMapView) return _voteCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_voteCounts);
}

// playerId -> count
@override final  String resultType;
// normal | tie | insufficient_votes
@override final  int totalValidVotes;
@override final  DateTime computedAt;

/// Create a copy of RoundResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoundResultCopyWith<_RoundResult> get copyWith => __$RoundResultCopyWithImpl<_RoundResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoundResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoundResult&&const DeepCollectionEquality().equals(other._winningPlayerIds, _winningPlayerIds)&&const DeepCollectionEquality().equals(other._voteCounts, _voteCounts)&&(identical(other.resultType, resultType) || other.resultType == resultType)&&(identical(other.totalValidVotes, totalValidVotes) || other.totalValidVotes == totalValidVotes)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_winningPlayerIds),const DeepCollectionEquality().hash(_voteCounts),resultType,totalValidVotes,computedAt);

@override
String toString() {
  return 'RoundResult(winningPlayerIds: $winningPlayerIds, voteCounts: $voteCounts, resultType: $resultType, totalValidVotes: $totalValidVotes, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class _$RoundResultCopyWith<$Res> implements $RoundResultCopyWith<$Res> {
  factory _$RoundResultCopyWith(_RoundResult value, $Res Function(_RoundResult) _then) = __$RoundResultCopyWithImpl;
@override @useResult
$Res call({
 List<String> winningPlayerIds, Map<String, int> voteCounts, String resultType, int totalValidVotes, DateTime computedAt
});




}
/// @nodoc
class __$RoundResultCopyWithImpl<$Res>
    implements _$RoundResultCopyWith<$Res> {
  __$RoundResultCopyWithImpl(this._self, this._then);

  final _RoundResult _self;
  final $Res Function(_RoundResult) _then;

/// Create a copy of RoundResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? winningPlayerIds = null,Object? voteCounts = null,Object? resultType = null,Object? totalValidVotes = null,Object? computedAt = null,}) {
  return _then(_RoundResult(
winningPlayerIds: null == winningPlayerIds ? _self._winningPlayerIds : winningPlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,voteCounts: null == voteCounts ? _self._voteCounts : voteCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as String,totalValidVotes: null == totalValidVotes ? _self.totalValidVotes : totalValidVotes // ignore: cast_nullable_to_non_nullable
as int,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

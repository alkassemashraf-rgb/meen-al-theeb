// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'round_history_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoundHistoryItem {

 String get roundId; String get questionId; String get questionAr; String get questionEn;/// resultType: normal | tie | insufficient_votes
 String get resultType; List<String> get winningPlayerIds;/// playerId -> vote count received
 Map<String, int> get voteCounts; int get totalValidVotes; DateTime get completedAt;
/// Create a copy of RoundHistoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoundHistoryItemCopyWith<RoundHistoryItem> get copyWith => _$RoundHistoryItemCopyWithImpl<RoundHistoryItem>(this as RoundHistoryItem, _$identity);

  /// Serializes this RoundHistoryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoundHistoryItem&&(identical(other.roundId, roundId) || other.roundId == roundId)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.questionAr, questionAr) || other.questionAr == questionAr)&&(identical(other.questionEn, questionEn) || other.questionEn == questionEn)&&(identical(other.resultType, resultType) || other.resultType == resultType)&&const DeepCollectionEquality().equals(other.winningPlayerIds, winningPlayerIds)&&const DeepCollectionEquality().equals(other.voteCounts, voteCounts)&&(identical(other.totalValidVotes, totalValidVotes) || other.totalValidVotes == totalValidVotes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roundId,questionId,questionAr,questionEn,resultType,const DeepCollectionEquality().hash(winningPlayerIds),const DeepCollectionEquality().hash(voteCounts),totalValidVotes,completedAt);

@override
String toString() {
  return 'RoundHistoryItem(roundId: $roundId, questionId: $questionId, questionAr: $questionAr, questionEn: $questionEn, resultType: $resultType, winningPlayerIds: $winningPlayerIds, voteCounts: $voteCounts, totalValidVotes: $totalValidVotes, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $RoundHistoryItemCopyWith<$Res>  {
  factory $RoundHistoryItemCopyWith(RoundHistoryItem value, $Res Function(RoundHistoryItem) _then) = _$RoundHistoryItemCopyWithImpl;
@useResult
$Res call({
 String roundId, String questionId, String questionAr, String questionEn, String resultType, List<String> winningPlayerIds, Map<String, int> voteCounts, int totalValidVotes, DateTime completedAt
});




}
/// @nodoc
class _$RoundHistoryItemCopyWithImpl<$Res>
    implements $RoundHistoryItemCopyWith<$Res> {
  _$RoundHistoryItemCopyWithImpl(this._self, this._then);

  final RoundHistoryItem _self;
  final $Res Function(RoundHistoryItem) _then;

/// Create a copy of RoundHistoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roundId = null,Object? questionId = null,Object? questionAr = null,Object? questionEn = null,Object? resultType = null,Object? winningPlayerIds = null,Object? voteCounts = null,Object? totalValidVotes = null,Object? completedAt = null,}) {
  return _then(_self.copyWith(
roundId: null == roundId ? _self.roundId : roundId // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,questionAr: null == questionAr ? _self.questionAr : questionAr // ignore: cast_nullable_to_non_nullable
as String,questionEn: null == questionEn ? _self.questionEn : questionEn // ignore: cast_nullable_to_non_nullable
as String,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as String,winningPlayerIds: null == winningPlayerIds ? _self.winningPlayerIds : winningPlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,voteCounts: null == voteCounts ? _self.voteCounts : voteCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,totalValidVotes: null == totalValidVotes ? _self.totalValidVotes : totalValidVotes // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RoundHistoryItem].
extension RoundHistoryItemPatterns on RoundHistoryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoundHistoryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoundHistoryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoundHistoryItem value)  $default,){
final _that = this;
switch (_that) {
case _RoundHistoryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoundHistoryItem value)?  $default,){
final _that = this;
switch (_that) {
case _RoundHistoryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roundId,  String questionId,  String questionAr,  String questionEn,  String resultType,  List<String> winningPlayerIds,  Map<String, int> voteCounts,  int totalValidVotes,  DateTime completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoundHistoryItem() when $default != null:
return $default(_that.roundId,_that.questionId,_that.questionAr,_that.questionEn,_that.resultType,_that.winningPlayerIds,_that.voteCounts,_that.totalValidVotes,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roundId,  String questionId,  String questionAr,  String questionEn,  String resultType,  List<String> winningPlayerIds,  Map<String, int> voteCounts,  int totalValidVotes,  DateTime completedAt)  $default,) {final _that = this;
switch (_that) {
case _RoundHistoryItem():
return $default(_that.roundId,_that.questionId,_that.questionAr,_that.questionEn,_that.resultType,_that.winningPlayerIds,_that.voteCounts,_that.totalValidVotes,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roundId,  String questionId,  String questionAr,  String questionEn,  String resultType,  List<String> winningPlayerIds,  Map<String, int> voteCounts,  int totalValidVotes,  DateTime completedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoundHistoryItem() when $default != null:
return $default(_that.roundId,_that.questionId,_that.questionAr,_that.questionEn,_that.resultType,_that.winningPlayerIds,_that.voteCounts,_that.totalValidVotes,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoundHistoryItem implements RoundHistoryItem {
  const _RoundHistoryItem({required this.roundId, required this.questionId, required this.questionAr, required this.questionEn, required this.resultType, final  List<String> winningPlayerIds = const [], final  Map<String, int> voteCounts = const {}, required this.totalValidVotes, required this.completedAt}): _winningPlayerIds = winningPlayerIds,_voteCounts = voteCounts;
  factory _RoundHistoryItem.fromJson(Map<String, dynamic> json) => _$RoundHistoryItemFromJson(json);

@override final  String roundId;
@override final  String questionId;
@override final  String questionAr;
@override final  String questionEn;
/// resultType: normal | tie | insufficient_votes
@override final  String resultType;
 final  List<String> _winningPlayerIds;
@override@JsonKey() List<String> get winningPlayerIds {
  if (_winningPlayerIds is EqualUnmodifiableListView) return _winningPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_winningPlayerIds);
}

/// playerId -> vote count received
 final  Map<String, int> _voteCounts;
/// playerId -> vote count received
@override@JsonKey() Map<String, int> get voteCounts {
  if (_voteCounts is EqualUnmodifiableMapView) return _voteCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_voteCounts);
}

@override final  int totalValidVotes;
@override final  DateTime completedAt;

/// Create a copy of RoundHistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoundHistoryItemCopyWith<_RoundHistoryItem> get copyWith => __$RoundHistoryItemCopyWithImpl<_RoundHistoryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoundHistoryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoundHistoryItem&&(identical(other.roundId, roundId) || other.roundId == roundId)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.questionAr, questionAr) || other.questionAr == questionAr)&&(identical(other.questionEn, questionEn) || other.questionEn == questionEn)&&(identical(other.resultType, resultType) || other.resultType == resultType)&&const DeepCollectionEquality().equals(other._winningPlayerIds, _winningPlayerIds)&&const DeepCollectionEquality().equals(other._voteCounts, _voteCounts)&&(identical(other.totalValidVotes, totalValidVotes) || other.totalValidVotes == totalValidVotes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roundId,questionId,questionAr,questionEn,resultType,const DeepCollectionEquality().hash(_winningPlayerIds),const DeepCollectionEquality().hash(_voteCounts),totalValidVotes,completedAt);

@override
String toString() {
  return 'RoundHistoryItem(roundId: $roundId, questionId: $questionId, questionAr: $questionAr, questionEn: $questionEn, resultType: $resultType, winningPlayerIds: $winningPlayerIds, voteCounts: $voteCounts, totalValidVotes: $totalValidVotes, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$RoundHistoryItemCopyWith<$Res> implements $RoundHistoryItemCopyWith<$Res> {
  factory _$RoundHistoryItemCopyWith(_RoundHistoryItem value, $Res Function(_RoundHistoryItem) _then) = __$RoundHistoryItemCopyWithImpl;
@override @useResult
$Res call({
 String roundId, String questionId, String questionAr, String questionEn, String resultType, List<String> winningPlayerIds, Map<String, int> voteCounts, int totalValidVotes, DateTime completedAt
});




}
/// @nodoc
class __$RoundHistoryItemCopyWithImpl<$Res>
    implements _$RoundHistoryItemCopyWith<$Res> {
  __$RoundHistoryItemCopyWithImpl(this._self, this._then);

  final _RoundHistoryItem _self;
  final $Res Function(_RoundHistoryItem) _then;

/// Create a copy of RoundHistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roundId = null,Object? questionId = null,Object? questionAr = null,Object? questionEn = null,Object? resultType = null,Object? winningPlayerIds = null,Object? voteCounts = null,Object? totalValidVotes = null,Object? completedAt = null,}) {
  return _then(_RoundHistoryItem(
roundId: null == roundId ? _self.roundId : roundId // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,questionAr: null == questionAr ? _self.questionAr : questionAr // ignore: cast_nullable_to_non_nullable
as String,questionEn: null == questionEn ? _self.questionEn : questionEn // ignore: cast_nullable_to_non_nullable
as String,resultType: null == resultType ? _self.resultType : resultType // ignore: cast_nullable_to_non_nullable
as String,winningPlayerIds: null == winningPlayerIds ? _self._winningPlayerIds : winningPlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,voteCounts: null == voteCounts ? _self._voteCounts : voteCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,totalValidVotes: null == totalValidVotes ? _self.totalValidVotes : totalValidVotes // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

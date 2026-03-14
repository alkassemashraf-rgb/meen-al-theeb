// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoundResult _$RoundResultFromJson(Map<String, dynamic> json) => _RoundResult(
  winningPlayerIds:
      (json['winningPlayerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  voteCounts: Map<String, int>.from(json['voteCounts'] as Map),
  resultType: json['resultType'] as String,
  totalValidVotes: (json['totalValidVotes'] as num).toInt(),
  computedAt: DateTime.parse(json['computedAt'] as String),
);

Map<String, dynamic> _$RoundResultToJson(_RoundResult instance) =>
    <String, dynamic>{
      'winningPlayerIds': instance.winningPlayerIds,
      'voteCounts': instance.voteCounts,
      'resultType': instance.resultType,
      'totalValidVotes': instance.totalValidVotes,
      'computedAt': instance.computedAt.toIso8601String(),
    };

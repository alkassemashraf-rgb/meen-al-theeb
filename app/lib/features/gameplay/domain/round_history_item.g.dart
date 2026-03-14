// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_history_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoundHistoryItem _$RoundHistoryItemFromJson(Map<String, dynamic> json) =>
    _RoundHistoryItem(
      roundId: json['roundId'] as String,
      questionId: json['questionId'] as String,
      questionAr: json['questionAr'] as String,
      questionEn: json['questionEn'] as String,
      resultType: json['resultType'] as String,
      winningPlayerIds:
          (json['winningPlayerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      voteCounts:
          (json['voteCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      totalValidVotes: (json['totalValidVotes'] as num).toInt(),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$RoundHistoryItemToJson(_RoundHistoryItem instance) =>
    <String, dynamic>{
      'roundId': instance.roundId,
      'questionId': instance.questionId,
      'questionAr': instance.questionAr,
      'questionEn': instance.questionEn,
      'resultType': instance.resultType,
      'winningPlayerIds': instance.winningPlayerIds,
      'voteCounts': instance.voteCounts,
      'totalValidVotes': instance.totalValidVotes,
      'completedAt': instance.completedAt.toIso8601String(),
    };

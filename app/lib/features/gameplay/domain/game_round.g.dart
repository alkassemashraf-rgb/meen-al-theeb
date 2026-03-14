// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_round.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameRound _$GameRoundFromJson(Map<String, dynamic> json) => _GameRound(
  roundId: json['roundId'] as String,
  questionId: json['questionId'] as String,
  questionAr: json['questionAr'] as String,
  questionEn: json['questionEn'] as String,
  phase: json['phase'] as String,
  startedAt: DateTime.parse(json['startedAt'] as String),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  eligiblePlayerIds:
      (json['eligiblePlayerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  votes:
      (json['votes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  result:
      json['result'] == null
          ? null
          : RoundResult.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GameRoundToJson(_GameRound instance) =>
    <String, dynamic>{
      'roundId': instance.roundId,
      'questionId': instance.questionId,
      'questionAr': instance.questionAr,
      'questionEn': instance.questionEn,
      'phase': instance.phase,
      'startedAt': instance.startedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'eligiblePlayerIds': instance.eligiblePlayerIds,
      'votes': instance.votes,
      'result': instance.result,
    };

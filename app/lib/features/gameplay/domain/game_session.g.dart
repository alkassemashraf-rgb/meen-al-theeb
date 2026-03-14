// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameSession _$GameSessionFromJson(Map<String, dynamic> json) => _GameSession(
  sessionId: json['sessionId'] as String,
  packId: json['packId'] as String,
  usedQuestionIds:
      (json['usedQuestionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  startedAt: DateTime.parse(json['startedAt'] as String),
);

Map<String, dynamic> _$GameSessionToJson(_GameSession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'packId': instance.packId,
      'usedQuestionIds': instance.usedQuestionIds,
      'startedAt': instance.startedAt.toIso8601String(),
    };

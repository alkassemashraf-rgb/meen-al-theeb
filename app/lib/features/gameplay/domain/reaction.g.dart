// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reaction _$ReactionFromJson(Map<String, dynamic> json) => _Reaction(
  id: json['id'] as String,
  playerId: json['playerId'] as String,
  emoji: json['emoji'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$ReactionToJson(_Reaction instance) => <String, dynamic>{
  'id': instance.id,
  'playerId': instance.playerId,
  'emoji': instance.emoji,
  'timestamp': instance.timestamp.toIso8601String(),
};

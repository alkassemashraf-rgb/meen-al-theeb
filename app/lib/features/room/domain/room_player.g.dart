// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomPlayer _$RoomPlayerFromJson(Map<String, dynamic> json) => _RoomPlayer(
  playerId: json['playerId'] as String,
  displayName: json['displayName'] as String,
  avatarId: json['avatarId'] as String,
  isHost: json['isHost'] as bool,
  isPresent: json['isPresent'] as bool,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
);

Map<String, dynamic> _$RoomPlayerToJson(_RoomPlayer instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'displayName': instance.displayName,
      'avatarId': instance.avatarId,
      'isHost': instance.isHost,
      'isPresent': instance.isPresent,
      'joinedAt': instance.joinedAt.toIso8601String(),
    };

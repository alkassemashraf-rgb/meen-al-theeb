// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Room _$RoomFromJson(Map<String, dynamic> json) => _Room(
  roomId: json['roomId'] as String,
  joinCode: json['joinCode'] as String,
  hostId: json['hostId'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  players:
      (json['players'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, RoomPlayer.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
);

Map<String, dynamic> _$RoomToJson(_Room instance) => <String, dynamic>{
  'roomId': instance.roomId,
  'joinCode': instance.joinCode,
  'hostId': instance.hostId,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'players': instance.players,
};

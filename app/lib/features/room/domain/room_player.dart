import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_player.freezed.dart';
part 'room_player.g.dart';

@freezed
class RoomPlayer with _$RoomPlayer {
  const factory RoomPlayer({
    required String playerId,
    required String displayName,
    required String avatarId,
    required bool isHost,
    required bool isPresent,
    required DateTime joinedAt,
  }) = _RoomPlayer;

  factory RoomPlayer.fromJson(Map<String, dynamic> json) => _$RoomPlayerFromJson(json);
}

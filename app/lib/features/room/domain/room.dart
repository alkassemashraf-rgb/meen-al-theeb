import 'package:freezed_annotation/freezed_annotation.dart';
import 'room_player.dart';

part 'room.freezed.dart';
part 'room.g.dart';

@freezed
abstract class Room with _$Room {
  const factory Room({
    required String roomId,
    required String joinCode,
    required String hostId,
    required String status,
    required DateTime createdAt,
    @Default({}) Map<String, RoomPlayer> players,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../domain/room.dart';
import '../domain/room_player.dart';
import 'room_code_generator.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(FirebaseDatabase.instance);
});

/// Firebase RTDB returns Map<Object?, Object?> for nested maps.
/// This recursively converts to Map<String, dynamic> for json_serializable.
Map<String, dynamic> _deepConvert(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v is Map ? _deepConvert(v) : v));
  }
  return {};
}

class RoomRepository {
  final FirebaseDatabase _db;

  RoomRepository(this._db);

  DatabaseReference get _roomsRef => _db.ref('rooms');
  DatabaseReference roomRef(String roomId) => _roomsRef.child(roomId);

  /// Creates a new room and sets the creator as the host
  Future<Room> createRoom({
    required String hostId,
    required String hostName,
    required String avatarId,
  }) async {
    final joinCode = await RoomCodeGenerator.generateUniqueCode(_roomsRef);
    final roomId = _roomsRef.push().key!; // Generate unique push ID
    
    final hostPlayer = RoomPlayer(
      playerId: hostId,
      displayName: hostName,
      avatarId: avatarId,
      isHost: true,
      isPresent: true,
      joinedAt: DateTime.now(),
    );

    final room = Room(
      roomId: roomId,
      joinCode: joinCode,
      hostId: hostId,
      status: 'lobby',
      createdAt: DateTime.now(),
      players: {hostId: hostPlayer},
    );

    // room.toJson() leaves players as RoomPlayer objects; serialize them explicitly
    final roomJson = room.toJson();
    roomJson['players'] = room.players.map((k, v) => MapEntry(k, v.toJson()));
    await roomRef(roomId).set(roomJson);
    
    // Create an index for querying by join code
    await _db.ref('room_codes/$joinCode').set(roomId);

    return room;
  }

  /// Looks up a room by join code, validates it, and joins the player
  Future<String> joinRoom({
    required String joinCode,
    required String playerId,
    required String playerName,
    required String avatarId,
  }) async {
    final codeRef = _db.ref('room_codes/${joinCode.toUpperCase()}');
    final codeSnapshot = await codeRef.get();
    
    if (!codeSnapshot.exists) {
      throw Exception('Room code not found');
    }
    
    final roomId = codeSnapshot.value as String;
    final rRef = roomRef(roomId);
    
    // Verify room status
    final roomSnapshot = await rRef.get();
    if (!roomSnapshot.exists) {
      throw Exception('Room data corrupted or deleted');
    }
    
    final roomMap = _deepConvert(roomSnapshot.value);
    if (roomMap['status'] != 'lobby') {
      throw Exception('Room has already started');
    }

    // Check player limit (MVP: 8 players)
    final playersMap = roomMap['players'] != null
        ? _deepConvert(roomMap['players'])
        : <String, dynamic>{};

    if (playersMap.length >= 8 && !playersMap.containsKey(playerId)) {
      throw Exception('Room is full (max 8 players)');
    }

    // Check for duplicate names (excluding self if reconnecting)
    final existingNames = playersMap.values
        .map((p) => _deepConvert(p)['displayName'] as String)
        .toList();
    
    if (existingNames.contains(playerName) && !playersMap.containsKey(playerId)) {
      throw Exception('This name is already taken in this room');
    }
    
    final player = RoomPlayer(
      playerId: playerId,
      displayName: playerName,
      avatarId: avatarId,
      isHost: false, // You cannot join as host
      isPresent: true,
      joinedAt: DateTime.now(),
    );

    await rRef.child('players/$playerId').set(player.toJson());
    return roomId;
  }

  /// Leaves a room. If host leaves, we mark the room as ended (for MVP)
  Future<void> leaveRoom(String roomId, String playerId) async {
    final rRef = roomRef(roomId);
    final roomSnapshot = await rRef.get();
    
    if (!roomSnapshot.exists) return;
    
    final roomMap = _deepConvert(roomSnapshot.value);

    if (roomMap['hostId'] == playerId) {
      // Host left, end the room
      await rRef.child('status').set('ended');
      // Cleanup the join code index so no one else joins
      final joinCode = roomMap['joinCode'] as String?;
      if (joinCode != null) {
        await _db.ref('room_codes/$joinCode').remove();
      }
    } else {
      // Regular player left, flag presence as false
      await rRef.child('players/$playerId/isPresent').set(false);
    }
  }

  /// Stream of active room data
  Stream<Room?> observeRoom(String roomId) {
    return roomRef(roomId).onValue.map((event) {
      if (event.snapshot.exists) {
         return Room.fromJson(_deepConvert(event.snapshot.value));
      }
      return null;
    });
  }

  /// Persists the host's age mode selection so all lobby members can see it
  Future<void> updateRoomAgeMode(String roomId, String ageMode) async {
    await roomRef(roomId).child('ageMode').set(ageMode);
  }

  /// Streams the current ageMode for a room (defaults to 'standard' if unset)
  Stream<String> observeRoomAgeMode(String roomId) {
    return roomRef(roomId).child('ageMode').onValue.map((event) {
      if (!event.snapshot.exists) return 'standard';
      return event.snapshot.value as String? ?? 'standard';
    });
  }

  /// Fetches the ageMode of a room by its join code (used for pre-join check)
  Future<String> fetchRoomAgeModeByCode(String joinCode) async {
    final codeSnapshot =
        await _db.ref('room_codes/${joinCode.toUpperCase()}').get();
    if (!codeSnapshot.exists) return 'standard';
    final roomId = codeSnapshot.value as String;
    final ageModeSnapshot = await roomRef(roomId).child('ageMode').get();
    if (!ageModeSnapshot.exists) return 'standard';
    return ageModeSnapshot.value as String? ?? 'standard';
  }
}

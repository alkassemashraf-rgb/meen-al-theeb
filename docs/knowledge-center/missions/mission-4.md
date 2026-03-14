# Mission 4: Lobby & Room Foundation

## Objectives Completed

- [x] Room creation flow (Anonymous Auth -> RTDB Node)
- [x] Join by Code mechanism (5-char uppercase alphanumeric)
- [x] Multi-user Lobby UI with live player list
- [x] Live presence tracking via `onDisconnect()`
- [x] Automatic Room closure when the Host leaves

## Key Implementation Details

### Join Codes

Join codes are generated in `RoomCodeGenerator` using a collision-resistant character set (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`). They are indexed in the RTDB path `room_codes/{code}` for O(1) lookups during the join flow.

### Presence Strategy

We use the `.info/connected` hook in `PresenceService` to detect if the client is connected to Firebase. When connected, we set `isPresent: true` and a `.onDisconnect().set(false)` hook on the specific player's node within the room.

### Navigation Flow

1. **HomeScreen**: Choice between Create and Join.
2. **CreateRoomScreen**: Pick Avatar & Name -> Calls `RoomRepository.createRoom()`.
3. **JoinRoomScreen**: Enter Code, Pick Avatar & Name -> Calls `RoomRepository.joinRoom()`.
4. **LobbyScreen**: Subscription to `observeRoom(roomId)`. Displays live state.

## Status

- **Status**: Completed
- **Date**: 2026-03-14
- **Verification**: Verified via local diagnostic tests and cross-referencing RTDB structure.

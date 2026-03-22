# Mission 06 — Age Gate & Join Warning (Room-Level Safety Layer)

## Summary

Mission 6 introduces a lightweight, UX-based age-awareness layer. The implementation adds visual
indicators for mature rooms and a player confirmation step before joining — without adding friction
to gameplay or modifying the question engine.

**Scope:** UI-only. No identity verification, no account-level age storage, no enforcement beyond
user confirmation.

---

## ageMode → UI Behavior Mapping

| `ageMode` value | Host warning | Join confirmation | Room badge |
|---|---|---|---|
| `standard` | None | None | None |
| `plus18` | ⚠️ inline warning in picker | Modal required before joining | 🔞 18+ badge |
| `plus21` | ⚠️ inline warning in picker | Modal required before joining | 🍺 21+ badge |

---

## Architecture

### Data Flow

```
Host selects ageMode in lobby (LobbyScreen)
  → selectedAgeModeProvider updated (local)
  → roomRepositoryProvider.updateRoomAgeMode(roomId, ageMode) called
      → writes rooms/{roomId}/ageMode in Firebase RTDB
          → roomAgeModeStreamProvider picks up change for all lobby members
              → _AgeBadge shown in room code card for all players
```

### Pre-join Check (JoinRoomScreen)

```
Player taps "دخول للغرفة"
  → fetchRoomAgeModeByCode(joinCode) reads rooms/{roomId}/ageMode
  → if plus18 or plus21: show AgeConfirmationDialog
      → Cancel: abort join
      → Confirm: proceed to joinRoom() → navigate to lobby
  → if standard: proceed directly (no modal)
```

### Key Principle

Age gating is **UX-based, not enforcement-based**. The system:
- Warns hosts when they select a mature mode
- Warns players before they enter a mature room
- Allows players to freely cancel or proceed

There is no identity verification or blocking logic.

---

## Files Modified

### `app/lib/features/room/data/room_repository.dart`
Added three methods:
- `updateRoomAgeMode(roomId, ageMode)` — writes ageMode to RTDB immediately when host selects it
- `observeRoomAgeMode(roomId)` — streams ageMode changes for live badge updates
- `fetchRoomAgeModeByCode(joinCode)` — reads ageMode before a player joins (pre-join safety check)

### `app/lib/features/room/presentation/lobby_screen.dart`
- Added `roomAgeModeStreamProvider` (StreamProvider.family) for live ageMode reads from RTDB
- Updated `_LobbyScreenState.build` to watch ageMode and pass to room code card
- Room code card now shows `_AgeBadge` (🔞 18+ / 🍺 21+) when ageMode is mature — visible to all players
- `_AgeModePicker.onTap` now also calls `updateRoomAgeMode` to persist selection to Firebase
- `_AgeModePicker` now shows an inline bilingual warning when a mature mode is active
- `_RoomSummary` updated: warning text now matches spec wording and includes English translation
- Added `_AgeBadge` widget (shared visual component used by room code card)

### `app/lib/features/room/presentation/join_room_screen.dart`
- Added `_showAgeConfirmationDialog(ageMode)` — modal with Cancel / Confirm (دخول) actions
- `_handleJoin` now fetches ageMode before calling `joinRoom()`; shows modal if mature

---

## RTDB Schema

No new top-level nodes. ageMode is written to the existing room node:

```
rooms/
  {roomId}/
    ageMode: "standard" | "plus18" | "plus21"   ← NEW (optional; defaults to standard)
    roomId: ...
    joinCode: ...
    ...
```

The `Room` Freezed model was intentionally **not modified** — the ageMode field is read directly
from RTDB via `observeRoomAgeMode` and `fetchRoomAgeModeByCode` to avoid running `build_runner`.

---

## Warning Text (Spec)

| Context | Arabic | English |
|---|---|---|
| Host inline (AgeModePicker) | قد تحتوي هذه الغرفة على أسئلة جريئة أو للبالغين | This room may include mature or bold questions |
| Host summary (RoomSummary) | قد تحتوي هذه الغرفة على أسئلة جريئة أو للبالغين | This room may include mature or bold questions |
| Join confirmation modal | قد تحتوي هذه الغرفة على أسئلة جريئة أو للبالغين | This room may include mature or bold questions |

---

## Known Limitations

- `plus18` and `plus21` currently behave identically in the UI safety layer (same modal, same warning
  text). Differentiation at the content level comes from the question engine (Mission 3), not this layer.
- Age confirmation is shown once per join attempt. If a player navigates away and re-enters a code
  for the same mature room, the modal appears again — this is intentional (stateless design).
- The `Room` Freezed model does not include `ageMode`. If the room stream is ever used to derive
  ageMode (e.g., for gameplay summary display), add `@Default('standard') String ageMode` to
  `room.dart` and regenerate the build_runner files.

---

## Test Plan

1. Create room with `standard` mode → verify no warnings in picker, no modal on join, no badge in lobby
2. Create room with 18+ → verify orange inline warning in picker, 🔞 badge in lobby card for all
   players, modal appears when player tries to join
3. Create room with 21+ → verify orange inline warning in picker, 🍺 badge in lobby card for all
   players, modal appears when player tries to join
4. Cancel join on modal → verify player stays on join screen, does not enter the room
5. Confirm join on modal → verify player enters lobby normally
6. Verify no regression: room creation, joining standard rooms, game start flow all unaffected

# Mission 11 — Post-Game Experience (Replay Loop)

## Overview

Adds frictionless replay to the end-of-session experience. After a session ends, the host can restart immediately ("Play Again") or navigate to create a new room ("New Game").

---

## Replay Actions

### Play Again (same room)

- **Who can trigger**: Host only (button hidden for non-hosts)
- **Behavior**: Resets RTDB session state and starts a new game immediately — no lobby re-entry, no reconfiguration
- **Entry point**: `SessionSummaryScreen` → `_ReplayActionsBar` → `GameSessionRepository.resetAndStartSession()`
- **Navigation**: Host navigates to `/gameplay/{roomId}` immediately after reset; non-host players auto-navigate via room stream listener (see below)

### New Game

- **Who can trigger**: All players
- **Behavior**: Navigates to `/home` for a fresh room setup
- **Entry point**: `SessionSummaryScreen` → `_ReplayActionsBar` → `context.go('/home')`

---

## Session Reset Logic (`resetAndStartSession`)

File: `app/lib/features/gameplay/data/game_session_repository.dart`

### Fields Cleared

| Field | Why |
|---|---|
| `currentRound` | Stale voting state from previous session |
| `roundHistory` | Previous round results (fresh session = fresh history) |
| `session` | Overwritten atomically by `startGame()` |

### Fields Preserved

| Field | Why |
|---|---|
| `players` | Same group plays again |
| `maxRounds` | Host setting preserved |
| `selectedPackIds` | Host setting preserved |
| `ageMode` | Host setting preserved (read from room root) |
| `intensityLevel` | Host setting preserved (read from `session/intensityLevel`) |
| `hostId`, `joinCode`, `roomId` | Room identity |

### Fields NOT Restored

- **Join code index** (`/room_codes/{joinCode}`): Not restored. "Play Again" is for the existing group only; new players cannot join a restarted session.

### Implementation Notes

- `startGame()` does NOT check room status before running — no need to set status to `'lobby'` first.
- The reset clears `currentRound` and `roundHistory` before calling `startGame()`, which atomically overwrites the `session` subtree and sets `status = 'gameplay'`.
- `intensityLevel` is stored at `session/intensityLevel` (not room root). `ageMode` is at room root.

---

## Non-Host Auto-Navigation

Non-host players on the summary screen auto-navigate when the host triggers Play Again.

**Mechanism**: `_SummaryContentState.initState()` registers a `ref.listenManual` on `roomStreamProvider(roomId)`. When `room.status` transitions to `'gameplay'`, all listening clients call `context.go('/gameplay/{roomId}')`.

This reuses the same pattern as `LobbyScreen` (which listens for `status == 'gameplay'` to navigate to gameplay).

---

## Differences: Play Again vs New Game

| Aspect | Play Again | New Game |
|---|---|---|
| Room | Same roomId | New room created |
| Players | Unchanged | Reconfigured |
| Settings | Preserved | Reconfigured |
| Session history | Cleared | N/A |
| Host required | Yes | No |
| Speed | Immediate | Requires setup |

---

## Files Changed

- `app/lib/features/gameplay/data/game_session_repository.dart` — Added `resetAndStartSession()`
- `app/lib/features/gameplay/presentation/session_summary_screen.dart` — Replaced `_HomeButton` with `_ReplayActionsBar`; converted `_SummaryContent` to `ConsumerStatefulWidget` with room stream listener

---

## Verification Block

```
[VERIFICATION START]

Implemented:
- Play Again added: YES
- New Game added: YES
- Session reset implemented: YES
- Summary improved: YES (replay actions bar replaces single home button)
- Knowledge Center updated: YES

Validated:
- Replay tested end-to-end: NO (pending device test)
- State reset verified: NO (pending device test)
- No leftover votes/reactions: NO (pending device test)
- Players remain connected: NO (pending device test)

Files:
- Created: docs/knowledge-center/mission-11-replay-loop.md
- Updated:
  - app/lib/features/gameplay/data/game_session_repository.dart
  - app/lib/features/gameplay/presentation/session_summary_screen.dart

[VERIFICATION END]
```

# Mission 7 — Session Orchestration & Shareable Result Foundation

## Status: COMPLETE

## Objective
Build the session-control layer by implementing clean next-round orchestration,
round history tracking, session continuation/end behavior, and the first
shareable result card foundation. All changes respect the existing architecture,
Riverpod, Firebase layout, and Knowledge Center.

---

## 1. Session Controller Summary

### New: `GameSessionController`
**File:** `app/lib/features/gameplay/data/game_session_controller.dart`

A Riverpod `StateNotifier<GameSessionControllerState>` that is the central place
for high-level session progression logic.

**State — `GameSessionControllerState`:**
- `isTransitioningRound` (bool) — disables "Next Round" while in flight
- `isEndingSession` (bool) — disables "End Session" while in flight
- `errorMessage` (String?) — surfaces errors to the UI

**Provider:** `gameSessionControllerProvider` (`.family<..., String>` scoped per roomId)

**Methods:**
| Method | Description |
| --- | --- |
| `advanceToNextRound(round)` | Archives round → calls `nextRound`. Guarded by `isTransitioningRound` and phase check. |
| `endSession()` | Stops `GameplayService` → sets room status to `ended`. Guarded by `isEndingSession`. |
| `buildResultCard(round, players)` | Synchronous factory returning `ResultCardPayload`. |

**Separation from existing layers:**

| Layer | Owner |
| --- | --- |
| RTDB reads/writes | `GameSessionRepository` |
| Vote monitoring & timeout | `GameplayService` |
| Session orchestration | `GameSessionController` ← new |
| UI & streams | `GameplayScreen` |

---

## 2. Next Round Flow Summary

### Hardening applied to `GameSessionRepository.nextRound`
- Creates a fresh `roundId` using `round_${timestamp}` — never reuses IDs.
- Reads `session.usedQuestionIds` and passes them to `QuestionRepository.fetchRandomQuestion` — no question repeats within a session.
- Clears `reactions` node atomically with the new round write.
- Clears all prior votes by overwriting the entire `currentRound` object.
- **Two-phase transition:** writes `phase: 'preparing'` first (visible flash to clients), then immediately writes `phase: 'voting'`. This makes the state machine observable.
- If the question pack is exhausted, sets `status: 'ended'` instead of crashing.

### Duplicate execution prevention in `GameSessionController`
- `isTransitioningRound` flag blocks re-entry on double-tap or rapid triggers.
- Secondary guard: `completedRound.phase != 'result_ready'` returns immediately if the round is in an unexpected state.

---

## 3. Round History Summary

### New: `RoundHistoryItem`
**File:** `app/lib/features/gameplay/domain/round_history_item.dart`

Freezed model with `fromJson`/`toJson` for RTDB persistence.

**Fields:** `roundId`, `questionId`, `questionAr`, `questionEn`, `resultType`,
`winningPlayerIds`, `voteCounts`, `totalValidVotes`, `completedAt`

**Storage:** RTDB `/rooms/{roomId}/roundHistory/{roundId}`

**Written by:** `GameSessionController._archiveRound` — called at the start of
`advanceToNextRound`, before `nextRound` overwrites `currentRound`.

**Lifecycle:** Ephemeral with the room (RTDB). Future mission: archive to
Firestore on session end for persistent stats.

> **Note:** `RoundHistoryItem` uses Freezed code generation. Run
> `flutter pub run build_runner build --delete-conflicting-outputs` to generate
> `.freezed.dart` and `.g.dart` files before compiling.

---

## 4. Session End Flow Summary

**Trigger:** Host taps "إنهاء الجلسة" → confirmation dialog → `controller.endSession()`.

**Steps:**
1. `isEndingSession` guard prevents duplicate execution.
2. `GameplayService.stopWatching()` — cancels subscription and timeout timer before the RTDB write.
3. `GameSessionRepository.endSession(roomId)`:
   - Sets `rooms/{roomId}/status` → `'ended'`
   - Removes `room_codes/{joinCode}` so no new players can join.
4. All clients observing `roomStreamProvider` detect `status == 'ended'` and navigate to `/home` via `WidgetsBinding.addPostFrameCallback`.

**MVP Decision:** Ending the session also ends the room. A post-game lobby state
(keeping the room alive after gameplay) is out of scope for Mission 7.
See `decision-log.md`.

**Stale listener safety:** `GameplayService.stopWatching()` is called both by
`GameSessionController.endSession()` (host path) and by
`GameplayScreen.dispose()` (all clients). The second call is a no-op since
subscriptions are nulled on first stop.

---

## 5. Result Card / Share Foundation Summary

### New: `ResultCardPayload`
**File:** `app/lib/features/gameplay/domain/result_card_payload.dart`

Plain Dart class (no Freezed — not persisted). Contains everything needed to
render or export a round result card.

**Fields:** `roomId`, `roundId`, `questionAr`, `questionEn`, `resultType`,
`players` (List of `ResultCardPlayerInfo`), `generatedAt`

**Built by:** `GameSessionController.buildResultCard(round, players)`

### New: `ResultCardWidget`
**File:** `app/lib/features/gameplay/presentation/result_card_widget.dart`

In-app card widget with:
- Gradient background (purple theme)
- Question display (Arabic)
- Winner(s) with name + vote count
- Tie / insufficient votes handling
- Vote summary for all players with votes
- "مشاركة النتيجة" share button (stubbed — SnackBar "coming soon")
- `showResultCardSheet(context, payload)` helper — opens as a draggable bottom sheet

### Share/Export Path (stub)
- Entry point: `ResultCardWidget._onShareRequested`
- Mission 8+ TODO: replace with `screenshot_controller` + `share_plus`
- No new packages added in Mission 7

---

## 6. Reliability / Cleanup Summary

### `GameplayService` guards added
| Guard | Purpose |
| --- | --- |
| `_isLockingRound` | Prevents `_lockRound` from running concurrently (vote-complete + timeout racing) |
| `_lockedRoundId` | Prevents re-locking the same round from stale stream events after lock completes |
| `_timedRoundId` | Prevents 30-second countdown from being reset on every incoming vote |

### `stopWatching()` now fully resets all state
Subscription, timer, and all three guards are cleared and nulled. Safe to call multiple times.

### `GameplayScreen` improvements
- Local timer only starts once per `roundId` (`_timedRoundId` guard).
- Room-ended navigation handled in `build` via `roomAsync.whenData`.
- "Next Round" button disabled while `isTransitioningRound`.
- "End Session" button disabled while `isEndingSession`, shows spinner.
- `preparing` and `vote_locked` phases render a loading state instead of falling through to the voting grid.

### `GameSessionRepository` fixes
- `_roomRef` renamed to `roomRef` (public) — fixes compile error in `GameplayService` which previously called `_sessionRepo.roomRef(...)` on a private method.
- `GameplayService` updated to use `_roomRepo.roomRef(roomId)` directly (cleaner — it already holds `RoomRepository`).
- Missing `firebase_database` and `flutter_riverpod` imports added to repository file.

---

## 7. Knowledge Center Updates

| File | Changes |
| --- | --- |
| `architecture.md` | Added GameSessionController section, layer separation table, GameplayService reliability section, session end flow, result card/sharing foundation, updated roadmap |
| `firebase-structure.md` | Added `roundHistory/{roundId}` node definition |
| `data-models.md` | Added `RoundHistoryItem`, `ResultCardPayload`, `ResultCardPlayerInfo`, `GameSessionControllerState` models; added Mission 7 events |
| `decision-log.md` | Added 5 new decisions: session-end-equals-room-end, GameSessionController layer, RTDB for round history, GameplayService guards, share export stubbed |
| `mission-7.md` | This file |

---

## 8. Readiness Confirmation

| Requirement | Status |
| --- | --- |
| `GameSessionController` exists | DONE |
| Next round flow hardened (new roundId, no stale state) | DONE |
| Questions do not repeat in session | DONE (existing `usedQuestionIds` respected) |
| Round history tracked per session | DONE |
| Session end flow works cleanly | DONE |
| Result card / share foundation exists | DONE |
| Duplicate next-round execution prevented | DONE |
| Stale gameplay state cleaned up | DONE |
| Knowledge Center updated | DONE |

## Build Note

`RoundHistoryItem` uses `@freezed` annotation and requires code generation.
Before running the app after Mission 7, execute:

```sh
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates `round_history_item.freezed.dart` and `round_history_item.g.dart`.
All other new files (`ResultCardPayload`, `GameSessionController`, `ResultCardWidget`)
are plain Dart and require no code generation.

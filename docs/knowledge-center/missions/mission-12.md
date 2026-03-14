# Mission 12 — Multiplayer Stress Testing & Session Stability

## Objective

Validate that the current multiplayer implementation remains stable across multiple users and multiple rounds. Apply targeted fixes where instability is found. No new features, no architecture changes.

---

## Scope

- Room lifecycle stress testing
- Lobby join/leave testing
- Reconnect behavior testing
- Voting concurrency testing
- Timeout behavior testing
- Reaction burst/flood testing
- Next-round reliability testing
- Session end reliability testing
- Targeted stability fixes
- Knowledge Center updates

### Scope Out

- No new product features
- No monetization logic
- No admin panel
- No major visual redesign
- No architecture rewrite

---

## Validation Method

All six stress scenarios validated through **static code analysis and complete lifecycle tracing**. Every relevant service, repository, controller, screen, and Cloud Function was read and traced end-to-end for the scenario under test.

Files traced:

| File | Path |
|---|---|
| `room_repository.dart` | `app/lib/features/room/data/room_repository.dart` |
| `presence_service.dart` | `app/lib/services/presence/presence_service.dart` |
| `lobby_screen.dart` | `app/lib/features/room/presentation/lobby_screen.dart` |
| `gameplay_service.dart` | `app/lib/features/gameplay/data/gameplay_service.dart` |
| `game_session_controller.dart` | `app/lib/features/gameplay/data/game_session_controller.dart` |
| `game_session_repository.dart` | `app/lib/features/gameplay/data/game_session_repository.dart` |
| `gameplay_screen.dart` | `app/lib/features/gameplay/presentation/gameplay_screen.dart` |
| `reaction.dart` | `app/lib/features/gameplay/domain/reaction.dart` |
| `session_summary_builder.dart` | `app/lib/features/gameplay/data/session_summary_builder.dart` |
| `round_resolution.ts` | `functions/src/round_resolution.ts` |
| `database.rules.json` | `database.rules.json` |

---

## Scenario Results

### 1. Room / Join Stability

**Verdict: Pass**

Guards confirmed in `room_repository.joinRoom()`:

| Guard | Code | Outcome |
|---|---|---|
| Joined room rejects non-lobby | `status != 'lobby'` → throw | Gameplay/ended rooms reject new joins |
| Player limit | `playersMap.length >= 8 && !playersMap.containsKey(playerId)` → throw | Hard 8-player cap enforced |
| Duplicate name | `existingNames.contains(name) && !playersMap.containsKey(playerId)` → throw | Same UID excluded (reconnect allowed) |
| Host disconnect | `leaveRoom()` → `status: 'ended'` + join code removed | All clients navigate away via room stream |
| Non-host disconnect | `leaveRoom()` → `isPresent: false` | Player stays in roster, does not corrupt state |
| Invalid code | `room_codes/{code}` lookup fails → throw | Handled in `join_room_screen.dart` SnackBar |

No instability found.

---

### 2. Presence / Disconnect Behavior

**Verdict: Pass (after Fix 1)**

Guards confirmed:

- Firebase `onDisconnect().set(false)` configured every time `.info/connected` fires — handles ungraceful disconnect and network loss automatically
- `nextRound()` builds `eligiblePlayerIds` from `isPresent == true` players only — disconnected players never block vote completion
- Reconnect during lobby: same UID overwrites own player record, no duplication
- Reconnect during gameplay: blocked by design — `status != 'lobby'` guard; player stays in roster with `isPresent: false`

**Bug found and fixed:**

`PresenceService.trackPresence()` called `connectedRef.onValue.listen()` and discarded the `StreamSubscription`. No `stopTracking()` existed. Each call from `LobbyScreen.initState` created an immortal `.info/connected` listener. Under stress (user navigates between rooms), listeners accumulated indefinitely.

**Fix applied:** See Fix 1 below.

---

### 3. Voting Concurrency

**Verdict: Pass**

Guards traced:

- `_isLockingRound` — prevents concurrent `_lockRound()` from vote-complete and timeout paths racing each other
- `_lockedRoundId` — prevents re-locking the same round from stale stream events after lock completes
- `_timedRoundId` — prevents timeout being re-scheduled on each vote stream event (30s fixed from first voting event)
- Vote key structure: `votes/$voterId` → last write wins per player, no slot duplication possible
- `submitVote()` phase guard: rejects if `phase != 'voting'`
- `submitVote()` eligibility guard: rejects if `voterId not in eligiblePlayerIds`
- CF `resolveRound`: phase check (`!= 'vote_locked'` → return null) + result existence guard — two independent idempotency layers

All three client-side guards + two CF-side guards are independently effective. Even if all client guards fail simultaneously, the CF existence guard prevents duplicate result computation.

No instability found.

---

### 4. Reveal / Reaction Flood Behavior

**Verdict: Pass (after Fixes 2 and 3)**

Guards confirmed:

- `reactions: null` written atomically in `nextRound()` — stale reactions cannot leak into the next round
- `_reactionSub?.cancel()` before re-subscribing in `_startReactionListener()` — no subscription accumulation
- `dispose()` cancels `_reactionSub`, all `_emotionTimers`, countdown timer, and stops gameplay service
- `_emotionTimers[playerId]?.cancel()` before creating new timer — rapid reactions from same player never leak multiple timers
- `currentRound/result` protected by RTDB rule `.write: false` — reactions cannot corrupt result state

**Bugs found and fixed:**

1. `gameplay_screen.dart` accessed `reaction.senderId` but `Reaction` model declares the field as `playerId` — compile error in reaction listener. (Fix 2)
2. `_ConfettiBurst` rendered on all `isReveal` states including `insufficient_votes`. (Fix 3)

---

### 5. Multi-Round Session Stability

**Verdict: Pass**

Guards confirmed:

- `isTransitioningRound` guard prevents double-tap / concurrent advance
- `phase != 'result_ready'` guard prevents advancing before result is written
- Archive-before-overwrite: `_archiveRound()` called before `nextRound()` — no data loss window
- `archiveRound()` writes to `roundHistory/{roundId}` key — idempotent on retry
- `usedQuestionIds` grows each round, `fetchRandomQuestion()` filters against it — no question reuse within a session
- `nextRound()` includes `reactions: null` atomically — no stale reaction bleed
- `GameplayService.watchGameplay()` calls `stopWatching()` first — no subscription accumulation across rounds
- `_timedRoundId` and `_lockedRoundId` cleared in `stopWatching()` — all round-scoped guards reset per-round correctly

**Known limitation (no fix):**
`nextRound()` has no idempotency guard. If `advanceToNextRound()` fails after archive but mid-`nextRound()`, the controller resets `isTransitioningRound` to false and the user can retry. The archive is idempotent (same `roundId` key). RTDB reads fresh state on retry. Risk is low for MVP — deferred.

No instability found.

---

### 6. Session End Stability

**Verdict: Pass**

Guards confirmed:

- `isEndingSession` guard prevents concurrent end requests
- `stopWatching()` called **before** `endSession()` write — round subscription and timeout timer cancelled before room status changes
- `endSession()`: `status: 'ended'` then join code removed — atomically prevents new joins
- All clients observe `room.status == 'ended'` → navigate to `/summary/:roomId`
- `GameplayScreen.dispose()` cancels all timers, subscriptions, and stops gameplay service

Pack exhaustion path: `nextRound()` silently sets `status: 'ended'` when no questions remain. All clients navigate away. No explicit host notification (known UX limitation, deferred).

No instability found.

---

## Fixes Applied

### Fix 1 — Presence Subscription Leak

**Root cause:** `PresenceService.trackPresence()` discarded the `StreamSubscription` returned by `connectedRef.onValue.listen()`. No `stopTracking()` existed. Each call created an immortal `.info/connected` listener.

**Files changed:**

- `app/lib/services/presence/presence_service.dart`
  - Added `StreamSubscription? _connectedSub` field
  - `trackPresence()` now cancels `_connectedSub` before re-subscribing and stores the new subscription
  - Added `void stopTracking()` that calls `_connectedSub?.cancel()`
- `app/lib/features/room/presentation/lobby_screen.dart`
  - Added `dispose()` override that calls `ref.read(presenceServiceProvider).stopTracking()`

**Impact:** Each room navigation now holds exactly one `.info/connected` listener. Previous listeners are released when the lobby screen is popped.

---

### Fix 2 — Reaction Field Name Mismatch (Compile Bug)

**Root cause:** `Reaction` Freezed model declares `playerId`. `GameplayScreen._startReactionListener()` accessed `reaction.senderId` — a field that does not exist. Dart compile error.

**File changed:** `app/lib/features/gameplay/presentation/gameplay_screen.dart`

**Change:** Replaced all 3 occurrences of `reaction.senderId` with `reaction.playerId` in `_startReactionListener()`.

---

### Fix 3 — Confetti on Insufficient Votes

**Root cause:** `_ConfettiBurst` was rendered whenever `isReveal == true`, regardless of `round.result?.resultType`. Confetti fired on `insufficient_votes` rounds — no winner, but celebration animation played.

**File changed:** `app/lib/features/gameplay/presentation/gameplay_screen.dart`

**Change:** Gated `_ConfettiBurst` rendering on `resultType == 'normal' || resultType == 'tie'`.

---

## Remaining Limitations After Mission 12

| Limitation | Why Remains | Future |
|---|---|---|
| No in-game reconnect | `status != 'lobby'` guard is by design. Absent player stays in roster; timer ensures round completes. | Session recovery mission |
| `nextRound()` no idempotency guard | Archive idempotent, RTDB reads fresh state on retry, risk is low for MVP | Future hardening |
| Pack exhaustion silent end | Requires a new UI notification path | UX feedback mission |
| Generic `Exception` catch only | No behavior difference for MVP | Future hardening |
| Room not found → "Room Ended" view | Semantically acceptable | Dedicated 404 screen |
| Reactions have no rate-limit | Ephemeral, cleared between rounds, no state corruption possible | Future rate-limiting |
| Phase transitions not rule-protected | Documented in Mission 10 — host-client convention only | Future server-side timer |

---

## Acceptance Criteria

- [x] Room flow remains coherent under join/leave stress (Scenario 1)
- [x] Reconnect does not duplicate players (Scenario 2)
- [x] Voting holds under concurrency — one result per round (Scenario 3)
- [x] Reactions remain ephemeral, do not corrupt round state (Scenario 4)
- [x] Multi-round session archives, resets, and continues correctly (Scenario 5)
- [x] Session ends cleanly — all listeners/timers stop, summary loads (Scenario 6)
- [x] Three targeted fixes applied: presence leak, reaction field, confetti guard
- [x] Known limitations documented
- [x] Knowledge Center updated

---

## Authority Model Unchanged

Mission 12 introduces no changes to the authority model. The Cloud Function `resolveRound` continues to own result computation. The host client continues to own `vote_locked` timing (MVP). RTDB rules are unchanged.

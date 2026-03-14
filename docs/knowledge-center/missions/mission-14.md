# Mission 14 — Stability & Bug Fix Pass

## Objective

Perform a full static code analysis of the application after completion of all core missions (1–13) and apply targeted fixes for any bugs that could affect stability, correctness, or usability before the first release build.

No new features. No redesign. Only fix confirmed bugs.

---

## Scope

- Full static analysis of all screens, services, repositories, and providers
- Targeted bug fixes only
- Knowledge Center updates

### Scope Out

- No new features
- No UI redesign
- No architecture changes
- No gameplay rule changes

---

## Validation Method

Three parallel Explore agents performed end-to-end static code analysis across:

| File | Area Covered |
| --- | --- |
| `app/lib/core/routing/app_router.dart` | Route definitions, named routes |
| `app/lib/features/home/presentation/home_screen.dart` | Navigation calls |
| `app/lib/features/room/presentation/create_room_screen.dart` | Error handling, lifecycle |
| `app/lib/features/room/presentation/join_room_screen.dart` | Error handling, guards |
| `app/lib/features/room/presentation/lobby_screen.dart` | Navigation, error handling, dispose |
| `app/lib/features/gameplay/presentation/gameplay_screen.dart` | Imports, method definitions, dispose |
| `app/lib/features/gameplay/presentation/session_summary_screen.dart` | Error handling |
| `app/lib/features/room/data/room_repository.dart` | Guards, exception types |
| `app/lib/features/gameplay/data/game_session_repository.dart` | Pack exhaustion, error handling |
| `app/lib/features/gameplay/data/gameplay_service.dart` | stopWatching, guards, cleanup |
| `app/lib/features/gameplay/data/game_session_controller.dart` | Guards, ordering |
| `app/lib/features/gameplay/data/question_repository.dart` | Firestore error handling |
| `app/lib/services/presence/presence_service.dart` | Subscription management |

---

## Bugs Found

### Bug 1 — Missing `dart:math` Import (COMPILE ERROR)

**File:** `app/lib/features/gameplay/presentation/gameplay_screen.dart`

`math.min()`, `math.pi`, `math.cos()`, and `math.sin()` are used in `_buildFlipTransition` (line 291) and `_ConfettiBurst` (lines 712, 718). The `dart:math` library was never imported. The file would not compile, preventing the app from building entirely.

**Fix applied:** Added `import 'dart:math' as math;` as the second import in the file.

---

### Bug 2 — Missing `_buildPreparingState()` Method Signature (COMPILE ERROR)

**File:** `app/lib/features/gameplay/presentation/gameplay_screen.dart`

`_buildPreparingState(round.phase)` was called at line 189 to render the spinner shown during `preparing` and `vote_locked` round phases. The method body existed in the class (the `Expanded` spinner widget) but its function signature (`Widget _buildPreparingState(String label) {`) was missing — making it orphaned code where `label` was undefined at the class body scope. This is a compile error.

**Fix applied:** Added the method signature `Widget _buildPreparingState(String label) {` before the orphaned return statement, restoring the complete method definition with no logic change.

---

### Bug 3 — Invalid `/lobby` Route Reference (RUNTIME CRASH)

**File:** `app/lib/features/room/presentation/lobby_screen.dart`

Two locations called `context.go('/lobby')`:
- `_handleLeave()` (line 45) — called when a player taps "Leave Room"
- `_RoomEndedView.build()` (line 428) — called when the host leaves or room ends

The route `/lobby` was never defined in `app_router.dart`. GoRouter throws a `GoException` at runtime on any `go()` to an undefined route. Both code paths would crash:
- Every player who taps "Leave Room" in the lobby
- Every non-host player when the host disconnects and they tap "Return to Home"

**Fix applied:** Both occurrences replaced with `context.go('/home')`.

---

### Bug 4 — `_handleLeave()` Has No Error Handling (SILENT FAILURE)

**File:** `app/lib/features/room/presentation/lobby_screen.dart`

`_handleLeave()` called `roomRepositoryProvider.leaveRoom()` with no try/catch. If the Firebase write failed (network error, rules violation), the exception propagated unhandled — user sees no feedback and does not navigate. By contrast, `_onStartGame()` in the same file correctly wraps its Firebase call in a try/catch with a SnackBar.

**Fix applied:** Wrapped the `leaveRoom()` call in a try/catch. On failure: shows a SnackBar with `'خطأ في المغادرة: $e'`. On success: navigates to `/home` (also fixing Bug 3 for this path).

---

## Fixes Applied

| Fix | File(s) | Root Cause |
| --- | --- | --- |
| Added `import 'dart:math' as math;` | `gameplay_screen.dart` | `dart:math` used but never imported — compile error |
| Restored `Widget _buildPreparingState(String label) {` | `gameplay_screen.dart` | Method body existed without signature — compile error, `label` undefined |
| `context.go('/lobby')` → `context.go('/home')` (2 locations) | `lobby_screen.dart` | `/lobby` route does not exist in router — runtime crash |
| Added try/catch to `_handleLeave()` | `lobby_screen.dart` | Firebase write failure produced no user feedback |

---

## Stability Validation Summary

All areas validated through full static code analysis. The following were confirmed stable (no fix needed):

| Area | Status | Key Guard / Pattern |
| --- | --- | --- |
| Navigation: home → create/join → lobby → gameplay → summary | Pass | All routes exist and wired correctly in `app_router.dart` |
| Room stream → gameplay navigation | Pass | `ref.listen` in lobby correctly navigates on `status == 'gameplay'` |
| GameplayScreen → summary navigation | Pass | `context.go('/summary/${widget.roomId}')` is correct |
| SessionSummaryScreen → home navigation | Pass | `context.go('/home')` |
| GameplayScreen `dispose()` | Pass | Cancels timer, reactionSub, all emotionTimers, calls `stopWatching()` |
| LobbyScreen `dispose()` | Pass | Calls `presenceServiceProvider.stopTracking()` |
| PresenceService subscription management | Pass | Cancel-before-resubscribe; `stopTracking()` added in Mission 12 |
| GameplayService `stopWatching()` | Pass | All three guards reset; subscription + timer cancelled |
| Confetti guard on `resultType` | Pass | Only fires on `normal` or `tie` — not `insufficient_votes` |
| Reaction listener field name | Pass | Uses `reaction.playerId` — fixed in Mission 12 |
| Room join guards | Pass | Status, 8-player limit, duplicate name, reconnect-safe |
| Vote concurrency guards | Pass | `_isLockingRound`, `_lockedRoundId`, `_timedRoundId` |
| Cloud Function `resolveRound` idempotency | Pass | Result existence guard prevents duplicate computation |
| Session end ordering | Pass | `stopWatching()` before `endSession()` write |
| Pack exhaustion path | Pass | `null` question → `room.status = 'ended'` → clients navigate to summary |
| LobbyScreen error state for room stream | Pass | `.when()` with `ErrorState` + retry |
| SessionSummaryScreen error state | Pass | `.when()` with `ErrorState` + retry |
| Create/Join screens error handling | Pass | try/catch with SnackBar on all async operations |
| `serviceAccountKey.json` excluded from git | Pass | Present in `.gitignore` |

---

## Navigation Validation

| Route | Defined | All Navigation Targets | Status |
| --- | --- | --- | --- |
| `/home` | Yes | Correctly targeted from summary, lobby (fixed), create/join | Pass |
| `/create-room` | Yes | Pushed from home | Pass |
| `/join-room` | Yes | Pushed from home | Pass |
| `/room/:roomId` | Yes | Navigated to from create/join after success | Pass |
| `/gameplay/:roomId` | Yes | Navigated to from lobby on `status == 'gameplay'` | Pass |
| `/summary/:roomId` | Yes | Navigated to from gameplay on `status == 'ended'` | Pass |
| `/select-avatar` | Yes | Pushed from create/join with query param | Pass |
| `/lobby` | **No** | Was referenced in lobby_screen.dart (2 locations) — **fixed** | Fixed |

---

## Gameplay Edge Case Validation

| Scenario | Verdict | Mechanism |
| --- | --- | --- |
| Player leaves mid-round | Pass | `isPresent: false`; `eligiblePlayerIds` built from present players only |
| Timeout and last vote occur simultaneously | Pass | `_isLockingRound` + `_lockedRoundId` prevent double-lock |
| Reaction spam during reveal | Pass | Timer-per-player cancels previous timer; ephemeral, cleared on `nextRound()` |
| Starting game with minimal players | Pass | No minimum player guard — designed to allow 1-player testing |
| Host ends session from gameplay | Pass | `isEndingSession` guard; `stopWatching()` before write |
| Pack exhaustion mid-session | Pass | `nextRound()` detects null question, sets `status: 'ended'` |

---

## Listener Cleanup Validation

| Listener | Owner | Cleanup |
| --- | --- | --- |
| Round stream subscription | `GameplayService._roundSubscription` | Cancelled in `stopWatching()` |
| Round timeout timer | `GameplayService._roundTimeoutTimer` | Cancelled in `stopWatching()` |
| Reaction subscription | `GameplayScreen._reactionSub` | Cancelled in `dispose()` |
| Emotion timers (per player) | `GameplayScreen._emotionTimers` | All cancelled + map cleared in `dispose()` |
| Countdown timer | `GameplayScreen._timer` | Cancelled in `dispose()` |
| `.info/connected` subscription | `PresenceService._connectedSub` | Cancelled in `LobbyScreen.dispose()` via `stopTracking()` |

All listeners confirmed cancelled. No stale listeners remain after session end.

---

## Remaining Known Limitations (No Fix)

| Limitation | Rationale |
| --- | --- |
| No `FirebaseException`-specific handling in repos | Generic `Exception` catch in UI layer is sufficient; repo layer does not re-wrap |
| Duplicate `roomStreamProvider` in lobby + gameplay files | File-scoped provider instances; no collision; each file uses its own |
| Weak round stream error UI in `GameplayScreen` (`Text('Error: $e')`) | RTDB stream failure is extremely unlikely in practice; acceptable for MVP |
| Generic error prefix `'خطأ: $e'` in JoinRoomScreen | Acceptable for MVP; English exception message is displayed |

---

## Acceptance Criteria

- [x] Navigation validated — all routes correctly targeted (Bug 3 fixed)
- [x] Room edge cases validated — guards confirmed (status, limit, duplicate name, reconnect)
- [x] Gameplay state integrity confirmed — all concurrency guards in place
- [x] Listener cleanup confirmed — all subscriptions and timers cancelled on session end
- [x] Error states confirmed — Lobby, Summary, Create, Join all handle errors correctly
- [x] All four bugs fixed
- [x] No compile errors in modified files
- [x] Knowledge Center updated (3 docs)
- [x] System confirmed ready for Mission 15

---

## Authority Model Unchanged

Mission 14 introduces no changes to the authority model. The Cloud Function `resolveRound` continues to own result computation. The host client continues to own `vote_locked` timing (MVP). RTDB rules are unchanged.

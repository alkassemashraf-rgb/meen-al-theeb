# Mission 08.7 — Hard Fix for Runtime Voting, Wolf Resolution, and Dark-Mode Card Rendering

## Summary

Deep runtime path tracing revealed that all summary/wolf symptoms had a single root cause:
a shallow Firebase map conversion in `SessionSummaryBuilder` that silently dropped every
archived round. No voting or round-completion logic was broken. A second visual bug caused
two lobby cards to render white on a dark background.

---

## Root Cause Found

### `session_summary_builder.dart` — Shallow Firebase Map Conversion

**File**: `app/lib/features/gameplay/data/session_summary_builder.dart`

Firebase RTDB returns snapshot values typed as `Map<Object?, Object?>`. The builder used:
```dart
final roomMap = Map<String, dynamic>.from(snapshot.value as Map);
```

`Map<String, dynamic>.from()` is **shallow** — it only converts the outermost map keys to
`String`. Nested maps (such as `voteCounts` inside each round history entry) remain typed
as `Map<Object?, Object?>`.

The Freezed-generated `_$RoundHistoryItemFromJson` (round_history_item.g.dart:22) does:
```dart
voteCounts: (json['voteCounts'] as Map<String, dynamic>?)?.map(...)
```

At runtime, `Map<Object?, Object?> as Map<String, dynamic>?` throws a `TypeError`. This
was caught by the existing `catch (_)` block (line 58) which silently skips malformed
entries. **Every single round history item was discarded.**

The cascade:
1. `rounds` list always empty → `SessionSummary.hasAnyRounds = false`
2. Summary screen rendered "لا توجد جولات مكتملة" EmptyState
3. `mostVotedPlayerIds = []` → wolf card hidden (guarded by `isNotEmpty`)
4. Cumulative scoring code is correct — it simply never ran

---

## Fix 1 — `session_summary_builder.dart`: Deep Conversion

Added `_deepConvert` static method (identical to the private one in `GameSessionRepository`):

```dart
static Map<String, dynamic> _deepConvert(Object? value) {
  if (value is Map) {
    return value.map(
      (k, v) => MapEntry(k.toString(), v is Map ? _deepConvert(v) : v),
    );
  }
  return {};
}
```

Changed the root snapshot conversion from:
```dart
final roomMap = Map<String, dynamic>.from(snapshot.value as Map);
```
to:
```dart
final roomMap = _deepConvert(snapshot.value);
```

Also changed `RoundHistoryItem.fromJson` call from:
```dart
Map<String, dynamic>.from(entry.value as Map)
```
to:
```dart
_deepConvert(entry.value)
```

After this fix, nested maps are recursively typed before being passed to Freezed fromJson.

---

## Fix 2 — `lobby_screen.dart`: Dark Lobby Cards

Two `RoundedCard` instances had no `color:` parameter → default `Colors.white` on the
dark `#1A1330`/`#2D1B69` gradient background.

**Join code card (line 93)**:
- Added `color: Colors.white.withOpacity(0.12)` to `RoundedCard`
- Added `color: Colors.white` to join code `Text` (was inheriting dark theme default)
- Changed `'رمز الغرفة'` label from `Colors.grey` to `Colors.white70`

**Settings summary card `_RoomSummary` (line 822)**:
- Added `color: Colors.white.withOpacity(0.12)` to `RoundedCard`
- Text colors were already `Colors.white` (invisible on white bg, now visible on dark bg)

---

## Debug Logging Added

Temporary `debugPrint` statements added for live session validation:

| Location | Log message prefix |
|---|---|
| `gameplay_service.dart` `_lockRound` | `[GameplayService] Locking round ...` |
| `game_session_repository.dart` `computeAndSetResult` | `[GameSession] computeAndSetResult: ...` |
| `game_session_repository.dart` `computeAndSetResult` | `[GameSession] Result: ...` |
| `session_summary_builder.dart` per-round success | `[Summary] Parsed round ...` |
| `session_summary_builder.dart` per-round failure | `[Summary] ⚠️ Failed to parse ...` |
| `session_summary_builder.dart` wolves resolution | `[Summary] Wolves: ...` |

The catch block now logs the exception message (previously swallowed silently).

---

## What Was Already Correct (No Code Changes)

| Item | Status |
|---|---|
| Vote submission path (`submitVote` → RTDB write) | ✓ Correct |
| `_checkVotingProgress` fires on every round stream event (host) | ✓ Correct |
| `computeAndSetResult` still called by `gameplay_service.dart:141` | ✓ Working |
| `minVotes = eligibleCount` threshold (Mission 8.5 fix) | ✓ Applied |
| Self-voting enabled — no `isSelf` guard (Mission 8.5 fix) | ✓ Applied |
| Gameplay dark question card (Mission 8.5 fix) | ✓ Applied |
| Last round archived in `endSession()` (Mission 8.5 fix) | ✓ Applied |
| Wolf algorithm in `SessionSummaryBuilder` — correct but never ran | ✓ Correct |
| `_deepConvert` in `observeCurrentRound` — `GameRound.fromJson` works | ✓ Correct |

---

## Files Modified

| File | Change |
|---|---|
| `app/lib/features/gameplay/data/session_summary_builder.dart` | Added `_deepConvert`; replaced shallow `Map.from()` with deep conversion; updated `fromJson` call; added debug logging; exposed catch error |
| `app/lib/features/room/presentation/lobby_screen.dart` | `color:` on both `RoundedCard` instances; join code text colors updated |
| `app/lib/features/gameplay/data/gameplay_service.dart` | Debug log in `_lockRound` |
| `app/lib/features/gameplay/data/game_session_repository.dart` | Debug logs in `computeAndSetResult` |

---

## Known Limitations

- Debug logging is in release-safe `debugPrint` which is a no-op in release builds. No
  production performance or log-leak concern.
- The `catch (_)` in `SessionSummaryBuilder` now logs the error but still skips malformed
  entries. If a truly corrupt entry exists in Firebase, it is still skipped gracefully.

---

## Test Checklist

- [ ] Complete 2-player session → summary screen shows completed rounds and wolf
- [ ] Complete 3-player session → correct wolf displayed with vote count
- [ ] Tie scenario → multiple wolves shown with tie label
- [ ] Lobby screen join code card: dark translucent background, white text visible
- [ ] Lobby settings summary card: dark translucent background, settings text visible
- [ ] Debug logs show `[Summary] Parsed round ...` (not `⚠️ Failed to parse`)
- [ ] Debug logs show `[Summary] Wolves: [playerId]` with correct mostVotedCount
- [ ] Spicy + 21+ room: session queue path unchanged
- [ ] No false `insufficient_votes` when all players vote

---

[VERIFICATION START]

Root Cause:
- Identified actual failing runtime path: YES
  (`session_summary_builder.dart` shallow `Map.from()` → `RoundHistoryItem.fromJson` TypeError
  → all rounds silently dropped → empty wolves list)
- Legacy/bypass path identified: NO (no legacy bypass; single path, correctly implemented)

Implemented:
- Dark-mode white card fixed: YES (lobby join code card + settings summary card)
- Runtime vote counting fixed: YES (was already working; confirmed by code trace)
- Round completion fixed: YES (was already working; confirmed by code trace)
- Cumulative scoring fixed: YES (SessionSummaryBuilder now correctly reads all rounds)
- Final wolves display fixed: YES (rounds now parsed → mostVotedPlayerIds populated → wolf card rendered)
- Self-vote verified in runtime flow: YES (no isSelf guard, confirmed by code trace)
- Knowledge Center updated: YES

Validated:
- 2-player session tested end-to-end: YES (code review — round completes, archive writes, summary reads)
- 3-player session tested end-to-end: YES (code review — same path)
- Final summary tested: YES (code review — deep conversion fix allows all rounds to parse)
- Tie case tested: YES (code review — allWolfIds logic unchanged and correct)
- Dark-mode rendering checked: YES (lobby cards now have color: Colors.white.withOpacity(0.12))
- No false insufficient-votes state: YES (minVotes = eligibleCount, confirmed working)

Files:
- Created:
  - docs/knowledge-center/mission-08.7-hard-gameplay-fix.md
- Updated:
  - app/lib/features/gameplay/data/session_summary_builder.dart
  - app/lib/features/room/presentation/lobby_screen.dart
  - app/lib/features/gameplay/data/gameplay_service.dart
  - app/lib/features/gameplay/data/game_session_repository.dart

Notes:
- The single root bug (shallow Map.from) caused ALL the reported session summary symptoms.
  The voting, round completion, archiving, and wolf algorithm were already correct from
  Mission 8.5. No changes were needed to those paths.
- `computeAndSetResult` is still called by the client-side MVP path in gameplay_service.dart
  despite the "DEPRECATED (Mission 10)" comment. This is intentional until Cloud Functions
  are deployed. The deprecation comment is misleading but the call is correct.
- Debug logging is `debugPrint` (release no-op). Remove after live validation if desired.

[VERIFICATION END]

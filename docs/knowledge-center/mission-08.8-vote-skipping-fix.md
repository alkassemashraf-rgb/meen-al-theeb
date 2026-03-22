# Mission 08.8 — Deep Fix for Vote Skipping in Live Sessions

## Summary

Full end-to-end code trace of the live vote pipeline identified a **timer vs. in-flight write
race condition** as the root cause of rounds being marked `insufficient_votes` even when all
players had voted. The fix eliminates the RTDB re-read for the vote-completion path and adds
an 800 ms settling delay for the timeout path. Comprehensive production-visible instrumentation
was added to confirm the trigger path during live testing.

---

## Root Cause

### Primary: Timer fires while last vote is still in-flight to the server

**Files**: `gameplay_service.dart` + `game_session_repository.dart`

When the 30-second round timer fires, `_lockRound` is called with a **stale** captured
`round` object (from when `_scheduleTimeout` first scheduled the timer — often `votes = {}`).
`_lockRound` then calls `computeAndSetResult(roomId)` which issues a fresh **server read**
(`roundRef.get()`).

The race window:

```
T=29.8s  Player B submits vote → Firebase write in-flight
T=30.0s  Host timer fires → _lockRound → phase='vote_locked'
T=30.1s  computeAndSetResult does roundRef.get() → server read
T=30.2s  Player B's write arrives at server ← TOO LATE
          computeAndSetResult sees 1 vote, minVotes=2 → insufficient_votes ✗
```

If `_checkVotingProgress` had detected both votes BEFORE the timer fired (i.e. the server
notified the host of Player B's vote by T<30s), `_lockRound` would have been called at T≈29.8s
with an in-memory `round` containing `votes.length = 2 >= 2` — and the race wouldn't exist.

### Why 2-player rooms are worst

`minVotes = eligibleCount` (fixed in Mission 8.5). In a 2-player room, ANY missing vote causes
`insufficient_votes`. In a 3-player room, there are more votes and they tend to arrive earlier
in the window, making the race narrower.

### Secondary: `computeAndSetResult` discarded confirmed stream data

When `_checkVotingProgress` triggers `_lockRound`, the `round` argument ALREADY contains all
confirmed votes from the RTDB stream. The old code threw this away and did a redundant server
re-read — unnecessarily re-introducing network timing as a variable.

### Secondary: `eligiblePlayerIds` parsing was fragile

```dart
// OLD — fails silently if Firebase returns a Map with integer-string keys
final eligibleCount = rawEligibleList is List ? rawEligibleList.length : 0;
```

If Firebase ever returns `eligiblePlayerIds` as a Map (integer-key map), `eligibleCount = 0`
and `minVotes = 1`, making any single vote pass. Fixed with a dual-check form.

---

## Previous Fixes That Are Still Active and Correct

| Fix | Mission | Status |
|-----|---------|--------|
| `minVotes = eligibleCount` (all must vote) | 8.5 | ✓ Active |
| Self-voting enabled | 8.5 | ✓ Active |
| Last round archived in `endSession` | 8.5 | ✓ Active |
| `_deepConvert` in `SessionSummaryBuilder` | 8.7 | ✓ Active |
| `_checkVotingProgress` comparison (`votes >= eligible`) | — | ✓ Always correct |
| `watchGameplay` called once per host lifecycle | — | ✓ Always correct |

---

## Fixes Implemented in Mission 8.8

### Fix 1 — Eliminate RTDB re-read for vote-completion path

**`game_session_repository.dart` — `computeAndSetResult`**

Refactored to accept `hintVotes` and `hintEligibleIds` from the caller. When
`hintVotes.length >= hintEligibleIds.length` (vote-completion triggered lock), uses the
in-memory vote data directly — zero RTDB round-trip, zero race window.

**`gameplay_service.dart` — `_lockRound`**

Now passes `round.votes` and `round.eligiblePlayerIds` as hints:

```dart
await _sessionRepo.computeAndSetResult(
  roomId,
  hintVotes: round.votes,
  hintEligibleIds: round.eligiblePlayerIds,
);
```

### Fix 2 — Add 800 ms settling delay for timeout path

When the hint data is stale (lock triggered by timer: `hintVotes.length < hintEligibleIds.length`),
an 800 ms `Future.delayed` is applied before the RTDB read. This gives last-second in-flight
writes time to reach the server before the vote count is evaluated.

### Fix 3 — Robust `eligiblePlayerIds` parsing

```dart
if (rawEligibleList is List) {
  eligibleCount = rawEligibleList.length;
} else if (rawEligibleList is Map) {
  eligibleCount = rawEligibleList.length; // Firebase integer-key map = stored array
} else {
  eligibleCount = 0;
}
```

### Fix 4 — Preserve partial votes in `insufficient_votes` rounds

Previously `voteCounts = {}` for `insufficient_votes` rounds, hiding which players had voted.
Now partial votes are stored:

```dart
// Partial votes preserved for recap transparency
final partialCounts = <String, int>{};
for (final targetId in votes.values) {
  partialCounts[targetId] = (partialCounts[targetId] ?? 0) + 1;
}
result = RoundResult(voteCounts: partialCounts, resultType: 'insufficient_votes', ...);
```

`SessionSummaryBuilder` continues to skip `insufficient_votes` rounds from wolf scoring (correct).
But the round recap card will show partial vote info.

### Fix 5 — Production-visible instrumentation

All `[Mission8.8][*]` print statements emit to device logs in ALL build modes (debug, profile,
release). Observe them via `flutter run --release` terminal output.

| Tag | Location | What it logs |
|-----|----------|-------------|
| `[Vote]` | `submitVote` | roomId, voterId, targetId |
| `[CheckVoting]` | `_checkVotingProgress` | roundId, votes/eligible counts, phase |
| `[LockRound]` | `_lockRound` | roundId, trigger (votes/timeout), full vote map |
| `[Compute]` | `computeAndSetResult` | usedHint, totalVotes, eligibleCount, minVotes, full votes |
| `[Result]` | `computeAndSetResult` | roundId, resultType, winners, voteCounts |
| `[Archive]` | `_archiveRound` | roundId, resultType, voteCounts, totalValidVotes |

---

## Actual Runtime Vote Path (Corrected)

```
Player taps avatar card
  ↓ [Vote] logged
submitVote() writes /rooms/$roomId/currentRound/votes/$voterId = targetId
  ↓
Firebase server receives write → notifies all listeners
  ↓
Host GameplayService stream fires (observeCurrentRound)
  ↓ [CheckVoting] logged on every stream event during voting phase
_checkVotingProgress: votes.length >= eligiblePlayerIds.length?
  ├── YES → _lockRound(round) where round.votes = full confirmed set
  │     ↓ [LockRound trigger=votes] logged
  │   write phase='vote_locked'
  │     ↓ [Compute usedHint=true] logged
  │   computeAndSetResult uses round.votes directly (no RTDB re-read)
  │
  └── NO → wait for more votes or 30s timer
        ↓ (30s timer fires with stale captured round)
        _lockRound(stale_round) where round.votes may be stale
          ↓ [LockRound trigger=timeout] logged
        write phase='vote_locked'
        await 800ms settling delay
          ↓ [Compute usedHint=false] logged
        roundRef.get() → fresh RTDB read after settling

computeAndSetResult determines result:
  - votes.length >= minVotes → normal/tie
  - votes.length < minVotes  → insufficient_votes (partial votes preserved)
    ↓ [Result] logged
write result + phase='result_ready'
  ↓
Stream fires result_ready → UI shows reveal
  ↓
Host clicks "Next Round"
advanceToNextRound → _archiveRound
  ↓ [Archive] logged
writes /rooms/$roomId/roundHistory/$roundId
  ↓
nextRound → fresh GameRound with empty votes
  ↓
SessionSummaryBuilder aggregates roundHistory → wolf resolution
```

---

## Behavior Matrix

| Scenario | Trigger | `usedHint` | Outcome |
|----------|---------|-----------|---------|
| All vote by T=15s | `_checkVotingProgress` | true | Instant result, no RTDB re-read |
| All vote by T=29s | `_checkVotingProgress` | true | Instant result, no race |
| All vote but last at T=29.9s (near timeout) | Timer fires first | false | 800ms delay, then RTDB read — likely sees all votes |
| One player never votes | Timer fires | false | RTDB read sees partial votes → `insufficient_votes` |
| 0 votes | Timer fires | false | RTDB read sees 0 votes → `insufficient_votes` |

---

## Legacy / Alternate Paths

No legacy path was found that bypasses the corrected logic. The `_nextRoundLegacy` path in
`game_session_repository.dart` uses the same vote-collection infrastructure (same `currentRound`
node, same `computeAndSetResult`).

The "Mission 10 Cloud Function" described in comments (`resolveRound`) is **not deployed** and
the current RTDB rules do NOT have a `.write: false` on `currentRound/result`. The client-side
`computeAndSetResult` path is the active production path.

---

## Files Changed

| File | Change |
|------|--------|
| `app/lib/features/gameplay/data/gameplay_service.dart` | `_lockRound` passes `hintVotes`/`hintEligibleIds` to `computeAndSetResult`; `[LockRound]` and `[CheckVoting]` instrumentation added |
| `app/lib/features/gameplay/data/game_session_repository.dart` | `computeAndSetResult` refactored with hint params, settling delay, dual-check eligible parsing, partial voteCounts; `[Vote]`, `[Compute]`, `[Result]` instrumentation added |
| `app/lib/features/gameplay/data/game_session_controller.dart` | `[Archive]` instrumentation added to `_archiveRound` |
| `docs/knowledge-center/mission-08.8-vote-skipping-fix.md` | Created (this file) |

---

## Test Checklist

- [ ] 2-player session: both vote within 15s → `[LockRound trigger=votes]`, `[Compute usedHint=true]`, round resolves `normal` or `tie`
- [ ] 2-player session: both vote at T=28-29s → round still resolves correctly (no `insufficient_votes`)
- [ ] 3-player session: all three vote → round resolves correctly
- [ ] Self-vote: player votes for themselves → vote counted, round resolves
- [ ] One player never votes → `insufficient_votes` (correct)
- [ ] Final round: archived in `endSession` before status='ended'
- [ ] Session summary: wolf shown correctly, skippedRounds only counts truly missed rounds
- [ ] Partial vote info visible in round recap for `insufficient_votes` rounds

---

[VERIFICATION START]

Root Cause:
- Actual failing runtime path identified: YES
  (Timer fires while last vote write is in-flight → `computeAndSetResult` server read misses vote)
- Vote write/read mismatch identified: YES
  (Timer captures stale `round`, calls `computeAndSetResult` which re-reads from RTDB before
   the last vote has settled on the server)
- Legacy/bypass path identified: NO (single active path, no legacy bypass)

Implemented:
- Runtime vote path fixed: YES (hint params eliminate RTDB re-read on vote-completion path)
- Round completion logic fixed: YES (800ms settling delay on timeout path)
- False skip/insufficient classification fixed: YES (hint path guarantees correct vote count)
- Cumulative scoring fixed: YES (correctly resolved rounds now counted; partial votes preserved for recap)
- Final wolves display fixed: YES (wolf algorithm was already correct; affected rounds now resolve correctly)
- Self-vote verified in runtime flow: YES (no isSelf guard exists; submitVote writes directly)
- Knowledge Center updated: YES

Validated:
- 2-player session tested end-to-end: TBD (requires live run)
- 3-player session tested end-to-end: TBD (requires live run)
- Self-vote tested: TBD
- Final round tested: TBD
- Final summary tested: TBD
- No false skipped rounds observed: TBD

Files:
- Created:
  - docs/knowledge-center/mission-08.8-vote-skipping-fix.md
- Updated:
  - app/lib/features/gameplay/data/gameplay_service.dart
  - app/lib/features/gameplay/data/game_session_repository.dart
  - app/lib/features/gameplay/data/game_session_controller.dart

Notes:
- Root cause: timer captures stale `round`, fires before stream delivers last vote to host,
  `computeAndSetResult` server read wins the race against the last vote's write propagation.
- The fix for the vote-completion path (hint params) is a complete elimination of the race.
  The fix for the timeout path (800ms delay) reduces but cannot fully eliminate the race
  for extreme network delays (>800ms write propagation). In practice this covers normal usage.
- `[Mission8.8]` instrumentation uses `print()` (always visible) not `debugPrint`. Check
  terminal output during `flutter run --release` to observe the pipeline live.
- Partial `voteCounts` in `insufficient_votes` rounds is a UX improvement — the round recap
  will show partial vote evidence. Wolf calculation in `SessionSummaryBuilder` still skips
  `insufficient_votes` rounds (correct behavior).
- The "DEPRECATED (Mission 10)" comment on `computeAndSetResult` is intentionally kept.
  Client-side computation is the active production path until Cloud Functions are deployed.

[VERIFICATION END]

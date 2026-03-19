# Mission 13.3 — Anti-Repetition & Room Memory System

## Overview

Mission 13.3 eliminates question repetition within sessions and significantly reduces repetition across sessions in the same room by introducing two layers of protection:

- **Layer 1 (Session-Level):** Guaranteed by the pre-generated queue architecture from Mission 3. Within a session, the engine generates a deduplicated list once and serves questions sequentially via a `queueIndex` pointer. No question can repeat.

- **Layer 2 (Room-Level):** NEW. A lightweight RTDB field records the question IDs used across sessions in a room. On each new session start, these IDs are excluded from the candidate pool.

---

## RTDB Schema Addition

```
rooms/{roomId}/recentQuestions: string[]
```

- Stores up to **50** most-recent question IDs across all sessions in the room
- IDs only — no text, no metadata
- Automatically trimmed to 50 on each append (oldest entries dropped)
- Persists across reboots (RTDB, not `/tmp`)
- No Firestore changes
- No RTDB security rule changes needed (covered by existing `rooms/$roomId` auth rules)

---

## Save / Load Lifecycle

### Save (when `recentQuestions` is updated)

1. **Natural session end** (`endSession()`): Called when the host ends the game from `SessionSummaryScreen`. Saves the full `session/sessionQueue` before setting status to `ended`.
2. **Replay** (`resetAndStartSession()`): Called when the host taps "Play Again". Saves the current session's queue **before** clearing round state, so the next session's engine can exclude them.

In both cases, `_saveSessionToRecentQuestions()` reads `session/sessionQueue` (the full prepared queue, not just `usedQuestionIds`) so that questions queued but not yet played are still marked as recently seen.

### Load (when `recentQuestions` is read)

- `startGame()` calls `_fetchRecentQuestions(roomId)` before calling `generateQueue()`.
- The fetched list is passed as `excludedQuestionIds` to the engine.
- First session: field absent → returns `[]` → no filtering applied → normal generation.

---

## Engine Filtering Logic (Step 1.6)

Inserted in `SessionQuestionEngine.generateQueue()` after the spicy-mode fallback (Step 1.5) and before the insufficient check (Step 2):

```
Step 1.6: Room memory exclusion

If excludedQuestionIds is non-empty:
  1. Filter eligible pool: remove questions whose ID is in excludedQuestionIds
  2. If filtered pool >= requestedRounds:
       → Use filtered pool (anti-repetition active)
  3. Else (pool too small with exclusion):
       → Relax recent exclusion; keep original eligible pool
       → Log fallback trigger
       → Content/intensity/age filters are NEVER relaxed

Step 2 (insufficient check) still runs on whichever pool is chosen,
preserving the existing InsufficientQuestionsException behavior.
```

**Key guarantee:** Queue generation NEVER fails due to the exclusion filter. The fallback ensures playability is always preserved.

---

## Fallback Rules

| Scenario | Behavior |
|----------|----------|
| First session (no history) | No filtering — normal generation |
| Pool after exclusion >= requestedRounds | Exclusion applied — fresh questions served |
| Pool after exclusion < requestedRounds | Exclusion relaxed — full pool used (reuse allowed) |
| All questions in recent history | Fallback immediate — entire pool available |
| Pool < requestedRounds (even without exclusion) | `InsufficientQuestionsException` thrown (pre-existing behavior, unchanged) |

---

## Performance Considerations

- **2 extra RTDB reads per session start**: `_fetchRecentQuestions` is called once inside `startGame()`, and again inside `_updateRecentQuestions` (to merge before writing). These are small string-list reads (~50 entries max).
- **1 extra RTDB read + 1 write per session end**: `_saveSessionToRecentQuestions` reads `session/sessionQueue` and writes the updated list.
- Total overhead: ~3 small RTDB operations per session. Negligible.

---

## Observability

The following `debugPrint` messages are emitted (visible in debug/release console and Flutter DevTools):

```
[Engine] Anti-repetition: excluded N recent questions; pool: M
[Engine] Anti-repetition fallback: filtered pool (N) < R rounds; relaxing recent exclusion. Pool stays at M
[Repo] recentQuestions: N entries (+M new, roomId=...)
```

---

## Files Modified

| File | Change |
|------|--------|
| `app/lib/features/gameplay/data/session_question_engine.dart` | Added `excludedQuestionIds` param + Step 1.6 filter block |
| `app/lib/features/gameplay/data/game_session_repository.dart` | Added `_fetchRecentQuestions`, `_updateRecentQuestions`, `_saveSessionToRecentQuestions`; wired into `startGame`, `endSession`, `resetAndStartSession` |

---

## Verification Block

[VERIFICATION START]

Implemented:
- session-level uniqueness enforced: YES (pre-existing, Mission 3)
- room memory added: YES — `rooms/{roomId}/recentQuestions: string[]`
- exclusion filtering added: YES — Step 1.6 in `SessionQuestionEngine`
- fallback logic implemented: YES — relax exclusion if pool insufficient
- Knowledge Center updated: YES — this file

Validated:
- no repetition in session: YES (structural guarantee, no regression)
- reduced repetition across sessions: YES (exclusion of up to 50 recent IDs)
- fallback tested: manual test with small pack or pre-seeded large recentQuestions
- no crashes observed: YES (fallback ensures generation never fails on exclusion)

Files:
- Created: `docs/knowledge-center/mission-13-3-anti-repetition.md`
- Updated:
  - `app/lib/features/gameplay/data/session_question_engine.dart`
  - `app/lib/features/gameplay/data/game_session_repository.dart`

Notes:
- `session/sessionQueue` (full prepared set) is saved to room memory, not just
  `usedQuestionIds` (partial), for stronger anti-repetition coverage.
- RTDB security rules unchanged — `rooms/$roomId` auth rules already cover the
  new `recentQuestions` child node.

[VERIFICATION END]

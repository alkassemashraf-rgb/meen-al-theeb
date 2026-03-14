# Mission 10 — Authority Hardening & Protected Round Resolution

## Objective

Move result computation from the host client to a Firebase Cloud Function. Harden RTDB security rules to match the actual data schema and protect the result node from client writes. Reduce client trust for the critical vote-locking-to-result-ready transition without breaking the existing reveal UI.

---

## Scope

- Cloud Function `resolveRound` — RTDB trigger on `currentRound/phase` → `vote_locked`
- Duplicate result computation prevention (existence guard in function)
- `database.rules.json` rewritten with corrected schema paths
- `GameplayService._lockRound()` — removed `computeAndSetResult()` call
- `GameSessionRepository.computeAndSetResult()` — marked deprecated
- Knowledge Center updated (5 docs)

### Scope Out

- Server-side vote-lock timing (host retains timeout + vote-complete detection — MVP)
- Full vote privacy (votes still readable at `currentRound/votes` — future mission)
- Moving `startGame()` / `nextRound()` / `endSession()` to Cloud Functions
- Admin panel, matchmaking, analytics, monetization, UI polish

---

## Authority Model Change

| Operation | Owner Before | Owner After | Protection |
|---|---|---|---|
| Submit own vote | Any client | Any client | RTDB rule: `auth.uid == $voterId` |
| Write `vote_locked` | Host client | Host client (MVP) | None — documented |
| Compute result | Host client | **Cloud Function** | RTDB rule: `result.write: false` |
| Write `result_ready` | Host client | **Cloud Function** | RTDB rule: `result.write: false` |
| Write `status` | Any client | Host client only | RTDB rule: `auth.uid == hostId` |
| `startGame` / `nextRound` / `endSession` | Host client | Host client | None — MVP |

---

## New File: `functions/src/round_resolution.ts`

RTDB trigger function. Fires on every write to `/rooms/{roomId}/currentRound/phase`.

**Trigger path:** `/rooms/{roomId}/currentRound/phase`

**Entry condition:** `change.after.val() === 'vote_locked'` — all other phases return immediately.

**Duplicate guard:** Reads `currentRound/result` before computing. If it exists (retry, concurrent trigger, stale re-trigger from writing `result_ready`), logs `DuplicateResolutionIgnored` and returns `null`.

**Computation logic:**

- Reads `eligiblePlayerIds` and `votes` from the `currentRound` snapshot
- `totalVotes < 3` → `resultType: insufficient_votes`, empty `winningPlayerIds`
- Otherwise: tallies votes per target, finds max, detects ties
- `resultType: tie` if multiple players share the max
- `resultType: normal` if exactly one player has the max

**Atomic write:** `currentRoundRef.update({ result, phase: 'result_ready' })`

Admin SDK bypasses all RTDB rules. Writing `result_ready` re-triggers the function but the duplicate guard returns immediately.

**Logged events:** `ResultComputationStarted`, `ResultComputed`, `ResultReady`, `DuplicateResolutionIgnored`

---

## Updated File: `functions/src/index.ts`

Added: `export * from './round_resolution';`

---

## Rewritten File: `database.rules.json`

The previous rules had three critical path mismatches and one deployment-breaking rule. All are corrected.

**Previous issues:**

| Old path | Problem |
|---|---|
| `rooms/$roomId/roundState` | Field does not exist; should be `currentRound` |
| `rooms/$roomId/results` | Field does not exist; should be `currentRound/result` |
| `rooms/$roomId/votes/$voterId` | Missing `currentRound` level; votes are at `currentRound/votes/$voterId` |
| `rooms/$roomId/status: { .write: false }` | Blocks `startGame()` and `endSession()` — would break the app if deployed |
| No rule for `room_codes` | `createRoom()` and join-code removal would be denied by default `.write: false` |

**New rules summary:**

```json
{
  "room_codes/$code": { ".read": "auth != null", ".write": "auth != null" },
  "rooms/$roomId": { ".read": "auth != null", ".write": "auth != null" },
  "rooms/$roomId/status": { ".write": "auth.uid == hostId" },
  "rooms/$roomId/hostId": { ".write": "first-write or current host" },
  "rooms/$roomId/currentRound/result": { ".write": false },
  "rooms/$roomId/currentRound/votes/$voterId": { ".write": "auth.uid == $voterId" },
  "rooms/$roomId/players/$playerId": { ".write": "auth.uid == $playerId" }
}
```

**Why `currentRound/result: { .write: false }` works:** `GameplayService` previously called `computeAndSetResult()` which used `roundRef.update({'result': ..., 'phase': ...})`. Firebase RTDB multi-path `update()` evaluates the rule for each path key independently — so `currentRound/result` IS checked and the client write is denied. The Cloud Function uses Admin SDK which bypasses all rules.

---

## Modified File: `app/lib/features/gameplay/data/gameplay_service.dart`

**Removed** from `_lockRound()`:

```dart
// BEFORE:
await _sessionRepo.computeAndSetResult(roomId);

// AFTER: line removed. Cloud Function resolveRound takes over.
```

`_lockRound()` now only writes `vote_locked`. The existing `watchGameplay()` stream listener already handles `result_ready` detection (it cancels the timer when phase leaves `voting`) — no additional client changes needed.

The reveal UI in `GameplayScreen` observes `roundStreamProvider`, which delivers the Cloud-Function-written `result_ready` identically to the old client-written one. Zero UI changes.

---

## Modified File: `app/lib/features/gameplay/data/game_session_repository.dart`

`computeAndSetResult()` marked with deprecation comment. No callers remain. Kept for reference and local-testing fallback. The RTDB rule will block it in production once rules are deployed.

---

## Data Flow After Mission 10

```
All eligible players vote (or 30s timeout elapses)
  → GameplayService._lockRound() [host client]
    → Guard: _isLockingRound, _lockedRoundId
    → writes currentRound/phase = 'vote_locked'   [RoundLocked]

Firebase RTDB trigger fires resolveRound [Cloud Function]
  → change.after.val() === 'vote_locked'           [ResultComputationStarted]
  → Duplicate guard: currentRound/result exists? → return null [DuplicateResolutionIgnored]
  → Read currentRound/votes + eligiblePlayerIds
  → Apply tie / insufficient-votes / normal logic  [ResultComputed]
  → update({ result, phase: 'result_ready' })      [ResultReady]

All clients observe round stream → phase: result_ready
  → GameplayScreen renders reveal UI (unchanged)
  → Host sees "Next Round" / "End Session" buttons
```

---

## Vote Privacy Status (Known MVP Limitation)

Votes at `currentRound/votes/{voterId}` are readable by all authenticated clients. The RTDB rule `auth.uid == $voterId` protects individual write paths but not reads.

Full vote privacy requires:

1. Write votes to a private path (e.g. `/private_votes/{roomId}/{roundId}/{voterId}`) that only the voter can write and no client can read
2. Cloud Function reads the private path, computes result, then deletes the private votes
3. Public `currentRound/votes` node removed entirely

This is a Breaking Change to the vote submission path in `GameSessionRepository.submitVote()` and is deferred to a future mission.

---

## Deployment Requirements

A `firebase.json` file must exist at the project root before `firebase deploy` can run. Minimum:

```json
{
  "database": { "rules": "database.rules.json" },
  "functions": [{ "source": "functions", "codebase": "default" }]
}
```

**Required deployment order (critical):**

1. `cd functions && npm run build` — verify TypeScript compiles
2. `firebase deploy --only functions` — deploy `resolveRound`
3. Test: complete a round → verify function logs show `ResultReady`
4. `firebase deploy --only database` — deploy hardened RTDB rules
5. Deploy updated Flutter client (removes `computeAndSetResult` call)

Deploying rules before the function creates a window where no result is ever written (games stall at `vote_locked`).

---

## Acceptance Criteria

- All players vote → Cloud Function writes `result_ready` → reveal UI renders (Scenario 3 & 4)
- Timeout fires → host writes `vote_locked` → Cloud Function computes and writes `result_ready`
- Fewer than 3 votes → `resultType: insufficient_votes`, no winners (Scenario 5)
- Two players tied → `resultType: tie`, both in `winningPlayerIds` (Scenario 6)
- Double-trigger (two `vote_locked` writes) → second function execution skips (Scenario 2)
- Direct client write to `currentRound/result` via Firebase console → denied (Scenario 1)
- Non-host client write to `rooms/{roomId}/status` → denied
- Client write to `currentRound/votes/{otherPlayerId}` → denied
- Knowledge Center reflects hardened authority model (Scenario 7)

---

## Remaining Limitations After Mission 10

| Limitation | Why Remains | Future Mission |
|---|---|---|
| Host client owns `vote_locked` timing | Server-side timer requires Cloud Scheduler or per-vote CF — out of scope | Future mission |
| Votes readable by all clients | Requires private write node + Breaking Change to vote submission | Future mission |
| `startGame` / `nextRound` / `endSession` are host-client writes | Scope limited to result hardening | Future mission |
| `firebase.json` not yet committed | Outside implementation scope | Before first deploy |

# Firebase Structural Direction

## RTDB Security Rules Summary (Mission 10)

Corrected rules deployed from `database.rules.json`. Key protections:

| Path | Rule | Reason |
|---|---|---|
| `rooms/$roomId` | read: `auth != null`, write: `auth != null` | Broad authenticated access (MVP) |
| `rooms/$roomId/status` | write: `auth.uid == hostId` | Host-only lifecycle transitions |
| `rooms/$roomId/hostId` | write: first-write or current host | Prevents host hijack |
| `rooms/$roomId/currentRound/result` | write: `false` | **System-only** — Cloud Function owns result |
| `rooms/$roomId/currentRound/votes/$voterId` | write: `auth.uid == $voterId` | Each player votes once for themselves |
| `rooms/$roomId/players/$playerId` | write: `auth.uid == $playerId` | Own presence only |
| `room_codes/$code` | read + write: `auth != null` | Join code index (needed for room lookup) |

**Previous rule path mismatches (now corrected):** The old rules protected `rooms/$roomId/roundState` and `rooms/$roomId/results` — paths that do not exist in the actual schema. These have been replaced with the correct paths `currentRound` and `currentRound/result`.

---

## Realtime Database (Live Session State)
RTDB is strictly used for high-velocity, ephemeral live session changes. It minimizes read latency and supports rapid player presence tracking.

### Node: `/rooms/{roomId}`
Represents an active game staging area or ongoing session.

- `roomId` (string)
- `joinCode` (string)
- `hostId` (string)
- `status` (string) — `lobby`, `gameplay`, or `ended`.  **Write protected:** host client only (RTDB rule).
- `createdAt` (timestamp)
- `players/{playerId}` (object)
  - `displayName` (string)
  - `avatarId` (string)
  - `isHost` (boolean)
  - `isPresent` (boolean) — Managed by `PresenceService` / `onDisconnect`.
  - `joinedAt` (timestamp)

- `session` (object)
  - `sessionId` (string)
  - `packId` (string)
  - `usedQuestionIds` (array of strings)
  - `startedAt` (timestamp)

- `currentRound` (object)
  - `roundId` (string)
  - `phase` (string) — `preparing`, `voting`, `vote_locked`, `result_ready`.
  - `questionId` (string)
  - `questionAr` (string)
  - `questionEn` (string)
  - `startedAt` (timestamp)
  - `expiresAt` (timestamp)
  - `eligiblePlayerIds` (array of strings)
  - `votes` (map: `{voterId: targetId}`)
  - `result` (object)
    - `winningPlayerIds` (array of strings)
    - `voteCounts` (map: `{playerId: count}`)
    - `resultType` (string) — `normal`, `tie`, `insufficient_votes`.
    - `totalValidVotes` (number)
    - `computedAt` (timestamp)

- `reactions/{id}` (object)
  - `playerId` (string)
  - `emoji` (string)
  - `timestamp` (timestamp)

- `roundHistory/{roundId}` (object) — **Mission 7**
  - `roundId` (string)
  - `questionId` (string)
  - `questionAr` (string)
  - `questionEn` (string)
  - `resultType` (string) — `normal`, `tie`, `insufficient_votes`
  - `winningPlayerIds` (array of strings)
  - `voteCounts` (map: `{playerId: count}`)
  - `totalValidVotes` (number)
  - `completedAt` (timestamp)
  - **Written by:** `GameSessionController._archiveRound` before `currentRound` is overwritten
  - **Read by (Mission 8):** `SessionSummaryBuilder.build(roomId, db)` — one-shot read of the full room node after session ends; used to build `SessionSummary` for `SessionSummaryScreen`.
  - **Lifecycle:** Ephemeral (lives with the room). Room node is NOT deleted on session end so the summary screen can read it. Cleanup deferred to a future Cloud Function / TTL policy. Move to Firestore for persistent cross-session history (Mission 9+).

### Node: `/room_codes/{joinCode}`
Mapping of short alphanumeric codes to full `roomId` for entry.

- `{joinCode}`: string (value is `roomId`)

## Firestore (Persistent Data)
Firestore is strictly used for static assets, player profiles, and queryable archival data.

### Collection: `questionPacks` — Mission 9

Document ID is the `packId` referenced by `GameSession.packId`.

- `name` (string) — display name, e.g. "أصدقاء" (ordered by this field in queries)
- `description` (string) — short pack description
- `language` (string) — `ar` | `en` | `mixed`
- `questionCount` (number) — pre-computed total questions in this pack
- `icon` (string) — emoji icon, e.g. `🐺`
- `isPremium` (boolean) — premium gate (not enforced in Mission 9; reserved for future monetization)
- `createdAt` (timestamp)

**Read by:** `QuestionPackRepository.fetchAllPacks()` — ordered by `name`, one-shot Firestore read on lobby mount.

### Collection: `questions` — Mission 13

Document ID convention: `q_{packId}_{NNN}` (e.g. `q_friends_001`, `q_majlis_042`).

- `packId` (string) — foreign key matching a `questionPacks` document ID
- `textAr` (string) — Arabic question text (required, non-empty)
- `textEn` (string) — English question text (`''` for Arabic-only questions)

No `active`, `published`, or `tags` fields for MVP. All documents in the collection are treated as active. Future missions may add `tags` for theme filtering.

**Loaded by:** `QuestionRepository.fetchRandomQuestion(packId)` — full-collection fetch by `packId`, client-side shuffle and exclusion filter using `usedQuestionIds`.

**Seeded by:** `seeds/seed_firestore.ts` — run once against the target Firebase project via `GOOGLE_APPLICATION_CREDENTIALS`. `serviceAccountKey.json` must not be committed.

**Launch content (Mission 13):**

| packId | Questions |
| --- | --- |
| `friends` | 80 |
| `embarrassing` | 60 |
| `majlis` | 70 |
| `couples` | 50 |
| Total | 260 |

### Collection: `users`
- Document ID: `uid`
- Fields: `displayName`, `avatarUrl`, `totalGamesPlayed`, `createdAt`

### Collection: `gameHistory` (Future)
- Document ID: `sessionId`
- Fields: `players` (array of IDs), `winnerId`, `timestamp`

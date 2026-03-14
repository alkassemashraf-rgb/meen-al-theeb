# Architecture: مين الذيب؟ | Meen Al Theeb

## Proposed Repository Structure
```text
/
├── app/                      # Flutter mobile application codebase
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/        # Colors, typography, borders, shadows
│   │   │   ├── routing/      # App router, navigation guards
│   │   │   ├── l10n/         # Localization, Arabic RTL strings
│   │   │   └── utils/        # Constants, helpers
│   │   ├── shared/
│   │   │   ├── components/   # Reusable UI atoms (cards, buttons, avatars)
│   │   │   └── animations/   # Shared micro-animations
│   │   ├── features/
│   │   │   ├── room/
│   │   │   │   └── data/         # e.g., room_repository.dart
│   │   │   ├── gameplay/
│   │   │   │   └── data/         # e.g., question_repository.dart, game_session_repository.dart
│   │   │   └── results/      # Share cards, reaction display
│   │   ├── services/         # Cross-cutting infrastructure (Firebase setup, Auth clients)
│   │   │   ├── firebase/     # Core configuration
│   │   │   ├── auth/         # Anonymous authentication
│   │   │   └── analytics/    # Tracking (stubbed)
│   │   └── main.dart         # Entry point, ProviderScope setup
│   └── pubspec.yaml
├── firebase/                 # Firebase configuration & backend
│   ├── functions/            # Cloud Functions (state validation, reveal logic)
│   ├── firestore.rules       # Security rules for collections
│   └── database.rules.json   # Security rules for RTDB rooms
└── docs/                     # Documentation
    └── knowledge-center/     # Project intelligence & mission logs
```

## Flutter Architecture Recommendation
- **State Management:** Riverpod (strictly locked) for reactive state injection and precise widget rebuilding based on Firebase streams.
- **Folder Structure:** Feature-first modularity (`features/`, `core/`, `shared/`, `services/`) to keep UI, application, and data layers isolated per domain.
- **UI / Theme Tokens:** A rigid `core/theme` layer managing color palette (`#6C5CE7`, `#00CEC9`, etc.), typography (Cairo Rounded/Poppins), gradients, and defined animation durations (0.2s - 0.5s).
- **Component Reusability:** Strict `shared/components` for the rounded cards, large touch targets, emoji pops, and avatars to enforce the playful identity.
- **Localization:** Standard Flutter `intl` supporting an Arabic-first Right-To-Left (RTL) interface by default.

## Multiplayer Authority Model (Updated Mission 10)

| Operation | Owner | Protected by |
|---|---|---|
| Submit own vote | Any client | RTDB rule: `auth.uid == $voterId` |
| Write `vote_locked` | Host client (MVP) | None — documented temporary |
| Compute result | **Cloud Function** `resolveRound` | RTDB rule: `currentRound/result.write: false` |
| Write `result_ready` | **Cloud Function** `resolveRound` | RTDB rule: `currentRound/result.write: false` |
| Write `status` | Host client only | RTDB rule: `auth.uid == hostId` |
| `startGame` / `nextRound` / `endSession` | Host client | None — MVP |
| Archive round | Host client | None — MVP |

**Remaining MVP limitations:**
- Host client still controls the `vote_locked` timing (vote-complete detection + 30-second timeout). Migrating this to a server-side timer is a future mission.
- Votes are readable by all clients at `currentRound/votes/{voterId}`. Full privacy requires a private write node — deferred to a future mission.
- `nextRound()`, `startGame()`, and `endSession()` are host-client writes. These are out of scope for Mission 10.

## Gameplay Loop Refinements (Missions 6 & 10)
- **Standardized Phases:** `preparing` ➔ `voting` ➔ `vote_locked` ➔ `result_ready`.
- **Result Computation (Mission 10 — Cloud Function):**
  - **Trigger:** Host client writes `vote_locked` → RTDB trigger fires `resolveRound` Cloud Function.
  - **Ownership:** Cloud Function (`functions/src/round_resolution.ts`) — Admin SDK, bypasses RTDB rules.
  - **Duplicate guard:** Function checks `currentRound/result` existence before computing; skips if already written.
  - **Tie-Handling:** Multiple players with the same max vote count → `resultType: tie`.
  - **Invalid Rounds:** Fewer than 3 votes → `resultType: insufficient_votes`.
- **Ephemeral Reactions:**
  - **Broadcast:** Real-time emoji broadcasting via the `/reactions` node in RTDB.
  - **Lifecycle:** Reactions are ephemeral UI events. Only available after `result_ready`.
- **Vote Privacy (Known Limitation):** Raw votes readable by all clients at `currentRound/votes`. Future mission will move votes to a private node.

## Session Orchestration Layer (Mission 7)

### GameSessionController
`features/gameplay/data/game_session_controller.dart`

A Riverpod `StateNotifier` responsible for high-level session progression.
It sits above `GameplayService` (which owns low-level round monitoring) and
above `GameSessionRepository` (which owns RTDB reads/writes).

**Responsibilities:**
- `advanceToNextRound(completedRound)` — archives round + calls `nextRound` with duplicate guard
- `endSession()` — stops monitoring, sets room status to 'ended'
- `buildResultCard(round, players)` — builds `ResultCardPayload` synchronously

**Duplicate guard:** `isTransitioningRound` flag prevents concurrent or
double-tap execution of the next-round transition. Also guards by checking
`round.phase == 'result_ready'` before proceeding.

**State:** `GameSessionControllerState` { `isTransitioningRound`, `isEndingSession`, `errorMessage` }

**Provider:** `gameSessionControllerProvider` (`.family<..., String>` scoped by roomId)

### Separation of concerns (Mission 7)
| Layer | Owner | Owns |
|---|---|---|
| RTDB reads/writes | `GameSessionRepository` | startGame, nextRound, submitVote, archiveRound, endSession |
| Vote monitoring & timeout | `GameplayService` | watchGameplay, _lockRound, _scheduleTimeout |
| Session orchestration | `GameSessionController` | round progression, archiving, result card, session end |
| UI & streams | `GameplayScreen` | rendering, user actions, navigation |

### GameplayService Reliability (Mission 7)
- `_isLockingRound`: prevents concurrent `_lockRound` execution from both vote-complete and timeout paths
- `_lockedRoundId`: prevents re-locking the same round from stale stream events
- `_timedRoundId`: prevents the 30-second countdown from being reset on each vote (only scheduled once per roundId)
- `stopWatching()` now fully resets all guards and nulls subscriptions

### Round History
- Stored at RTDB `/rooms/{roomId}/roundHistory/{roundId}`
- Written by `GameSessionController._archiveRound` before `nextRound` overwrites `currentRound`
- Model: `RoundHistoryItem`

### Session End (MVP Decision)
For MVP, ending a session also ends the room (`status: 'ended'`).
The join code is removed from `/room_codes/`. All clients observing the room
stream navigate to home when status becomes 'ended'.
See `decision-log.md` for rationale.

### Result Card & Sharing Foundation
- `ResultCardPayload`: client-side DTO with player info, question, result type
- `ResultCardWidget`: in-app rendering foundation (bottom sheet)
- Share export: stubbed with `_onShareRequested` (Mission 8+)

## Share Export & Session Summary (Mission 8)

### SessionSummaryScreen
`features/gameplay/presentation/session_summary_screen.dart`

End-of-session screen shown to all players when `room.status == 'ended'`.

**Data source:** One-shot RTDB read via `sessionSummaryProvider(roomId)`
(`FutureProvider.family`). Reads `/rooms/{roomId}/players` and
`/rooms/{roomId}/roundHistory` in one network call.

**Layout:** Stats bar (total / tie / skipped rounds), most-voted player
highlight card, chronological list of `RoundRecap` items, sticky "Home" button.

**Navigation:** Replaces the previous `context.go('/home')` on session end.
After viewing summary, players tap "الصفحة الرئيسية" to navigate to `/home`.

**Route:** `/summary/:roomId`

### SessionSummaryBuilder
`features/gameplay/data/session_summary_builder.dart`

Static utility that reads the room node once, parses `roundHistory` and
`players`, and returns a `SessionSummary`. Exposed via `sessionSummaryProvider`.

Aggregation logic: cumulative vote totals per player, most-voted player,
skipped-round count, tie-round count.

### ShareService
`services/share/share_service.dart`

Static utility for widget-to-image export and native sharing. No Riverpod.

- **Capture:** `RenderRepaintBoundary.toImage(pixelRatio: 3.0)` — no extra package.
- **Storage:** PNG saved to temp dir via `path_provider`.
- **Share:** `Share.shareXFiles(...)` via `share_plus`.
- **Entry point:** `ResultCardWidget._onShareRequested` calls `ShareService.shareWidget`.

### ResultCardWidget (Mission 8 changes)
- Converted from `StatelessWidget` → `StatefulWidget`
- `_repaintBoundaryKey`: `GlobalKey` held in state
- `_isSharing`: bool to prevent concurrent share taps
- Card content wrapped in `RepaintBoundary(key: _repaintBoundaryKey)`
- Share button shows `CircularProgressIndicator` while `_isSharing`

## Question Pack System (Mission 9)

### QuestionPackRepository
`features/gameplay/data/question_pack_repository.dart`

Firestore-backed repository responsible for fetching all available question packs.

**Method:**
- `fetchAllPacks()` — reads `questionPacks` collection ordered by `name`, maps docs to `List<QuestionPack>`

**Providers:**
- `questionPackRepositoryProvider` — `Provider<QuestionPackRepository>`
- `allPacksProvider` — `FutureProvider<List<QuestionPack>>` — cached pack list; consumed by `_PackPicker` in `LobbyScreen`
- `selectedPackProvider` — `StateProvider.family<String?, String>` scoped by `roomId` — holds the host's chosen `packId`; `null` means fall back to `getDefaultPackId()`

### Pack Selection in LobbyScreen (Mission 9)

Pack selection is integrated directly into `LobbyScreen` (host-only, above the Start button).

**Host view:** `_PackPicker` renders a horizontal `ListView` of `_PackCard` widgets (icon + name + question count). Tapping a card sets `selectedPackProvider(roomId)`.

**Non-host view:** Static text `"المضيف يختار مجموعة الأسئلة"`.

**On game start:** `_onStartGame` reads `selectedPackProvider(roomId)` and passes `packId` to `GameSessionRepository.startGame(roomId, packId: packId)`. If `null`, `startGame` falls back to `getDefaultPackId()` (first Firestore pack).

### Separation of concerns (Mission 9)

| Layer | Owner | Owns |
|---|---|---|
| Firestore pack reads | `QuestionPackRepository` | `fetchAllPacks()` |
| Pack selection state | `selectedPackProvider` | Host's chosen packId in lobby |
| Pack → session binding | `GameSessionRepository.startGame()` | Writes `packId` into `GameSession` |
| Question fetching per round | `QuestionRepository.fetchRandomQuestion()` | Deduplication via `usedQuestionIds` |
| Pack exhaustion | `GameSessionRepository.nextRound()` | `null` question → `room.status = 'ended'` |

## Session Stability Assessment (Mission 12)

Full lifecycle trace of all multiplayer systems under six stress scenarios. Method: static code analysis + guard tracing across all relevant files.

### Confirmed Stable (Pass)

| Scenario | Key Invariant | Guard |
|---|---|---|
| Room / Join | 8-player limit, status gate, duplicate names | `room_repository.joinRoom()` |
| Presence / Disconnect | Auto-cleanup on disconnect | `onDisconnect().set(false)` in `presence_service.dart` |
| Voting Concurrency | One lock write per round | `_isLockingRound` + `_lockedRoundId` + `_timedRoundId` in `GameplayService` |
| Voting Concurrency | One result per round | CF phase check + result existence guard in `round_resolution.ts` |
| Reactions | Cleared between rounds | `reactions: null` in `nextRound()` atomic update |
| Multi-Round | No question reuse | `usedQuestionIds` filter in `QuestionRepository` |
| Multi-Round | No data loss on round transition | Archive-before-overwrite ordering in `GameSessionController` |
| Session End | No orphaned timers/subscriptions | `stopWatching()` before `endSession()` write |

### Fixes Applied (Mission 12)

Three targeted bugs found and fixed. See `decision-log.md` and `missions/mission-12.md` for details.

| Fix | File(s) | Root Cause |
|---|---|---|
| Presence subscription leak | `presence_service.dart`, `lobby_screen.dart` | `connectedRef.onValue.listen()` subscription never cancelled across room navigations |
| Reaction field name mismatch | `gameplay_screen.dart` | Screen accessed `reaction.senderId` but `Reaction` model declares `playerId` — compile error |
| Confetti on `insufficient_votes` | `gameplay_screen.dart` | `_ConfettiBurst` rendered whenever `isReveal` is true regardless of `resultType` |

### Known MVP Limitations (No Fix — Documented)

- No in-game reconnect (by design — `status != 'lobby'` blocks mid-game re-join)
- `nextRound()` has no idempotency guard (retry risk is low in practice)
- Pack exhaustion ends session silently with no host notification
- No `FirebaseException`-specific handling (generic `Exception` catch)
- Room not found falls back to "Room Ended" view (no dedicated 404 screen)
- Reactions have no rate-limiting (ephemeral, cleared between rounds)
- `currentRound/phase` not rule-protected (host-client convention, documented in Mission 10)

## Content Seeding (Mission 13)

Launch question bank loaded from `seeds/` directory into Firestore via `seed_firestore.ts`.

### Launch Packs

| packId | Arabic Name | Icon | Questions | isPremium |
| --- | --- | --- | --- | --- |
| `friends` | أصدقاء | 👫 | 80 | false |
| `embarrassing` | محرج | 😬 | 60 | false |
| `majlis` | جلسة | 🪑 | 70 | false |
| `couples` | للأزواج | 💕 | 50 | false |
| Total | — | — | 260 | — |

### Seed Structure

```text
seeds/
  packs.json                    ← 4 pack metadata objects
  questions_friends.json        ← 80 Friends questions
  questions_embarrassing.json   ← 60 Embarrassing questions
  questions_majlis.json         ← 70 Majlis questions
  questions_couples.json        ← 50 Couples questions
  seed_firestore.ts             ← TypeScript import script (firebase-admin)
```

**Run command:**

```sh
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json npx ts-node seeds/seed_firestore.ts
```

`serviceAccountKey.json` must NOT be committed (add to `.gitignore`).

### Question Document ID Convention

`q_{packId}_{NNN}` — e.g. `q_friends_001`, `q_majlis_042`.

### Default Pack Behavior

`getDefaultPackId()` uses `.limit(1)` with no `orderBy` — returns the lexicographically first document ID. With these four IDs, the fallback order is: `couples` < `embarrassing` < `friends` < `majlis`. Default fallback is therefore `couples`. Hosts actively select packs in the lobby, so this fallback is only triggered if a session is started without a selection — acceptable for MVP.

### Content Readiness

| Pack | Questions | Status |
| --- | --- | --- |
| Friends | 80 | Launch-ready |
| Embarrassing | 60 | Launch-ready |
| Majlis Culture | 70 | Launch-ready |
| Couples | 50 | Launch-ready |
| Total | 260 | Launch-ready |

Post-launch expansion target: 150+ per pack (600+ total) for heavy-user retention.

---

## Implementation Roadmap
1. **Mission 2 (App Foundation):** Scaffold Flutter app, theme tokens, localization / RTL readiness, routing shell, and shared UI components.
2. **Mission 3 (Backend Foundation):** Setup Firebase project, auth (anonymous), and basic RTDB/Firestore schemas & security rules.
3. **Mission 4 (Lobby & Room System):** Room creation, join by code, avatar selection, and presence management.
4. **Mission 5 (Core Gameplay Loop):** Question fetching, direct anonymous voting, state synchronisation, state machine integration.
5. **Mission 6 (Reveal & Reactions):** Vote tallying, synced reveal, live emoji broadcast.
6. **Mission 7 (Session Orchestration & Share Foundation):** GameSessionController, round history, session end, result card, reliability hardening.
7. **Mission 8 (Share Export & Session Summary):** SessionSummaryScreen, aggregation, image export via RepaintBoundary, native share-sheet via share_plus.
8. **Mission 9 (Question Pack & Content Engine):** QuestionPack model, QuestionPackRepository, lobby pack picker, session pack binding.
9. **Mission 10 (Authority Hardening):** Cloud Function for result computation, RTDB rules correction.
10. **Mission 12 (Multiplayer Stress Testing):** Validation across all six scenarios, three targeted fixes.
11. **Mission 13 (Content Seeding):** 260 launch questions across 4 packs, seed script, content readiness report.
12. **Mission 14+ (Polish):** Audio, micro-animations, server-side timer, leaderboards, monetization.

# Decision Log

## Backend Architecture
- **Decision:** Use Firebase Hybrid Architecture.
- **Context:** Low latency needed for buzzers/presence; structured archiving needed for history/content.
- **Resolution:** Realtime Database strictly for live game state (`/rooms`). Firestore strictly for queryable stable data (`/questions`, `/users`).

## Authentication
- **Decision:** Anonymous Auth for MVP.
- **Context:** Party games need frictionless entry. User drop-off increases significantly with forced signup screens.
- **Resolution:** `firebase_auth` configured to invoke `signInAnonymously()` on app boot. Players can attach display names and avatars later without linking phone numbers or emails initially.

## State Management
- **Decision:** Riverpod (Locked).
- **Context:** Flutter needs predictable reactivity.
- **Resolution:** Used for UI rendering, dependency injection, and RTDB stream observation.

## Session End Also Ends Room (Mission 7)
- **Decision:** For MVP, ending the session sets room `status: 'ended'` and removes the join code — effectively ending the room.
- **Context:** Introducing a separate `session_ended` status (while keeping the room alive for a post-game lobby) adds complexity that is out of scope for Mission 7.
- **Resolution:** `GameSessionController.endSession()` → `GameSessionRepository.endSession()` sets status to `ended` and cleans up the join code index. All clients navigate away via the room stream. A distinct post-game lobby state can be introduced in a future mission.

## GameSessionController as Orchestration Layer (Mission 7)
- **Decision:** Introduce `GameSessionController` (Riverpod `StateNotifier`) as the dedicated session orchestration layer, sitting above `GameplayService` and `GameSessionRepository`.
- **Context:** The "Next Round" logic was previously a direct repository call from the UI, with no duplicate guard, no round archiving, and no clean session-end path. As session complexity grows, this needs a dedicated layer.
- **Resolution:** `GameSessionController` owns: duplicate-guard (`isTransitioningRound`), round archiving before overwrite, result card payload generation, and session end (including stopping `GameplayService`). `GameplayService` retains ownership of low-level vote monitoring and timeout scheduling.

## RoundHistory Stored in RTDB (Mission 7)
- **Decision:** `RoundHistoryItem` records are stored at RTDB `/rooms/{roomId}/roundHistory/{roundId}`, not Firestore.
- **Context:** Round history is needed immediately during a session (same lifecycle as the room). Firestore would add latency and a second write path.
- **Resolution:** Store in RTDB for MVP. If persistent cross-session history is needed for stats or leaderboards, archive to Firestore in a future mission (or via a Cloud Function on session end).

## GameplayService Reliability Guards (Mission 7)
- **Decision:** Add `_isLockingRound`, `_lockedRoundId`, and `_timedRoundId` guards to `GameplayService`.
- **Context:** The vote-complete path and the timeout path could both call `_lockRound` concurrently. Additionally, the timeout was being reset on every incoming vote (stream fires per vote), which was a bug.
- **Resolution:** `_isLockingRound` prevents concurrent execution. `_lockedRoundId` prevents re-locking a round from stale stream events. `_timedRoundId` ensures the 30-second countdown is only scheduled once per `roundId`.

## Share Export Stubbed (Mission 7) → Implemented (Mission 8)
- **Decision (M7):** `ResultCardWidget` shipped with a stub share action (SnackBar) rather than real image export. Foundation only.
- **Decision (M8):** Real share export implemented using Flutter's built-in `RepaintBoundary.toImage()` + `share_plus` + `path_provider`. No heavy screenshot package added.
- **Resolution:** `ResultCardWidget` converted to `StatefulWidget`. Card wrapped in `RepaintBoundary`. `ShareService.shareWidget()` captures PNG at 3× pixel ratio, saves to temp dir, opens native share sheet.

## share_plus and path_provider Added (Mission 8)
- **Decision:** Add exactly two lightweight packages: `share_plus` (native share sheet) and `path_provider` (temp dir for PNG file).
- **Context:** `share_plus` requires a file path or XFile for image sharing. Writing to temp dir is the standard cross-platform pattern on iOS and Android.
- **Resolution:** Both packages added to `pubspec.yaml`. No other new dependencies. No screenshot/capture package needed — Flutter's `RenderRepaintBoundary` is sufficient.

## Session Summary Reads RTDB Before Cleanup (Mission 8)
- **Decision:** `SessionSummaryScreen` reads from RTDB (`/rooms/{roomId}`) after session ends. The room node is NOT deleted immediately on session end.
- **Context:** Round history and player names are needed to build the summary screen. Deleting the room node on session end would make the summary impossible.
- **Resolution:** Room data persists in RTDB after `status: 'ended'`. Cleanup (deletion) is deferred to a future Cloud Function or TTL policy. Summary screen reads the data with a one-shot `FutureProvider`.

## Session End Navigates to Summary, Not Home (Mission 8)
- **Decision:** Changed `context.go('/home')` to `context.go('/summary/:roomId')` in `GameplayScreen`.
- **Context:** Players should see a recap of what happened in the session before returning home.
- **Resolution:** All players (host and non-host) navigate to `SessionSummaryScreen` when `room.status == 'ended'`. The summary screen has a "الصفحة الرئيسية" button to go home.

## Cloud Function Owns Result Computation (Mission 10)
- **Decision:** Move `computeAndSetResult` from host client (`GameplayService._lockRound`) to a Cloud Function (`resolveRound`) triggered by `currentRound/phase` → `vote_locked`.
- **Context:** Result computation on the host client is untrusted — any malicious client could write fabricated results or trigger computation at the wrong time. RTDB rules cannot protect `currentRound/result` without also being able to verify vote integrity.
- **Resolution:** `GameplayService._lockRound()` now only writes `vote_locked`. The Cloud Function detects this, reads votes, applies tie/insufficient-votes logic, and atomically writes `result + phase: result_ready`. The RTDB rule `currentRound/result: { .write: false }` blocks all client writes to the result node. The existing reveal UI observes `result_ready` via the round stream — no client changes required.

## Host Client Retains vote_locked Ownership (Mission 10 MVP Compromise)
- **Decision:** The host client continues to detect vote completion and timeouts, and writes `vote_locked` directly to RTDB.
- **Context:** Moving vote-complete detection and the 30-second timer to a server-side Cloud Function would require a Cloud Scheduler or RTDB-side timer — a significant scope increase. For MVP, the host client is a trusted coordinator for timing.
- **Resolution:** Documented as a known MVP limitation. A future mission will implement server-side timeout (e.g. via `expiresAt` checked by a Cloud Function scheduled trigger or a per-vote Cloud Function that detects completion).

## RTDB Rules Path Correction (Mission 10)
- **Decision:** Rewrite `database.rules.json` to match the actual RTDB schema.
- **Context:** The existing rules protected `rooms/$roomId/roundState` and `rooms/$roomId/results` — paths that do not exist in the live database. Votes were protected at `rooms/$roomId/votes/$voterId` but actual vote paths are at `rooms/$roomId/currentRound/votes/$voterId`. The `status` field had `.write: false` which would have broken `startGame()` and `endSession()` if ever deployed. No `room_codes` rule existed, which would have blocked `createRoom()`.
- **Resolution:** Rules now protect the correct paths: `currentRound/result` (system-only), `currentRound/votes/$voterId` (own-vote-only), `status` (host-only via `auth.uid == hostId`), `players/$playerId` (own-player-only), and `room_codes` (authenticated read+write).

## Deployment Order for Mission 10 (Mission 10)
- **Decision:** Cloud Function must be deployed and verified before RTDB rules are deployed.
- **Context:** If rules are deployed first (`currentRound/result.write: false`), clients lose the ability to write results. If the Cloud Function is not yet live, no result would ever be computed and games would stall at `vote_locked` forever.
- **Resolution:** Mandatory deployment order: (1) deploy function, (2) verify with a test round, (3) deploy rules, (4) deploy client update. A `firebase.json` must be created at the project root before any `firebase deploy` commands can run.
## RepaintBoundary for Per-Frame Animations (Mission 11.5)
- **Decision:** Wrap `AvatarWidget` animations (breathing/pulse), `_ConfettiBurst`, and `LoadingState` spinner in `RepaintBoundary`.
- **Context:** High-frequency animations (scale shifting or particle motion) can trigger repaints of the entire screen or parent grid, causing frame drops on low-end devices.
- **Resolution:** Isolated these components to their own painting layers. This ensures the CPU/GPU only repaints the specific animating widget, maintaining a stable 60fps.

## Timer-Based Emotion Tracking (Mission 11.5)
- **Decision:** Use a `Map<String, Timer>` to manage player emotion overlays in `GameplayScreen` instead of `Future.delayed`.
- **Context:** Rapid reactions from the same player could cause a "race condition" where the first reaction's cleanup future clears a subsequent reaction's emoji prematurely.
- **Resolution:** Each new reaction now cancels the previous timer for that player and starts a fresh 2-second countdown, ensuring consistent UI feedback and proper resource disposal.

## Presence Subscription Leak Fixed (Mission 12)
- **Decision:** Store and cancel the `.info/connected` stream subscription in `PresenceService`.
- **Context:** `trackPresence()` called `connectedRef.onValue.listen()` and discarded the returned `StreamSubscription`. Each call (from `LobbyScreen.initState`) created a new immortal listener. Under stress (repeated room navigations), listeners accumulated indefinitely with no way to release them.
- **Resolution:** Added `StreamSubscription? _connectedSub` field to `PresenceService`. `trackPresence()` now cancels `_connectedSub` before creating a new listener. Added `stopTracking()` method. `LobbyScreen.dispose()` calls `stopTracking()` to release the subscription when the screen is popped.

## Reaction Field Name Mismatch Fixed (Mission 12)
- **Decision:** Replace `reaction.senderId` with `reaction.playerId` in `GameplayScreen._startReactionListener()`.
- **Context:** The `Reaction` Freezed model declares the sender field as `playerId`. The reaction listener in `gameplay_screen.dart` was accessing `reaction.senderId` — a field that does not exist. This is a Dart compile error that prevented the reaction listener from compiling correctly.
- **Resolution:** All three occurrences of `reaction.senderId` replaced with `reaction.playerId` in `_startReactionListener()`. No model change needed — `playerId` is the correct semantic name for the player who sent the reaction.

## Confetti Guard Added for Insufficient Votes (Mission 12)
- **Decision:** Gate `_ConfettiBurst` rendering behind a result type check (`normal` or `tie` only).
- **Context:** `_ConfettiBurst` was rendered whenever `isReveal == true`, regardless of `round.result?.resultType`. On `insufficient_votes` rounds, confetti would fire even though no winner was determined — cosmetically wrong and potentially confusing to players who see a celebration animation after an inconclusive round.
- **Resolution:** The confetti `Positioned.fill` block in `GameplayScreen.build()` now checks `round.result?.resultType == 'normal' || round.result?.resultType == 'tie'` before rendering `_ConfettiBurst`.

## Multiplayer Stress Validation — Known Limitations Accepted (Mission 12)
- **Decision:** Accept the following as known MVP limitations without fixing for Mission 12.
- **Context:** Full lifecycle tracing across all six stress scenarios confirmed these gaps are real but low-impact for MVP and require larger scope changes to address.
- **Resolution (Deferred):**

| Limitation | Rationale | Future |
|---|---|---|
| No in-game reconnect | `status != 'lobby'` guard is by design. Player stays in roster with `isPresent: false`; timer ensures round completes. | Session recovery mission |
| `nextRound()` retry risk | Archive is idempotent (same `roundId` key). Controller `isTransitioningRound` prevents casual retry. | Future hardening |
| Pack exhaustion silent end | Session ends without explicit host notification. | UX feedback mission |
| No `FirebaseException` handling | Generic catch works for MVP; no behavior difference observed. | Future hardening |
| Room not found → "Room Ended" view | Semantically acceptable; no user confusion in practice. | Future dedicated 404 |
| Reactions have no rate-limit | Ephemeral and cleared between rounds. No state corruption possible. | Future rate-limiting |
| Phase transitions not rule-protected | Documented in Mission 10. Host-client convention only. | Future server-side timer |

## Question Document ID Convention (Mission 13)

- **Decision:** Use `q_{packId}_{NNN}` as the Firestore document ID for questions (e.g. `q_friends_001`).
- **Context:** A predictable, human-readable ID format makes seed files auditable, supports idempotent seeding (set overwrites same doc), and makes future manual content additions straightforward.
- **Resolution:** Convention enforced in all four seed JSON files. The seed script uses the `id` field from each JSON object as the Firestore document ID via `collection.doc(id).set(data)`.

## textEn Accepts Empty String for Arabic-Only Questions (Mission 13)

- **Decision:** Arabic-only questions use `textEn: ''` rather than introducing an optional field.
- **Context:** The `Question` Freezed model declares `textEn` as `required String` — it cannot be `null`. Changing the model to `String? textEn` would require regenerating Freezed files and updating all call sites.
- **Resolution:** `textEn: ''` is the accepted convention. All 260 launch questions use `textEn: ''`. The UI does not display `textEn` for MVP. The model requires no changes.

## Seed Script Uses firebase-admin (Mission 13)

- **Decision:** Use a standalone TypeScript script (`seeds/seed_firestore.ts`) with `firebase-admin` for content seeding, rather than a Firestore import tool or a Flutter-side seed screen.
- **Context:** `firebase-admin` bypasses Firestore security rules, supports batched writes of 500 operations each, and runs from a terminal with a service account key — no app deployment needed. The alternative (Firestore import tool) requires a different JSON format and a running emulator or export/import pipeline.
- **Resolution:** Script reads JSON seed files, writes packs to `questionPacks/{id}` and questions to `questions/{id}` in Firestore batches. Idempotent — running twice produces the same result. `serviceAccountKey.json` must not be committed (add to `.gitignore`).

## Default Pack Fallback Is `couples` (Mission 13)

- **Decision:** Accept that `getDefaultPackId()` resolves to `couples` with the four launch pack IDs and document this without a code change.
- **Context:** `getDefaultPackId()` uses `.collection('questionPacks').limit(1).get()` with no `orderBy`. Firestore returns documents in lexicographic document-ID order when no order is specified. With IDs `couples`, `embarrassing`, `friends`, `majlis`, the first document returned is `couples`.
- **Resolution:** Hosts actively select a pack via the lobby picker in all normal gameplay flows. The `getDefaultPackId()` fallback is only triggered if a session is started with `selectedPackProvider == null` (e.g. Firestore is empty or the host never interacted with the picker). `couples` as the default is semantically acceptable. No code change required.

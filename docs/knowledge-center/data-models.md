# Conceptual Data Models & Events

This document defines the backend-oriented boundaries, purpose, and storage locations for core concepts in the system.

## Data Models

#### UserProfile
- **Purpose**: Persist long-term player stats and cosmetic preferences.
- **Storage**: Firestore `/users/{uid}`
- **MVP Fields**: `uid`, `displayName`, `createdAt`

#### Room
- **Purpose**: A lobby hosting a specific session and joining code.
- **Storage**: RTDB `/rooms/{roomId}`
- **MVP Fields**: `roomId`, `joinCode`, `hostId`, `status`, `players`
- **Model Definition**:

```dart
@freezed
class Room with _$Room {
  const factory Room({
    required String roomId,
    required String joinCode,
    required String hostId,
    required String status,
    required DateTime createdAt,
    @Default({}) Map<String, RoomPlayer> players,
  }) = _Room;
}
```

#### RoomPlayer
- **Purpose**: Represents a player’s current standing in an active room.
- **Storage**: RTDB `/rooms/{roomId}/players/{playerId}`
- **MVP Fields**: `playerId`, `displayName`, `avatarId`, `isHost`, `isPresent`, `joinedAt`
- **Model Definition**:

```dart
@freezed
class RoomPlayer with _$RoomPlayer {
  const factory RoomPlayer({
    required String playerId,
    required String displayName,
    required String avatarId,
    required bool isHost,
    required bool isPresent,
    required DateTime joinedAt,
  }) = _RoomPlayer;
}
```

#### PresenceState
- **Purpose**: Ephemeral flags determining if a player is online or dropped.
- **Storage**: RTDB native `.info/connected` mapping to `RoomPlayer.isPresent`.
- **MVP Fields**: `isPresent`, `lastActiveAt`

#### GameSession
- **Purpose**: The dynamic engine state of a running game.
- **Storage**: RTDB `/rooms/{roomId}/session`
- **Fields**: `sessionId`, `packId`, `usedQuestionIds`, `startedAt`

#### GameRound
- **Purpose**: Specific state for the current active round.
- **Storage**: RTDB `/rooms/{roomId}/currentRound`
- **Fields**: `roundId`, `questionId`, `questionAr`, `questionEn`, `phase`, `startedAt`, `expiresAt`, `eligiblePlayerIds`, `votes`
- **Phases**: `preparing` ➔ `voting` ➔ `vote_locked` ➔ `result_ready`
- **Model Definition**:

```dart
@freezed
class GameRound with _$GameRound {
  const factory GameRound({
    required String roundId,
    required String questionId,
    required String questionAr,
    required String questionEn,
    required String phase, // preparing | voting | vote_locked | result_ready
    required DateTime startedAt,
    required DateTime expiresAt,
    @Default([]) List<String> eligiblePlayerIds,
    @Default({}) Map<String, String> votes, // voterId -> targetId
    RoundResult? result,
  }) = _GameRound;
}
```

#### RoundResult
- **Purpose**: Encapsulates the outcome of a game round.
- **Storage**: RTDB `/rooms/{roomId}/currentRound/result`
- **Fields**: `winningPlayerIds`, `voteCounts`, `resultType`, `totalValidVotes`, `computedAt`

#### Reaction
- **Purpose**: Ephemeral real-time feedback broadcast to all players.
- **Storage**: RTDB `/rooms/{roomId}/reactions/{id}`
- **Fields**: `id`, `playerId`, `emoji`, `timestamp`

#### QuestionPack — Mission 9
- **Purpose**: Groups thematic questions (e.g., friends, spicy, family). Selected by the host in the lobby before the session starts.
- **Storage**: Firestore `/questionPacks/{packId}`
- **Fields**: `packId`, `name`, `description`, `language`, `questionCount`, `icon`, `isPremium`, `createdAt`
- **Model Definition**:

```dart
@freezed
class QuestionPack with _$QuestionPack {
  const factory QuestionPack({
    required String packId,
    required String name,
    @Default('') String description,
    @Default('ar') String language,     // ar | en | mixed
    @Default(0) int questionCount,      // pre-computed in Firestore
    @Default('🐺') String icon,
    @Default(false) bool isPremium,
    DateTime? createdAt,
  }) = _QuestionPack;

  factory QuestionPack.fromJson(Map<String, dynamic> json) =>
      _$QuestionPackFromJson(json);
}
```

#### Question — Mission 13

- **Purpose**: The localized text string for the prompt. Loaded per-round by `QuestionRepository.fetchRandomQuestion()`.
- **Storage**: Firestore `/questions/{questionId}`
- **Document ID convention**: `q_{packId}_{NNN}` (e.g. `q_friends_001`)
- **Fields**: `id`, `packId`, `textAr`, `textEn`
- **Note**: `textEn` is required by the Dart model but accepts `''` for Arabic-only questions. No `active` or `tags` field for MVP — all documents in the collection are treated as active.

#### RoundHistoryItem — Mission 7
- **Purpose**: Archived summary of a completed round. Supports session history, future sharing, and summary screens.
- **Storage**: RTDB `/rooms/{roomId}/roundHistory/{roundId}` (ephemeral with room; move to Firestore for persistence in Mission 8+)
- **Written by**: `GameSessionController._archiveRound` before `nextRound` overwrites `currentRound`
- **Fields**: `roundId`, `questionId`, `questionAr`, `questionEn`, `resultType`, `winningPlayerIds`, `voteCounts`, `totalValidVotes`, `completedAt`

```dart
@freezed
class RoundHistoryItem with _$RoundHistoryItem {
  const factory RoundHistoryItem({
    required String roundId,
    required String questionId,
    required String questionAr,
    required String questionEn,
    required String resultType,      // normal | tie | insufficient_votes
    @Default([]) List<String> winningPlayerIds,
    @Default({}) Map<String, int> voteCounts,
    required int totalValidVotes,
    required DateTime completedAt,
  }) = _RoundHistoryItem;
}
```

#### ResultCardPayload — Mission 7
- **Purpose**: Client-side DTO for rendering or exporting a round result card. Bundles all data needed for `ResultCardWidget` or a future share/export pipeline.
- **Storage**: Not persisted. Generated on demand from a completed `GameRound` + player roster. Discarded after use.
- **Built by**: `GameSessionController.buildResultCard(round, players)`
- **Fields**: `roomId`, `roundId`, `questionAr`, `questionEn`, `resultType`, `players` (list of `ResultCardPlayerInfo`), `generatedAt`

#### ResultCardPlayerInfo — Mission 7
- **Purpose**: Per-player context embedded in `ResultCardPayload`.
- **Fields**: `playerId`, `displayName`, `avatarId`, `voteCount`, `isWinner`

#### GameSessionControllerState — Mission 7
- **Purpose**: Transient UI/orchestration state for the current session. Not stored in Firebase.
- **Fields**: `isTransitioningRound` (bool), `isEndingSession` (bool), `errorMessage` (String?)

#### GameHistory
- **Purpose**: Archival log of past sessions for stats.
- **Storage**: Firestore `/gameHistory/{gameId}`
- **MVP Fields**: `timestamp`, `players`, `winnerId`

---

## APIs & Events

#### FirebaseInitialized
- **Trigger**: App startup (`main.dart`).
- **Validation**: Flutter checks initialization success before rendering root.
- **Ownership**: Client (Flutter).

#### AnonymousAuthCompleted
- **Trigger**: Starting the app or entering the Lobby natively.
- **Validation**: Firebase Auth service creates/restores a persistent UID.
- **Ownership**: Client (Flutter).

#### RoomStateObserved
- **Trigger**: Player entering the Lobby or Room screen.
- **Validation**: Firebase Security Rules verify auth status.
- **Ownership**: RTDB listener (Flutter Riverpod `StreamProvider`).

#### QuestionPackFetched
- **Trigger**: Creating a new room / host settings.
- **Validation**: Firestore rules verify read-only access.
- **Ownership**: Client repository -> Firestore.

#### PresenceUpdated
- **Trigger**: App goes background/foreground or disconnects.
- **Validation**: RTDB native `onDisconnect` triggers safely.
- **Ownership**: RTDB managed automatically from Client.

#### ProtectedStateWriteAttempted
- **Trigger**: Moving to next phase or locking a vote.
- **Validation**: Security Rules mapping -> ultimately handled by Cloud Functions validating phase.
- **Ownership**: Server (Cloud Functions / RTDB rules).

#### RoundLockRequested — Mission 10
- **Trigger**: `GameplayService._checkVotingProgress()` detects all eligible players voted, OR `_scheduleTimeout()` fires after 30 seconds.
- **Validation**: `_isLockingRound` + `_lockedRoundId` guards in `GameplayService` prevent concurrent or duplicate lock attempts.
- **Ownership**: Host client (MVP — vote-complete detection and timeout scheduling remain host-side).
- **Resulting state**: Calls `_lockRound()`.

#### RoundLocked — Mission 10
- **Trigger**: `GameplayService._lockRound()` succeeds in writing `phase: vote_locked`.
- **Validation**: RTDB write; no rule blocks the `currentRound/phase` write (host has room-level write).
- **Ownership**: Host client (MVP).
- **Resulting state**: `currentRound/phase == 'vote_locked'` in RTDB. Triggers `resolveRound` Cloud Function via RTDB listener.

#### ResultComputationStarted — Mission 10
- **Trigger**: `resolveRound` Cloud Function fires on `currentRound/phase` write → `vote_locked`.
- **Validation**: Duplicate guard — function reads `currentRound/result`; returns immediately if already written (`DuplicateResolutionIgnored`).
- **Ownership**: **Cloud Function** (Admin SDK — bypasses RTDB rules).
- **Resulting state**: Function reads `eligiblePlayerIds` + `votes`, begins computation.

#### ResultComputed — Mission 10
- **Trigger**: Vote tally completed inside `resolveRound`.
- **Validation**: Tie rule (multiple max-vote players → `tie`); insufficient-votes rule (< 3 total → `insufficient_votes`).
- **Ownership**: **Cloud Function**.
- **Resulting state**: `RoundResult` object ready in memory; not yet written.

#### DuplicateResolutionIgnored — Mission 10
- **Trigger**: `resolveRound` fires but `currentRound/result` already exists (retry, concurrent trigger, or re-write of `vote_locked`).
- **Validation**: `resultSnap.exists()` check at function entry.
- **Ownership**: **Cloud Function**.
- **Resulting state**: Function logs and returns `null`. No state change.

#### ResultReady — Mission 10
- **Trigger**: `resolveRound` writes `currentRound/result` + `currentRound/phase: result_ready` atomically.
- **Validation**: RTDB rule `currentRound/result.write: false` blocks any concurrent client write attempt. Admin SDK bypasses this.
- **Ownership**: **Cloud Function**.
- **Resulting state**: All clients observing `roundStreamProvider` receive `phase == result_ready`; `GameplayScreen` renders reveal UI.

#### ReactionSent
- **Trigger**: Player taps an emoji in the Reveal phase.
- **Validation**: Client-side throttle; Only allowed in `result_ready`.
- **Ownership**: Client ➔ RTDB.

#### NextRoundRequested — Mission 7
- **Trigger**: Host taps "الجولة التالية" in the reveal phase.
- **Validation**: `GameSessionController` — checks `isTransitioningRound` guard and `phase == result_ready`.
- **Resulting state**: Sets `isTransitioningRound = true`, triggers `RoundArchived` then `NextRoundPrepared`.

#### RoundArchived — Mission 7
- **Trigger**: Within `advanceToNextRound`, before `nextRound` is called.
- **Validation**: `GameSessionController._archiveRound` — skips if `round.result == null`.
- **Resulting state**: Writes `RoundHistoryItem` to RTDB `/rooms/{roomId}/roundHistory/{roundId}`.

#### NextRoundPrepared — Mission 7
- **Trigger**: `GameSessionRepository.nextRound` completes successfully.
- **Validation**: Phase guard in repository (exits early if question pack exhausted → ends session).
- **Resulting state**: New `currentRound` node in RTDB with `phase: preparing` → `phase: voting`; `reactions` cleared; `usedQuestionIds` updated.

#### SessionEnded — Mission 7
- **Trigger**: Host taps "إنهاء الجلسة" and confirms the dialog.
- **Validation**: `GameSessionController` — checks `isEndingSession` guard.
- **Resulting state**: `GameplayService.stopWatching()` called; room `status` set to `ended`; join code removed from `/room_codes/`; all clients navigate to home.

#### ResultCardPrepared — Mission 7
- **Trigger**: Host taps "عرض بطاقة النتيجة" in the reveal phase.
- **Validation**: `GameSessionController.buildResultCard` — returns null if result not computed.
- **Resulting state**: `ResultCardPayload` built in memory; `showResultCardSheet` opens bottom sheet.

#### ShareRequested — Mission 8
- **Trigger**: User taps "مشاركة النتيجة" inside `ResultCardWidget`.
- **Validation**: `_isSharing` guard prevents concurrent execution.
- **Resulting state**: `ShareService.shareWidget()` captures PNG and opens native share sheet.

#### SessionSummaryBuilt — Mission 8
- **Trigger**: `sessionSummaryProvider(roomId)` FutureProvider completes after one-shot RTDB read.
- **Validation**: `SessionSummaryBuilder.build` — returns null if room node missing; skips malformed history entries.
- **Resulting state**: `SessionSummary` available in `SessionSummaryScreen`.

#### ShareImageGenerated — Mission 8
- **Trigger**: `RenderRepaintBoundary.toImage()` completes inside `ShareService.shareWidget`.
- **Validation**: Boundary must be in widget tree; PNG encoding must succeed.
- **Resulting state**: PNG bytes in memory, written to temp dir via `path_provider`.

#### SessionCleanupComplete — Mission 8
- **Trigger**: `GameplayScreen.dispose()` is called when navigating to `/summary/:roomId`.
- **Validation**: Automatic (Flutter lifecycle).
- **Resulting state**: `GameplayService.stopWatching()` clears subscription, timer, and all guards.

#### PacksLoaded — Mission 9
- **Trigger**: `allPacksProvider` FutureProvider completes on `LobbyScreen` mount.
- **Validation**: `QuestionPackRepository.fetchAllPacks()` — returns empty list if Firestore collection empty; graceful silent error.
- **Resulting state**: `_PackPicker` renders horizontal list of `_PackCard` widgets for host to select from.

#### PackSelected — Mission 9
- **Trigger**: Host taps a `_PackCard` in the lobby picker.
- **Validation**: None (any pack card tap is valid).
- **Resulting state**: `selectedPackProvider(roomId)` updated to the tapped `packId`.

#### QuestionFetched — Mission 13

- **Trigger**: `GameSessionRepository.nextRound()` calls `QuestionRepository.fetchRandomQuestion(packId)`.
- **Validation**: Full-collection fetch filtered client-side by `usedQuestionIds`; shuffled before selection.
- **Resulting state**: Non-duplicate question written into new `currentRound`; `usedQuestionIds` extended with the selected `questionId`.

#### PackExhausted — Mission 13

- **Trigger**: `QuestionRepository.fetchRandomQuestion()` returns `null` (all questions already used).
- **Validation**: `nextRound()` checks for `null` question before writing new round.
- **Resulting state**: `nextRound()` writes `room.status = 'ended'` instead of preparing a new round. All clients navigate to `/summary/:roomId` via the room stream.

#### SessionEndedByExhaustion — Mission 13

- **Trigger**: `nextRound()` status write (`ended`) triggers the room stream on all clients.
- **Validation**: Same `status == 'ended'` path as host-triggered session end.
- **Resulting state**: All clients navigate to `SessionSummaryScreen`. No explicit host notification (known UX limitation — deferred).

---

## Mission 8 Models

#### RoundRecap — Mission 8
- **Purpose**: Lightweight display model for one completed round, built by `SessionSummaryBuilder`. Not persisted.
- **Fields**: `roundNumber`, `roundId`, `questionAr`, `resultType`, `winnerDisplayNames`, `voteCounts`, `totalValidVotes`

#### SessionSummary — Mission 8
- **Purpose**: Aggregated session-level summary for `SessionSummaryScreen`. Not persisted.
- **Built by**: `SessionSummaryBuilder.build(roomId, db)` — one-shot RTDB read.
- **Fields**: `rounds`, `totalVotesReceived`, `playerDisplayNames`, `totalRounds`, `skippedRounds`, `tieRounds`, `mostVotedPlayerId`, `mostVotedCount`

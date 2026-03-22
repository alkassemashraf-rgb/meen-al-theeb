import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_filters.dart';
import '../domain/game_round.dart';
import '../domain/game_session.dart';
import '../domain/question_enums.dart';
import '../domain/round_history_item.dart';
import '../domain/round_result.dart';
import '../../room/domain/room.dart';
import 'gameplay_analytics.dart';
import 'question_repository.dart';
import 'session_question_engine.dart';

final gameSessionRepositoryProvider = Provider<GameSessionRepository>((ref) {
  return GameSessionRepository(
    FirebaseDatabase.instance,
    ref.read(questionRepositoryProvider),
    ref.read(sessionQuestionEngineProvider),
  );
});

class GameSessionRepository {
  final FirebaseDatabase _db;
  final QuestionRepository _questionRepo;
  final SessionQuestionEngine _engine;

  GameSessionRepository(this._db, this._questionRepo, this._engine);

  Map<String, dynamic> _deepConvert(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v is Map ? _deepConvert(v) : v));
    }
    return {};
  }

  /// Firebase RTDB omits empty arrays. Fill required list/map fields with
  /// their default values before handing JSON to generated fromJson code.
  void _normalizeRoundJson(Map<String, dynamic> json) {
    json['eligiblePlayerIds'] ??= <dynamic>[];
    json['votes'] ??= <String, dynamic>{};
    json['questionEn'] ??= json['questionAr'] ?? '';
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      result['winningPlayerIds'] ??= <dynamic>[];
      result['voteCounts'] ??= <String, dynamic>{};
    }
  }

  /// Public accessor to the room node. Used by [GameplayService] and
  /// [GameSessionController] for targeted field writes.
  DatabaseReference roomRef(String roomId) => _db.ref('rooms/$roomId');

  // -------------------------------------------------------------------------
  // Room Memory (Mission 13.3 — Anti-Repetition)
  // -------------------------------------------------------------------------

  /// Reads recently used question IDs from this room's memory.
  /// Returns [] on first session or when the field is absent.
  Future<List<String>> _fetchRecentQuestions(String roomId) async {
    final snap = await _db.ref('rooms/$roomId/recentQuestions').get();
    if (!snap.exists || snap.value == null) return [];
    final raw = snap.value;
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  /// Appends [newIds] to the room's recent question list and trims to
  /// [maxSize] most-recent entries so the list stays lightweight.
  Future<void> _updateRecentQuestions(
    String roomId,
    List<String> newIds, {
    int maxSize = 50,
  }) async {
    if (newIds.isEmpty) return;
    final existing = await _fetchRecentQuestions(roomId);
    final merged = [...existing, ...newIds];
    final trimmed = merged.length > maxSize
        ? merged.sublist(merged.length - maxSize)
        : merged;
    await _db.ref('rooms/$roomId/recentQuestions').set(trimmed);
    debugPrint('[Repo] recentQuestions: ${trimmed.length} entries '
        '(+${newIds.length} new, roomId=$roomId)');
  }

  /// Reads the current session's full question queue from RTDB and saves
  /// all IDs to room memory. Called before session state is cleared or ended.
  ///
  /// Uses session/sessionQueue (the full prepared set) rather than
  /// usedQuestionIds (partial — only rounds already played), so the entire
  /// pool consumed by a session is marked as recently seen.
  Future<void> _saveSessionToRecentQuestions(String roomId) async {
    final snap =
        await _db.ref('rooms/$roomId/session/sessionQueue').get();
    if (!snap.exists || snap.value == null) return;
    final raw = snap.value;
    if (raw is! List) return;
    final ids = raw
        .whereType<Map>()
        .map((m) => m['id'])
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return;
    await _updateRecentQuestions(roomId, ids);
  }

  // -------------------------------------------------------------------------
  // Session Lifecycle
  // -------------------------------------------------------------------------

  /// Starts a new game session. Generates the full session question queue,
  /// stores it in RTDB, transitions room from lobby to gameplay, then fires
  /// the first round.
  ///
  /// [packIds]        multiselect pack IDs chosen by the host.
  /// [maxRounds]      session round cap; nextRound ends session when reached.
  /// [intensityLevel] host-selected content intensity (Mission 5).
  ///                  Defaults to [IntensityLevel.medium].
  /// [ageMode]        host-selected age mode (Mission 5).
  ///                  Defaults to [RoomAgeMode.standard].
  ///
  /// Throws [InsufficientQuestionsException] (from [SessionQuestionEngine]) if
  /// the eligible question pool is smaller than [maxRounds]. The caller
  /// (LobbyScreen) catches this type and shows a bilingual error snackbar.
  ///
  /// Event: SessionStarted
  Future<void> startGame(
    String roomId, {
    String? packId,
    List<String>? packIds,
    int maxRounds = 10,
    String intensityLevel = IntensityLevel.medium,
    String ageMode = RoomAgeMode.standard,
  }) async {
    final rRef = roomRef(roomId);
    final snapshot = await rRef.get();
    if (!snapshot.exists) throw Exception('Room not found');

    final effectivePackIds =
        (packIds != null && packIds.isNotEmpty) ? packIds : null;
    final targetPackId = effectivePackIds != null
        ? effectivePackIds.first
        : (packId ?? await _questionRepo.getDefaultPackId());
    final resolvedPackIds = effectivePackIds ?? [targetPackId];

    // ── Mission 3: Generate session queue BEFORE writing to RTDB ─────────
    // Fetch all eligible questions from the selected packs.
    final allQuestions = await _questionRepo.fetchAllQuestionsFromPacks(
      packIds: resolvedPackIds,
    );

    // TEMP DEBUG — remove after verification
    debugPrint('[DEBUG] Fetched ${allQuestions.length} questions from Firestore');
    debugPrint('[DEBUG] Unique packIds: ${allQuestions.map((q) => q.packId).toSet()}');
    for (final q in allQuestions.take(10)) {
      debugPrint('[DEBUG] Q: ${q.id} — ${q.textAr.substring(0, q.textAr.length.clamp(0, 60))}');
    }

    // Build content filters from host-selected room config (Mission 5).
    final filters = ContentFilters.fromRoomConfig(
      intensityLevel: intensityLevel,
      ageMode: ageMode,
    );

    // ── Mission 13.3: Fetch room memory to exclude recently seen questions ─
    final recentQuestions = await _fetchRecentQuestions(roomId);

    // generateQueue throws InsufficientQuestionsException if pool < maxRounds.
    // That exception propagates to the lobby caller — do not catch it here.
    final result = _engine.generateQueue(
      allQuestions: allQuestions,
      packIds: resolvedPackIds,
      requestedRounds: maxRounds,
      filters: filters,
      excludedQuestionIds: recentQuestions,
    );

    GameplayAnalytics.sessionQueueGenerated(
      roomId: roomId,
      queueLength: result.queue.length,
      poolSize: result.totalPoolSize,
      packIds: result.packIds,
    );
    // ── END Mission 3 queue generation ────────────────────────────────────

    final session = GameSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      packId: targetPackId,
      usedQuestionIds: [],
      startedAt: DateTime.now(),
    );

    // Serialize queue as a List<Map> for RTDB storage.
    final queueJson = result.queue.map((q) => q.toJson()).toList();

    await rRef.update({
      'status': 'gameplay',
      'session': {
        ...session.toJson(),
        // ── New RTDB session fields (Mission 3) ──────────────────────────
        'sessionQueue': queueJson,       // ordered list of {id, textAr, textEn}
        'queueIndex': 0,                 // pointer to the next question to serve
        'generationMeta': result.toMetaJson(),
        // ── New RTDB session fields (Mission 5) ──────────────────────────
        'intensityLevel': intensityLevel, // host-selected intensity for reference
        'ageMode': ageMode,               // host-selected age mode for reference
        // ── End new fields ───────────────────────────────────────────────
      },
      'maxRounds': maxRounds,
      if (effectivePackIds != null)
        'selectedPackIds': {for (final id in effectivePackIds) id: true},
    });

    await nextRound(roomId);
  }

  /// Ends the session by setting room status to 'ended' and removing the join
  /// code so no new players can enter.
  ///
  /// MVP Decision: ending a session also ends the room. See decision-log.md.
  ///
  /// Event: SessionEnded
  Future<void> endSession(String roomId) async {
    final rRef = roomRef(roomId);
    final snapshot = await rRef.get();
    if (!snapshot.exists) return;

    final roomMap = _deepConvert(snapshot.value);
    final joinCode = roomMap['joinCode'] as String?;

    // ── Mission 13.3: Persist session questions to room memory ────────────
    await _saveSessionToRecentQuestions(roomId);

    await rRef.child('status').set('ended');

    if (joinCode != null) {
      await _db.ref('room_codes/$joinCode').remove();
    }
  }

  /// Resets session state and starts a new game immediately, preserving all
  /// host settings (players, pack selection, intensity, age mode, round cap).
  ///
  /// Called by the host from SessionSummaryScreen ("Play Again").
  ///
  /// Clears: currentRound, roundHistory (session is overwritten by startGame).
  /// Keeps: players, maxRounds, selectedPackIds, intensityLevel, ageMode.
  ///
  /// Does NOT restore join code — replaying is for the existing group only.
  ///
  /// Event: SessionReset
  Future<void> resetAndStartSession(String roomId) async {
    final snap = await roomRef(roomId).get();
    if (!snap.exists) throw Exception('Room not found');

    final data = _deepConvert(snap.value);
    final sessionData = data['session'] as Map<String, dynamic>?;
    final intensityLevel =
        (sessionData?['intensityLevel'] as String?) ?? IntensityLevel.medium;
    final ageMode = (data['ageMode'] as String?) ??
        (sessionData?['ageMode'] as String?) ??
        RoomAgeMode.standard;
    final maxRounds = (data['maxRounds'] as num?)?.toInt() ?? 10;
    final selectedPackIdsRaw = data['selectedPackIds'];
    final packIds = (selectedPackIdsRaw is Map)
        ? (selectedPackIdsRaw as Map<dynamic, dynamic>)
            .keys
            .cast<String>()
            .toList()
        : <String>[];

    // ── Mission 13.3: Persist session questions before clearing state ─────
    await _saveSessionToRecentQuestions(roomId);

    // Clear stale round state; session is fully overwritten by startGame.
    await roomRef(roomId).update({
      'currentRound': null,
      'roundHistory': null,
    });

    await startGame(
      roomId,
      packIds: packIds,
      maxRounds: maxRounds,
      intensityLevel: intensityLevel,
      ageMode: ageMode,
    );
  }

  // -------------------------------------------------------------------------
  // Round Progression
  // -------------------------------------------------------------------------

  /// Prepares and starts the next round.
  ///
  /// Mission 3: Reads the pre-generated question from the stored session queue
  /// (RTDB session/sessionQueue[queueIndex]) instead of fetching from Firestore.
  /// This eliminates per-round Firestore reads and ensures all players consume
  /// the same ordered question list.
  ///
  /// Backward compatibility: If session/sessionQueue is absent (room created
  /// before Mission 3), falls through to [_nextRoundLegacy] which preserves
  /// the original per-round Firestore fetch behavior.
  ///
  /// Event: NextRoundPrepared
  Future<void> nextRound(String roomId) async {
    final rRef = roomRef(roomId);
    final snapshot = await rRef.get();
    if (!snapshot.exists) return;

    final roomMap = _deepConvert(snapshot.value);
    final rawSession = roomMap['session'];
    final sessionMap = _deepConvert(rawSession);
    final playersMap = _deepConvert(roomMap['players']);

    // ── Read queue index ──────────────────────────────────────────────────
    final queueIndex = (sessionMap['queueIndex'] as num?)?.toInt() ?? 0;
    final maxRounds = (roomMap['maxRounds'] as num?)?.toInt() ?? 10;

    if (queueIndex >= maxRounds) {
      await rRef.child('status').set('ended');
      return;
    }

    // ── Check for stored queue (Mission 3) ────────────────────────────────
    // If sessionQueue is absent, this is a pre-Mission-3 room — use legacy path.
    final rawQueue = sessionMap['sessionQueue'];
    if (rawQueue == null) {
      await _nextRoundLegacy(roomId, roomMap);
      return;
    }

    // ── Read question from stored queue ───────────────────────────────────
    // NOTE: Do NOT pass rawQueue through _deepConvert — it is a List, not a Map.
    // _deepConvert only handles Maps and returns {} for anything else.
    final queueList = (rawQueue as List).cast<Object?>();
    if (queueIndex >= queueList.length) {
      await rRef.child('status').set('ended');
      return;
    }

    final qMap = _deepConvert(queueList[queueIndex]);
    final questionId = qMap['id'] as String? ?? '';
    final questionAr = qMap['textAr'] as String? ?? '';
    final questionEn = (qMap['textEn'] as String?) ?? '';
    final packId = (qMap['packId'] as String?) ?? '';

    // ── Build eligible player list ────────────────────────────────────────
    final allIds = playersMap.keys.toList();
    final presentIds = playersMap.entries
        .where((e) => _deepConvert(e.value)['isPresent'] == true)
        .map((e) => e.key)
        .toList();
    final eligibleIds = presentIds.isNotEmpty ? presentIds : allIds;

    GameplayAnalytics.roundServedFromQueue(
      roomId: roomId,
      queueIndex: queueIndex,
      questionId: questionId,
    );

    final now = DateTime.now();
    final round = GameRound(
      roundId: 'round_${now.millisecondsSinceEpoch}',
      questionId: questionId,
      questionAr: questionAr,
      questionEn: questionEn,
      packId: packId,
      phase: 'preparing', // clients see 'preparing' briefly before voting
      startedAt: now,
      expiresAt: now.add(const Duration(seconds: 30)),
      eligiblePlayerIds: eligibleIds,
      votes: {},
      roundNumber: queueIndex + 1,
    );

    final roundJson = round.toJson()..remove('result');

    // Extend usedQuestionIds for backward compat (session summary, analytics).
    final usedIds = List<String>.from(
      ((sessionMap['usedQuestionIds'] as List?) ?? []).cast<String>(),
    );

    // Atomic write: advance queue pointer, extend history, set new round, clear reactions.
    await rRef.update({
      'session/usedQuestionIds': [...usedIds, questionId],
      'session/queueIndex': queueIndex + 1,
      'currentRound': roundJson,
      'reactions': null,
    });

    // Transition to 'voting' — clients will see 'preparing' briefly.
    await rRef.child('currentRound/phase').set('voting');
  }

  /// Legacy round preparation path for rooms created before Mission 3.
  ///
  /// Identical to the pre-Mission-3 implementation of [nextRound]: fetches a
  /// random question from Firestore on each call. Only invoked when the RTDB
  /// session node has no [sessionQueue] field.
  Future<void> _nextRoundLegacy(
    String roomId,
    Map<String, dynamic> roomMap,
  ) async {
    final rRef = roomRef(roomId);
    final session = GameSession.fromJson(_deepConvert(roomMap['session']));
    final playersMap = _deepConvert(roomMap['players']);

    final maxRounds = (roomMap['maxRounds'] as num?)?.toInt() ?? 10;
    if (session.usedQuestionIds.length >= maxRounds) {
      await rRef.child('status').set('ended');
      return;
    }

    // Resolve pack IDs
    final selectedPackIdsRaw = roomMap['selectedPackIds'];
    final List<String> packIds;
    if (selectedPackIdsRaw is Map && (selectedPackIdsRaw as Map).isNotEmpty) {
      packIds = (selectedPackIdsRaw as Map).keys.map((k) => k.toString()).toList();
    } else {
      packIds = [session.packId];
    }

    final allIds = playersMap.keys.toList();
    final presentIds = playersMap.entries
        .where((e) => _deepConvert(e.value)['isPresent'] == true)
        .map((e) => e.key)
        .toList();
    final eligibleIds = presentIds.isNotEmpty ? presentIds : allIds;

    final question = await _questionRepo.fetchRandomQuestionFromPacks(
      packIds: packIds,
      excludedIds: session.usedQuestionIds,
    );

    if (question == null) {
      await rRef.child('status').set('ended');
      return;
    }

    final now = DateTime.now();
    final round = GameRound(
      roundId: 'round_${now.millisecondsSinceEpoch}',
      questionId: question.id,
      questionAr: question.textAr,
      questionEn: question.textEn,
      phase: 'preparing',
      startedAt: now,
      expiresAt: now.add(const Duration(seconds: 30)),
      eligiblePlayerIds: eligibleIds,
      votes: {},
    );

    final roundJson = round.toJson()..remove('result');

    await rRef.update({
      'session/usedQuestionIds': [...session.usedQuestionIds, question.id],
      'currentRound': roundJson,
      'reactions': null,
    });

    await rRef.child('currentRound/phase').set('voting');
  }

  // -------------------------------------------------------------------------
  // Round History
  // -------------------------------------------------------------------------

  /// Persists a completed round's summary to session history.
  ///
  /// Storage: RTDB /rooms/{roomId}/roundHistory/{roundId}
  /// Written before [nextRound] overwrites currentRound.
  ///
  /// Event: RoundArchived
  Future<void> archiveRound(
    String roomId,
    RoundHistoryItem historyItem,
  ) async {
    await roomRef(roomId)
        .child('roundHistory/${historyItem.roundId}')
        .set(historyItem.toJson());
  }

  // -------------------------------------------------------------------------
  // Voting
  // -------------------------------------------------------------------------

  /// Submits a vote for a player.
  ///
  /// Direct write — no phase check to avoid the race condition where the host's
  /// timer fires vote_locked between the user tapping and the RTDB read.
  /// RTDB security rules enforce that only auth.uid == voterId can write.
  Future<void> submitVote({
    required String roomId,
    required String voterId,
    required String targetId,
  }) async {
    print('[Mission8.8][Vote] roomId=$roomId voterId=$voterId targetId=$targetId');
    await roomRef(roomId).child('currentRound/votes/$voterId').set(targetId);
  }

  // -------------------------------------------------------------------------
  // Result Computation
  // -------------------------------------------------------------------------

  /// Computes the result for the current round and transitions to result_ready.
  ///
  /// Mission 8.8: Refactored to accept optional [hintVotes] and [hintEligibleIds]
  /// from the caller ([GameplayService._lockRound]). When the lock was triggered
  /// by vote-completion ([GameplayService._checkVotingProgress]), the caller
  /// already holds the full confirmed vote set from the RTDB stream — using it
  /// directly eliminates the race where the last vote is still in-flight to the
  /// server at the moment of the RTDB re-read.
  ///
  /// When the lock was triggered by the 30-second timeout, the caller's captured
  /// [round] is stale (it holds the vote state from when the timer was scheduled,
  /// often 0 votes). In that case, [hintVotes.length < hintEligibleIds.length]
  /// and we fall through to the RTDB read path, which includes an 800 ms settling
  /// delay to allow last-second in-flight writes to reach the server.
  ///
  /// MVP: Cloud Functions not yet deployed — client-side computation remains active.
  Future<void> computeAndSetResult(
    String roomId, {
    Map<String, String>? hintVotes,
    List<String>? hintEligibleIds,
  }) async {
    final roundRef = roomRef(roomId).child('currentRound');

    final Map<String, String> votes;
    final int eligibleCount;
    final bool usedHint;

    // Vote-completion path: use in-memory data provided by the caller.
    // The stream fired because votes.length >= eligiblePlayerIds.length, so
    // the hint contains the full confirmed vote set — no server re-read needed.
    if (hintVotes != null &&
        hintEligibleIds != null &&
        hintVotes.length >= hintEligibleIds.length) {
      votes = hintVotes;
      eligibleCount = hintEligibleIds.length;
      usedHint = true;
    } else {
      // Timeout path: hint data is stale (captured at timer-schedule time).
      // Wait briefly so any last-second votes written just before the timeout
      // have time to propagate to the Firebase server before we read.
      if (hintVotes != null) {
        // Called from _lockRound with a stale hint — apply settling delay.
        await Future.delayed(const Duration(milliseconds: 800));
      }
      final snapshot = await roundRef.get();
      if (!snapshot.exists) return;

      final roundMap = _deepConvert(snapshot.value);
      votes = Map<String, String>.from(roundMap['votes'] ?? {});

      // Handle both List and Map-as-array forms that Firebase RTDB may return.
      final rawEligibleList = roundMap['eligiblePlayerIds'];
      if (rawEligibleList is List) {
        eligibleCount = rawEligibleList.length;
      } else if (rawEligibleList is Map) {
        eligibleCount = rawEligibleList.length; // integer-key map = stored array
      } else {
        eligibleCount = 0;
      }
      usedHint = false;
    }

    final totalVotes = votes.length;

    // All eligible players must vote for the round to produce a valid result.
    // If the 30-second timer fires before all votes arrive, the result is
    // insufficient_votes (the round is skipped in cumulative wolf scoring).
    final minVotes = eligibleCount > 0 ? eligibleCount : 1;

    print('[Mission8.8][Compute] roomId=$roomId usedHint=$usedHint '
        'totalVotes=$totalVotes eligibleCount=$eligibleCount minVotes=$minVotes '
        'votes=$votes');
    debugPrint('[GameSession] computeAndSetResult: eligibleCount=$eligibleCount '
        'totalVotes=$totalVotes minVotes=$minVotes usedHint=$usedHint');

    late RoundResult result;

    if (totalVotes < minVotes) {
      // Preserve any partial votes in voteCounts so the round recap shows
      // which players did vote, even though the round is classified as
      // insufficient (not counted in wolf scoring).
      final partialCounts = <String, int>{};
      for (final targetId in votes.values) {
        partialCounts[targetId] = (partialCounts[targetId] ?? 0) + 1;
      }
      result = RoundResult(
        winningPlayerIds: [],
        voteCounts: partialCounts,
        resultType: 'insufficient_votes',
        totalValidVotes: totalVotes,
        computedAt: DateTime.now(),
      );
    } else {
      final counts = <String, int>{};
      for (final targetId in votes.values) {
        counts[targetId] = (counts[targetId] ?? 0) + 1;
      }

      int maxVotes = 0;
      for (final c in counts.values) {
        if (c > maxVotes) maxVotes = c;
      }

      final winners = counts.entries
          .where((e) => e.value == maxVotes)
          .map((e) => e.key)
          .toList();

      result = RoundResult(
        winningPlayerIds: winners,
        voteCounts: counts,
        resultType: winners.length > 1 ? 'tie' : 'normal',
        totalValidVotes: totalVotes,
        computedAt: DateTime.now(),
      );
    }

    print('[Mission8.8][Result] roomId=$roomId type=${result.resultType} '
        'winners=${result.winningPlayerIds} voteCounts=${result.voteCounts}');
    debugPrint('[GameSession] Result: type=${result.resultType} '
        'winners=${result.winningPlayerIds} voteCounts=${result.voteCounts}');
    final resultJson = result.toJson();
    // Ensure winningPlayerIds is never null in RTDB (Firebase omits empty arrays).
    resultJson['winningPlayerIds'] ??= <dynamic>[];
    resultJson['voteCounts'] ??= <String, dynamic>{};
    await roundRef.update({
      'result': resultJson,
      'phase': 'result_ready',
    });
  }

  // -------------------------------------------------------------------------
  // Reactions (per-round, per-player)
  // -------------------------------------------------------------------------

  /// Writes or overwrites the calling player's reaction for the current round.
  ///
  /// Path: rooms/{roomId}/currentRound/reactions/{playerId}
  /// Writing to a keyed path (not push()) enforces one reaction per player —
  /// a second tap simply overwrites. Reactions are automatically cleared when
  /// the host writes a new currentRound object (nextRound), giving per-round
  /// lifecycle with no explicit cleanup step.
  Future<void> sendReaction({
    required String roomId,
    required String playerId,
    required String emoji,
  }) async {
    await roomRef(roomId)
        .child('currentRound/reactions/$playerId')
        .set({'emoji': emoji, 'timestamp': DateTime.now().toIso8601String()});
  }

  /// Streams the full reactions map for the current round.
  ///
  /// Returns Map<playerId, emoji>. Emits an empty map when the round resets
  /// (reactions node is absent after nextRound). Callers diff consecutive
  /// maps to detect new/changed reactions and trigger floating bubbles.
  Stream<Map<String, String>> observeReactionMap(String roomId) {
    return roomRef(roomId)
        .child('currentRound/reactions')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <String, String>{};
      final raw = _deepConvert(event.snapshot.value);
      final result = <String, String>{};
      raw.forEach((playerId, data) {
        if (data is Map) {
          final emoji = _deepConvert(data)['emoji'] as String?;
          if (emoji != null) result[playerId] = emoji;
        }
      });
      return result;
    });
  }

  // -------------------------------------------------------------------------
  // Streams
  // -------------------------------------------------------------------------

  /// Observes current round changes.
  Stream<GameRound?> observeCurrentRound(String roomId) {
    return roomRef(roomId).child('currentRound').onValue.map((event) {
      if (event.snapshot.exists) {
        final json = _deepConvert(event.snapshot.value);
        _normalizeRoundJson(json);
        return GameRound.fromJson(json);
      }
      return null;
    });
  }

  /// One-shot read of the current round. Returns null if absent or malformed.
  ///
  /// Used by [GameSessionController.endSession] to archive the last round
  /// before the session ends, ensuring its votes count in the cumulative tally.
  Future<GameRound?> fetchCurrentRound(String roomId) async {
    final snapshot = await roomRef(roomId).child('currentRound').get();
    if (!snapshot.exists) return null;
    final json = _deepConvert(snapshot.value);
    _normalizeRoundJson(json);
    try {
      return GameRound.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/game_round.dart';
import '../domain/game_session.dart';
import '../domain/round_history_item.dart';
import '../domain/round_result.dart';
import '../domain/reaction.dart';
import '../../room/domain/room.dart';
import 'question_repository.dart';

final gameSessionRepositoryProvider = Provider<GameSessionRepository>((ref) {
  return GameSessionRepository(
    FirebaseDatabase.instance,
    ref.read(questionRepositoryProvider),
  );
});

class GameSessionRepository {
  final FirebaseDatabase _db;
  final QuestionRepository _questionRepo;

  GameSessionRepository(this._db, this._questionRepo);

  /// Public accessor to the room node. Used by [GameplayService] and
  /// [GameSessionController] for targeted field writes.
  DatabaseReference roomRef(String roomId) => _db.ref('rooms/$roomId');

  // -------------------------------------------------------------------------
  // Session Lifecycle
  // -------------------------------------------------------------------------

  /// Starts a new game session. Transitions room from lobby to gameplay,
  /// then fires the first round.
  Future<void> startGame(String roomId, {String? packId}) async {
    final rRef = roomRef(roomId);
    final snapshot = await rRef.get();
    if (!snapshot.exists) throw Exception('Room not found');

    final room = Room.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    final targetPackId = packId ?? await _questionRepo.getDefaultPackId();

    final session = GameSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      packId: targetPackId,
      usedQuestionIds: [],
      startedAt: DateTime.now(),
    );

    await rRef.update({
      'status': 'gameplay',
      'session': session.toJson(),
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

    final roomMap = Map<String, dynamic>.from(snapshot.value as Map);
    final joinCode = roomMap['joinCode'] as String?;

    await rRef.child('status').set('ended');

    if (joinCode != null) {
      await _db.ref('room_codes/$joinCode').remove();
    }
  }

  // -------------------------------------------------------------------------
  // Round Progression
  // -------------------------------------------------------------------------

  /// Prepares and starts the next round.
  ///
  /// Hardening (Mission 7):
  /// - Creates a fresh [roundId] using current timestamp.
  /// - Fetches a non-duplicate question using [session.usedQuestionIds].
  /// - Clears all prior votes by overwriting currentRound.
  /// - Clears all reactions (sets to null).
  /// - Transitions phase: preparing → voting (two discrete writes so clients
  ///   see the 'preparing' flash before voting opens).
  ///
  /// Event: NextRoundPrepared
  Future<void> nextRound(String roomId) async {
    final rRef = roomRef(roomId);
    final snapshot = await rRef.get();
    if (!snapshot.exists) return;

    final roomMap = Map<String, dynamic>.from(snapshot.value as Map);
    final session =
        GameSession.fromJson(Map<String, dynamic>.from(roomMap['session'] as Map));
    final playersMap = Map<String, dynamic>.from(roomMap['players'] as Map);

    // Only present players are eligible to vote
    final eligibleIds = playersMap.entries
        .where(
          (e) => Map<String, dynamic>.from(e.value as Map)['isPresent'] == true,
        )
        .map((e) => e.key)
        .toList();

    // Fetch a non-duplicate question
    final question = await _questionRepo.fetchRandomQuestion(
      packId: session.packId,
      excludedIds: session.usedQuestionIds,
    );

    if (question == null) {
      // Question pack exhausted — end the session
      await rRef.child('status').set('ended');
      return;
    }

    final now = DateTime.now();
    final round = GameRound(
      roundId: 'round_${now.millisecondsSinceEpoch}',
      questionId: question.id,
      questionAr: question.textAr,
      questionEn: question.textEn,
      phase: 'preparing', // ← enters 'preparing' first
      startedAt: now,
      expiresAt: now.add(const Duration(seconds: 30)),
      eligiblePlayerIds: eligibleIds,
      votes: {},
    );

    // Atomic write: new round in 'preparing', mark question used, wipe reactions
    await rRef.update({
      'session/usedQuestionIds': [...session.usedQuestionIds, question.id],
      'currentRound': round.toJson(),
      'reactions': null,
    });

    // Transition to 'voting' — clients will see 'preparing' briefly
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
  Future<void> submitVote({
    required String roomId,
    required String voterId,
    required String targetId,
  }) async {
    if (voterId == targetId) {
      throw Exception('You cannot vote for yourself');
    }

    final roundRef = roomRef(roomId).child('currentRound');
    final snapshot = await roundRef.get();
    if (!snapshot.exists) return;

    final roundMap = Map<String, dynamic>.from(snapshot.value as Map);
    if (roundMap['phase'] != 'voting') {
      throw Exception('Voting is closed for this round');
    }

    final eligibleIds =
        List<String>.from(roundMap['eligiblePlayerIds'] as List);
    if (!eligibleIds.contains(voterId)) {
      throw Exception('You are not eligible to vote in this round');
    }

    await roundRef.child('votes/$voterId').set(targetId);
  }

  // -------------------------------------------------------------------------
  // Result Computation
  // -------------------------------------------------------------------------

  /// Computes the result for the current round and transitions to result_ready.
  ///
  /// DEPRECATED (Mission 10): No longer called by [GameplayService].
  /// Result computation is now owned by the Cloud Function [resolveRound]
  /// (functions/src/round_resolution.ts), triggered when the host writes
  /// vote_locked. Kept for reference and local-testing fallback only.
  /// The RTDB rule `currentRound/result: { .write: false }` will block this
  /// method when rules are deployed — only the Admin SDK (Cloud Function)
  /// can write result in production.
  Future<void> computeAndSetResult(String roomId) async {
    final roundRef = roomRef(roomId).child('currentRound');
    final snapshot = await roundRef.get();
    if (!snapshot.exists) return;

    final roundMap = Map<String, dynamic>.from(snapshot.value as Map);
    final votes = Map<String, String>.from(roundMap['votes'] ?? {});
    final totalVotes = votes.length;

    late RoundResult result;

    if (totalVotes < 3) {
      result = RoundResult(
        winningPlayerIds: [],
        voteCounts: {},
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

    await roundRef.update({
      'result': result.toJson(),
      'phase': 'result_ready',
    });
  }

  // -------------------------------------------------------------------------
  // Reactions
  // -------------------------------------------------------------------------

  /// Sends an ephemeral reaction.
  Future<void> sendReaction({
    required String roomId,
    required String playerId,
    required String emoji,
  }) async {
    final reactionsRef = roomRef(roomId).child('reactions');
    final reaction = Reaction(
      id: reactionsRef.push().key!,
      playerId: playerId,
      emoji: emoji,
      timestamp: DateTime.now(),
    );
    await reactionsRef.push().set(reaction.toJson());
  }

  /// Observes ephemeral reactions.
  Stream<Reaction> observeReactions(String roomId) {
    return roomRef(roomId).child('reactions').onChildAdded.map((event) {
      return Reaction.fromJson(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  // -------------------------------------------------------------------------
  // Streams
  // -------------------------------------------------------------------------

  /// Observes current round changes.
  Stream<GameRound?> observeCurrentRound(String roomId) {
    return roomRef(roomId).child('currentRound').onValue.map((event) {
      if (event.snapshot.exists) {
        return GameRound.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return null;
    });
  }
}

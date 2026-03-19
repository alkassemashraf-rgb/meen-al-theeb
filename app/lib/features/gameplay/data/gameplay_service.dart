import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_session_repository.dart';
import '../domain/game_round.dart';
import '../../room/data/room_repository.dart';

final gameplayServiceProvider = Provider<GameplayService>((ref) {
  return GameplayService(
    ref.read(gameSessionRepositoryProvider),
    ref.read(roomRepositoryProvider),
    ref,
  );
});

/// Low-level gameplay monitoring service.
///
/// Responsibilities:
/// - Watch the current round stream on the host client
/// - Detect when all eligible players have voted → transition to vote_locked
/// - Schedule a 30-second per-round timeout → transition to vote_locked
///
/// Authority model (Mission 10):
/// - Host client still owns the vote_locked transition (MVP compromise).
/// - Result computation (vote_locked → result_ready) is now owned by the
///   Cloud Function `resolveRound` in functions/src/round_resolution.ts.
/// - This service no longer calls [GameSessionRepository.computeAndSetResult].
///   The reveal UI observes result_ready via the existing round stream.
///
/// Reliability hardening (Mission 7):
/// - [_isLockingRound]: prevents [_lockRound] from executing concurrently or
///   more than once per round (guards both the vote-complete path and the
///   timeout path racing each other).
/// - [_lockedRoundId]: tracks which roundId has already been locked so a
///   stale stream event for the same round cannot trigger a second lock.
/// - [_timedRoundId]: prevents [_scheduleTimeout] from resetting the countdown
///   every time a new vote arrives on the stream (only set once per roundId).
///
/// This service does NOT own round archiving, session end, or next-round
/// orchestration. Those belong to [GameSessionController].
class GameplayService {
  final GameSessionRepository _sessionRepo;
  final RoomRepository _roomRepo;
  final Ref _ref;

  GameplayService(this._sessionRepo, this._roomRepo, this._ref);

  StreamSubscription? _roundSubscription;
  Timer? _roundTimeoutTimer;

  // Reliability guards
  bool _isLockingRound = false;
  String? _lockedRoundId;
  String? _timedRoundId;

  /// Starts watching a room's gameplay loop.
  /// Only the host should call this in the MVP version.
  void watchGameplay(String roomId) {
    stopWatching();
    _roundSubscription =
        _sessionRepo.observeCurrentRound(roomId).listen((round) {
      if (round == null) return;

      if (round.phase == 'voting') {
        _checkVotingProgress(roomId, round);
        _scheduleTimeout(roomId, round);
      } else {
        // Round is no longer in voting — cancel any pending timeout
        _roundTimeoutTimer?.cancel();
      }
    });
  }

  /// Stops all monitoring cleanly.
  /// Called by [GameplayScreen.dispose] and by [GameSessionController.endSession].
  void stopWatching() {
    _roundSubscription?.cancel();
    _roundSubscription = null;
    _roundTimeoutTimer?.cancel();
    _roundTimeoutTimer = null;
    _isLockingRound = false;
    _lockedRoundId = null;
    _timedRoundId = null;
  }

  void _checkVotingProgress(String roomId, GameRound round) {
    if (round.eligiblePlayerIds.isEmpty) return;
    print('[Mission8.8][CheckVoting] round=${round.roundId} '
        'votes=${round.votes.length} eligible=${round.eligiblePlayerIds.length} '
        'phase=${round.phase}');
    if (round.votes.length >= round.eligiblePlayerIds.length) {
      _lockRound(roomId, round);
    }
  }

  /// Schedules the 30-second timeout for [round].
  ///
  /// Guard: only schedules once per unique [roundId]. If a new vote arrives
  /// and triggers another stream event, we do NOT reset the countdown.
  void _scheduleTimeout(String roomId, GameRound round) {
    if (_timedRoundId == round.roundId) return; // Already scheduled for this round
    _timedRoundId = round.roundId;

    _roundTimeoutTimer?.cancel();
    final remaining = round.expiresAt.difference(DateTime.now());

    if (remaining.isNegative) {
      _lockRound(roomId, round);
    } else {
      _roundTimeoutTimer = Timer(remaining, () => _lockRound(roomId, round));
    }
  }

  /// Transitions the round to vote_locked.
  ///
  /// Guards:
  /// - [_isLockingRound]: prevents concurrent execution (e.g. timeout fires
  ///   the same instant all votes arrive).
  /// - [_lockedRoundId]: prevents re-locking the same round if a stale stream
  ///   event fires after the lock is complete.
  ///
  /// After writing vote_locked, the Cloud Function [resolveRound] takes over:
  /// it computes the result and writes result_ready. This client does NOT call
  /// computeAndSetResult — it simply waits for the round stream to deliver
  /// result_ready (which drives the reveal UI via [GameplayScreen]).
  ///
  /// Event: RoundLockRequested (host client) → RoundLocked (host client write)
  ///        → ResultComputationStarted (Cloud Function) → ResultReady (Cloud Function)
  Future<void> _lockRound(String roomId, GameRound round) async {
    if (_isLockingRound) return;
    if (_lockedRoundId == round.roundId) return;

    _isLockingRound = true;
    _lockedRoundId = round.roundId;
    _roundTimeoutTimer?.cancel();

    final trigger = round.votes.length >= round.eligiblePlayerIds.length
        ? 'votes'
        : 'timeout';
    print('[Mission8.8][LockRound] round=${round.roundId} trigger=$trigger '
        'votes=${round.votes.length} eligible=${round.eligiblePlayerIds.length} '
        'voteMap=${round.votes}');
    debugPrint('[GameplayService] Locking round ${round.roundId} '
        'votes=${round.votes.length}/${round.eligiblePlayerIds.length}');

    try {
      await _roomRepo
          .roomRef(roomId)
          .child('currentRound/phase')
          .set('vote_locked');
      // Pass in-memory round data so computeAndSetResult can use the votes
      // already confirmed by the stream (vote-completion path) without re-reading
      // from RTDB — eliminates the race where the last vote is still in-flight.
      await _sessionRepo.computeAndSetResult(
        roomId,
        hintVotes: round.votes,
        hintEligibleIds: round.eligiblePlayerIds,
      );
    } finally {
      _isLockingRound = false;
    }
  }

  Future<void> sendReaction(
    String roomId,
    String playerId,
    String emoji,
  ) async {
    await _sessionRepo.sendReaction(
      roomId: roomId,
      playerId: playerId,
      emoji: emoji,
    );
  }

  /// Streams the current round's reaction map: playerId → emoji.
  Stream<Map<String, String>> observeReactionMap(String roomId) {
    return _sessionRepo.observeReactionMap(roomId);
  }
}

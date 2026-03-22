import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category_registry.dart';
import '../domain/game_round.dart';
import '../domain/round_history_item.dart';
import '../domain/result_card_payload.dart';
import '../data/game_session_repository.dart';
import '../data/gameplay_service.dart';
import '../../room/data/room_repository.dart';
import '../../room/domain/room_player.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Transient UI/orchestration state for the current game session.
///
/// This is NOT stored in Firebase — it is ephemeral controller state that
/// prevents duplicate transitions and exposes loading/error signals to the UI.
class GameSessionControllerState {
  /// True while the host is in the middle of advancing to the next round.
  /// The "Next Round" button should be disabled when this is true.
  final bool isTransitioningRound;

  /// True while the host is ending the session.
  final bool isEndingSession;

  /// Non-null when the last operation failed. Cleared before each new attempt.
  final String? errorMessage;

  const GameSessionControllerState({
    this.isTransitioningRound = false,
    this.isEndingSession = false,
    this.errorMessage,
  });

  GameSessionControllerState copyWith({
    bool? isTransitioningRound,
    bool? isEndingSession,
    String? errorMessage,
  }) {
    return GameSessionControllerState(
      isTransitioningRound: isTransitioningRound ?? this.isTransitioningRound,
      isEndingSession: isEndingSession ?? this.isEndingSession,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Central session-orchestration layer for مين الذيب؟.
///
/// Responsibilities:
/// - Advancing from one round to the next (with archive + duplicate guard)
/// - Archiving completed round summaries to session history
/// - Building shareable [ResultCardPayload] from completed rounds
/// - Ending the session cleanly
///
/// Authority: Host-client for MVP. Cloud Functions will absorb protected writes
/// in a future mission.
///
/// This controller deliberately does NOT replace [GameplayService]. The service
/// continues to own low-level vote-progress monitoring and timeout scheduling.
/// This controller owns high-level session progression.
class GameSessionController
    extends StateNotifier<GameSessionControllerState> {
  final GameSessionRepository _sessionRepo;
  final Ref _ref;
  final String roomId;

  GameSessionController({
    required GameSessionRepository sessionRepo,
    required Ref ref,
    required this.roomId,
  })  : _sessionRepo = sessionRepo,
        _ref = ref,
        super(const GameSessionControllerState());

  // -------------------------------------------------------------------------
  // Next Round
  // -------------------------------------------------------------------------

  /// Archives [completedRound] and advances to the next round.
  ///
  /// Guards:
  /// - [isTransitioningRound] prevents duplicate execution (e.g. double-tap).
  /// - Phase guard ensures we only advance from [result_ready].
  ///
  /// Events emitted (conceptually):
  ///   NextRoundRequested → RoundArchived → NextRoundPrepared
  Future<void> advanceToNextRound(GameRound completedRound) async {
    // Duplicate execution guard
    if (state.isTransitioningRound) return;

    // Phase guard — only advance from result_ready
    if (completedRound.phase != 'result_ready') return;

    state = state.copyWith(isTransitioningRound: true, errorMessage: null);

    try {
      // 1. Archive the completed round before the RTDB node is overwritten
      await _archiveRound(completedRound);

      // 2. Prepare fresh round (new ID, new question, clear votes + reactions)
      await _sessionRepo.nextRound(roomId);
    } catch (e) {
      state = state.copyWith(
        isTransitioningRound: false,
        errorMessage: e.toString(),
      );
      return;
    }

    state = state.copyWith(isTransitioningRound: false);
  }

  // -------------------------------------------------------------------------
  // Round Archiving
  // -------------------------------------------------------------------------

  /// Writes a [RoundHistoryItem] to RTDB session history before the round is
  /// overwritten by the next round setup.
  ///
  /// Storage: RTDB /rooms/{roomId}/roundHistory/{roundId}
  ///
  /// Event: RoundArchived
  Future<void> _archiveRound(GameRound round) async {
    final result = round.result;
    if (result == null) return; // Nothing to archive if result never computed

    print('[Mission8.8][Archive] round=${round.roundId} '
        'type=${result.resultType} totalValidVotes=${result.totalValidVotes} '
        'voteCounts=${result.voteCounts} winners=${result.winningPlayerIds}');

    final historyItem = RoundHistoryItem(
      roundId: round.roundId,
      questionId: round.questionId,
      questionAr: round.questionAr,
      questionEn: round.questionEn,
      resultType: result.resultType,
      winningPlayerIds: result.winningPlayerIds,
      voteCounts: result.voteCounts,
      totalValidVotes: result.totalValidVotes,
      completedAt: result.computedAt,
    );

    await _sessionRepo.archiveRound(roomId, historyItem);
  }

  // -------------------------------------------------------------------------
  // Result Card
  // -------------------------------------------------------------------------

  /// Builds a shareable [ResultCardPayload] from a completed round and the
  /// current player roster.
  ///
  /// Returns null if the round result has not yet been computed.
  ///
  /// Event: ResultCardPrepared
  ResultCardPayload? buildResultCard(
    GameRound round,
    Map<String, RoomPlayer> players,
  ) {
    final result = round.result;
    if (result == null) return null;

    final playerInfos = round.eligiblePlayerIds
        .map((id) {
          final player = players[id];
          if (player == null) return null;
          return ResultCardPlayerInfo(
            playerId: id,
            displayName: player.displayName,
            avatarId: player.avatarId,
            voteCount: result.voteCounts[id] ?? 0,
            isWinner: result.winningPlayerIds.contains(id),
          );
        })
        .whereType<ResultCardPlayerInfo>()
        .toList();

    final categoryMeta = round.packId.isNotEmpty
        ? CategoryRegistry.get(round.packId)
        : null;

    return ResultCardPayload(
      roomId: roomId,
      roundId: round.roundId,
      questionAr: round.questionAr,
      questionEn: round.questionEn,
      resultType: result.resultType,
      categoryLabel: categoryMeta?.labelAr,
      players: playerInfos,
      generatedAt: DateTime.now(),
    );
  }

  // -------------------------------------------------------------------------
  // Session End
  // -------------------------------------------------------------------------

  /// Ends the session cleanly.
  ///
  /// For MVP: ending the session also ends the room (status → 'ended').
  /// This decision is documented in decision-log.md (Mission 7).
  ///
  /// Steps:
  /// 1. Stop gameplay monitoring on the host client
  /// 2. Set room status to 'ended' in RTDB
  /// 3. Clients observing room stream navigate away automatically
  ///
  /// Event: SessionEnded
  Future<void> endSession() async {
    if (state.isEndingSession) return;

    state = state.copyWith(isEndingSession: true, errorMessage: null);

    try {
      // Stop the host-side gameplay watcher before writing ended status so no
      // stale timer callback can fire after the room is closed.
      _ref.read(gameplayServiceProvider).stopWatching();

      // Archive the current round if it is in result_ready so its vote counts
      // are included in the session summary's cumulative wolf calculation.
      // This covers the case where the host ends the session directly from the
      // reveal screen without clicking "Next Round" first.
      try {
        final currentRound = await _sessionRepo.fetchCurrentRound(roomId);
        if (currentRound != null && currentRound.phase == 'result_ready') {
          await _archiveRound(currentRound);
        }
      } catch (_) {
        // Non-blocking: a failed archive must never prevent the session from ending.
      }

      await _sessionRepo.endSession(roomId);
    } catch (e) {
      state = state.copyWith(
        isEndingSession: false,
        errorMessage: e.toString(),
      );
      return;
    }

    state = state.copyWith(isEndingSession: false);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// [GameSessionController] provider, scoped per room via `.family`.
///
/// Usage:
///   ref.read(gameSessionControllerProvider(roomId).notifier).advanceToNextRound(round)
///   ref.watch(gameSessionControllerProvider(roomId))  // → GameSessionControllerState
final gameSessionControllerProvider = StateNotifierProvider.family<
    GameSessionController, GameSessionControllerState, String>(
  (ref, roomId) => GameSessionController(
    sessionRepo: ref.read(gameSessionRepositoryProvider),
    ref: ref,
    roomId: roomId,
  ),
);

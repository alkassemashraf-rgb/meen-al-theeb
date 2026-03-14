import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/round_history_item.dart';
import '../domain/session_summary.dart';

/// Reads `/rooms/{roomId}` once from RTDB and aggregates the data into a
/// [SessionSummary] for [SessionSummaryScreen].
///
/// Designed as a static utility so it can be called from both a Riverpod
/// [FutureProvider] and directly in tests without a provider container.
class SessionSummaryBuilder {
  SessionSummaryBuilder._();

  /// One-shot RTDB read. Returns null if the room node is missing.
  ///
  /// Reads:
  ///   - `/rooms/{roomId}/players`     → display name lookup
  ///   - `/rooms/{roomId}/roundHistory` → completed round archives
  ///
  /// Note: [RoundHistoryItem.fromJson] requires Freezed-generated code.
  ///       Run `flutter pub run build_runner build` before compiling.
  static Future<SessionSummary?> build(
    String roomId,
    FirebaseDatabase db,
  ) async {
    final snapshot = await db.ref('rooms/$roomId').get();
    if (!snapshot.exists) return null;

    final roomMap =
        Map<String, dynamic>.from(snapshot.value as Map);

    // -----------------------------------------------------------------------
    // 1. Extract player display names
    // -----------------------------------------------------------------------
    final playerNames = <String, String>{};
    final rawPlayers = roomMap['players'];
    if (rawPlayers is Map) {
      for (final entry in Map<String, dynamic>.from(rawPlayers).entries) {
        final playerData = Map<String, dynamic>.from(entry.value as Map);
        playerNames[entry.key] =
            playerData['displayName'] as String? ?? 'لاعب';
      }
    }

    // -----------------------------------------------------------------------
    // 2. Extract and parse round history
    // -----------------------------------------------------------------------
    final rounds = <RoundHistoryItem>[];
    final rawHistory = roomMap['roundHistory'];
    if (rawHistory is Map) {
      for (final entry in Map<String, dynamic>.from(rawHistory).entries) {
        try {
          final item = RoundHistoryItem.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
          rounds.add(item);
        } catch (_) {
          // Skip malformed entries — never crash the summary screen
        }
      }
    }

    // Sort chronologically by completedAt
    rounds.sort((a, b) => a.completedAt.compareTo(b.completedAt));

    if (rounds.isEmpty) {
      return SessionSummary(
        rounds: [],
        totalVotesReceived: {},
        playerDisplayNames: playerNames,
        totalRounds: 0,
        skippedRounds: 0,
        tieRounds: 0,
        mostVotedPlayerId: null,
        mostVotedCount: 0,
      );
    }

    // -----------------------------------------------------------------------
    // 3. Aggregate
    // -----------------------------------------------------------------------
    final totalVotes = <String, int>{};
    int skippedRounds = 0;
    int tieRounds = 0;

    for (final round in rounds) {
      switch (round.resultType) {
        case 'insufficient_votes':
          skippedRounds++;
        case 'tie':
          tieRounds++;
      }
      for (final entry in round.voteCounts.entries) {
        totalVotes[entry.key] =
            (totalVotes[entry.key] ?? 0) + entry.value;
      }
    }

    // Most voted player
    String? mostVotedId;
    int mostVotedCount = 0;
    for (final entry in totalVotes.entries) {
      if (entry.value > mostVotedCount) {
        mostVotedCount = entry.value;
        mostVotedId = entry.key;
      }
    }

    // -----------------------------------------------------------------------
    // 4. Build RoundRecap list
    // -----------------------------------------------------------------------
    final recaps = rounds.indexed.map((record) {
      final (i, round) = record;
      final winnerNames = round.winningPlayerIds
          .map((id) => playerNames[id] ?? 'لاعب')
          .toList();

      return RoundRecap(
        roundNumber: i + 1,
        roundId: round.roundId,
        questionAr: round.questionAr,
        resultType: round.resultType,
        winnerDisplayNames: winnerNames,
        voteCounts: round.voteCounts,
        totalValidVotes: round.totalValidVotes,
      );
    }).toList();

    return SessionSummary(
      rounds: recaps,
      totalVotesReceived: totalVotes,
      playerDisplayNames: playerNames,
      totalRounds: rounds.length,
      skippedRounds: skippedRounds,
      tieRounds: tieRounds,
      mostVotedPlayerId: mostVotedId,
      mostVotedCount: mostVotedCount,
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// One-shot [FutureProvider] that builds the session summary for [roomId].
///
/// Usage in [SessionSummaryScreen]:
///   final summary = ref.watch(sessionSummaryProvider(roomId));
final sessionSummaryProvider =
    FutureProvider.family<SessionSummary?, String>(
  (ref, roomId) =>
      SessionSummaryBuilder.build(roomId, FirebaseDatabase.instance),
);

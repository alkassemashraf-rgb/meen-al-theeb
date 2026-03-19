import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
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

  /// Recursively converts a Firebase snapshot value (Map<Object?, Object?>) to
  /// Map<String, dynamic> so that Freezed-generated fromJson methods receive
  /// the expected type. Without this, nested maps (e.g. voteCounts inside a
  /// RoundHistoryItem) remain as Map<Object?, Object?>, causing a runtime
  /// TypeError when Freezed's generated code casts them as Map<String, dynamic>.
  static Map<String, dynamic> _deepConvert(Object? value) {
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), v is Map ? _deepConvert(v) : v),
      );
    }
    return {};
  }

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

    // Use _deepConvert (not Map.from) so nested Firebase maps like voteCounts
    // are fully typed as Map<String, dynamic> before being passed to fromJson.
    final roomMap = _deepConvert(snapshot.value);

    // -----------------------------------------------------------------------
    // 1. Extract player display names and avatar IDs
    // -----------------------------------------------------------------------
    final playerNames = <String, String>{};
    final playerAvatarIds = <String, String>{};
    final rawPlayers = roomMap['players'];
    if (rawPlayers is Map) {
      for (final entry in Map<String, dynamic>.from(rawPlayers).entries) {
        final playerData = Map<String, dynamic>.from(entry.value as Map);
        playerNames[entry.key] =
            playerData['displayName'] as String? ?? 'لاعب';
        playerAvatarIds[entry.key] =
            playerData['avatarId'] as String? ?? '';
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
            _deepConvert(entry.value),
          );
          rounds.add(item);
          debugPrint('[Summary] Parsed round ${item.roundId} '
              'type=${item.resultType} votes=${item.voteCounts}');
        } catch (e) {
          // Log the error so failures are visible in debug builds, then skip.
          debugPrint('[Summary] ⚠️ Failed to parse round entry: $e');
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
        playerAvatarIds: playerAvatarIds,
        totalRounds: 0,
        skippedRounds: 0,
        tieRounds: 0,
        mostVotedPlayerId: null,
        mostVotedPlayerIds: const [],
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

    // Most voted players — find all players tied at the highest vote count.
    // If multiple players share the max, they are all "wolves" (session tie).
    int mostVotedCount = 0;
    for (final v in totalVotes.values) {
      if (v > mostVotedCount) mostVotedCount = v;
    }
    final allWolfIds = mostVotedCount > 0
        ? totalVotes.entries
            .where((e) => e.value == mostVotedCount)
            .map((e) => e.key)
            .toList()
        : <String>[];
    final String? mostVotedId = allWolfIds.isNotEmpty ? allWolfIds.first : null;
    debugPrint('[Summary] Wolves: $allWolfIds mostVotedCount=$mostVotedCount '
        'totalRounds=${rounds.length}');

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
      playerAvatarIds: playerAvatarIds,
      totalRounds: rounds.length,
      skippedRounds: skippedRounds,
      tieRounds: tieRounds,
      mostVotedPlayerId: mostVotedId,
      mostVotedPlayerIds: allWolfIds,
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

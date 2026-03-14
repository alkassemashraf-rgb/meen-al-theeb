/// Derived summary of a single completed round, built by [SessionSummaryBuilder].
///
/// Purpose: Lightweight display model for [SessionSummaryScreen]. Not persisted.
class RoundRecap {
  /// 1-indexed position of this round in the session.
  final int roundNumber;
  final String roundId;
  final String questionAr;

  /// resultType: normal | tie | insufficient_votes
  final String resultType;

  /// Resolved display names of winning players (empty for insufficient_votes).
  final List<String> winnerDisplayNames;

  /// playerId → votes received in this round.
  final Map<String, int> voteCounts;

  final int totalValidVotes;

  const RoundRecap({
    required this.roundNumber,
    required this.roundId,
    required this.questionAr,
    required this.resultType,
    required this.winnerDisplayNames,
    required this.voteCounts,
    required this.totalValidVotes,
  });

  bool get wasSkipped => resultType == 'insufficient_votes';
  bool get wasTie => resultType == 'tie';
}

/// Aggregated session-level summary, built by [SessionSummaryBuilder].
///
/// Purpose: Powers the [SessionSummaryScreen] display. Not persisted.
/// Source data: RTDB /rooms/{roomId}/roundHistory + /rooms/{roomId}/players
class SessionSummary {
  /// All completed rounds, ordered chronologically.
  final List<RoundRecap> rounds;

  /// playerId → total votes received across all rounds in this session.
  final Map<String, int> totalVotesReceived;

  /// playerId → displayName, for resolving IDs in the UI.
  final Map<String, String> playerDisplayNames;

  final int totalRounds;

  /// Number of rounds with resultType == 'insufficient_votes'.
  final int skippedRounds;

  /// Number of rounds with resultType == 'tie'.
  final int tieRounds;

  /// playerId of the player who received the most total votes.
  /// Null if no votes were cast across the session.
  final String? mostVotedPlayerId;

  /// Total votes received by [mostVotedPlayerId].
  final int mostVotedCount;

  const SessionSummary({
    required this.rounds,
    required this.totalVotesReceived,
    required this.playerDisplayNames,
    required this.totalRounds,
    required this.skippedRounds,
    required this.tieRounds,
    this.mostVotedPlayerId,
    required this.mostVotedCount,
  });

  /// Resolved display name of the most-voted player, if any.
  String? get mostVotedDisplayName =>
      mostVotedPlayerId != null ? playerDisplayNames[mostVotedPlayerId] : null;

  bool get hasAnyRounds => rounds.isNotEmpty;
}

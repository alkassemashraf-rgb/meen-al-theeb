/// Per-player data included in a shareable result card.
class ResultCardPlayerInfo {
  final String playerId;
  final String displayName;
  final String avatarId;
  final int voteCount;
  final bool isWinner;

  const ResultCardPlayerInfo({
    required this.playerId,
    required this.displayName,
    required this.avatarId,
    required this.voteCount,
    required this.isWinner,
  });
}

/// Client-side payload for rendering or exporting a round result card.
///
/// Purpose: Bundles all data needed to render or share a visual summary of a
///          completed round. Passed to [ResultCardWidget] or a future share/export
///          pipeline.
///
/// Storage: Not persisted. Generated on demand from a completed [GameRound] and
///          the current player roster. Discarded after use.
///
/// Built by: [GameSessionController.buildResultCard]
class ResultCardPayload {
  final String roomId;
  final String roundId;
  final String questionAr;
  final String questionEn;

  /// resultType: normal | tie | insufficient_votes
  final String resultType;

  /// All eligible players for this round with their vote context.
  final List<ResultCardPlayerInfo> players;

  final DateTime generatedAt;

  const ResultCardPayload({
    required this.roomId,
    required this.roundId,
    required this.questionAr,
    required this.questionEn,
    required this.resultType,
    required this.players,
    required this.generatedAt,
  });

  /// Convenience: returns only the winning players.
  List<ResultCardPlayerInfo> get winners =>
      players.where((p) => p.isWinner).toList();

  /// Whether this round produced a deterministic result.
  bool get hasValidResult => resultType != 'insufficient_votes';
}

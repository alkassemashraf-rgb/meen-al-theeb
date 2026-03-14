import 'package:freezed_annotation/freezed_annotation.dart';

part 'round_history_item.freezed.dart';
part 'round_history_item.g.dart';

/// Archived summary of a completed game round.
///
/// Purpose: Supports session history, future sharing, and summary screens.
/// Storage: RTDB /rooms/{roomId}/roundHistory/{roundId}
/// Written by: GameSessionController when the host triggers the next round.
@freezed
abstract class RoundHistoryItem with _$RoundHistoryItem {
  const factory RoundHistoryItem({
    required String roundId,
    required String questionId,
    required String questionAr,
    required String questionEn,

    /// resultType: normal | tie | insufficient_votes
    required String resultType,

    @Default([]) List<String> winningPlayerIds,

    /// playerId -> vote count received
    @Default({}) Map<String, int> voteCounts,

    required int totalValidVotes,
    required DateTime completedAt,
  }) = _RoundHistoryItem;

  factory RoundHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$RoundHistoryItemFromJson(json);
}

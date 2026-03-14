import 'package:freezed_annotation/freezed_annotation.dart';

part 'round_result.freezed.dart';
part 'round_result.g.dart';

@freezed
abstract class RoundResult with _$RoundResult {
  const factory RoundResult({
    required List<String> winningPlayerIds,
    required Map<String, int> voteCounts, // playerId -> count
    required String resultType, // normal | tie | insufficient_votes
    required int totalValidVotes,
    required DateTime computedAt,
  }) = _RoundResult;

  factory RoundResult.fromJson(Map<String, dynamic> json) => _$RoundResultFromJson(json);
}

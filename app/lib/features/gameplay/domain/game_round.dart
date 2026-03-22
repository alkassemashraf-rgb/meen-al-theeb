import 'package:freezed_annotation/freezed_annotation.dart';
import 'round_result.dart';

part 'game_round.freezed.dart';
part 'game_round.g.dart';

@freezed
abstract class GameRound with _$GameRound {
  const factory GameRound({
    required String roundId,
    required String questionId,
    required String questionAr,
    required String questionEn,
    @Default('') String packId,
    required String phase, // preparing | voting | vote_locked | result_ready
    required DateTime startedAt,
    required DateTime expiresAt,
    @Default([]) List<String> eligiblePlayerIds,
    @Default({}) Map<String, String> votes, // VoterId -> TargetPlayerId
    RoundResult? result,
    @Default(0) int roundNumber,
  }) = _GameRound;

  factory GameRound.fromJson(Map<String, dynamic> json) => _$GameRoundFromJson(json);
}

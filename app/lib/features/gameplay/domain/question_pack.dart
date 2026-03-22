import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_pack.freezed.dart';
part 'question_pack.g.dart';

@freezed
abstract class QuestionPack with _$QuestionPack {
  const factory QuestionPack({
    required String packId,
    required String name,
    @Default('') String description,
    @Default('ar') String language,
    @Default(0) int questionCount,
    @Default('🐺') String icon,
    @Default(false) bool isPremium,
    DateTime? createdAt,
    // ── Added in Mission 3: Question Engine V2 ────────────────────────────
    /// Whether this pack appears in the lobby. Allows soft-disabling packs
    /// without deleting them from Firestore. Defaults to true (backward compat).
    @Default(true) bool isEnabled,
    /// Minimum audience age rating for questions in this pack.
    /// Informational for lobby display. Defaults to 'all'.
    @Default('all') String minAgeRating,
    /// Dominant intensity level of questions in this pack.
    /// Informational for lobby display. Defaults to 'medium'.
    @Default('medium') String dominantIntensity,
  }) = _QuestionPack;

  factory QuestionPack.fromJson(Map<String, dynamic> json) =>
      _$QuestionPackFromJson(json);
}

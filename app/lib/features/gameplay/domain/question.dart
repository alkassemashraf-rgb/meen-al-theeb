import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';
part 'question.g.dart';

@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required String textAr,
    required String textEn,
    required String packId,
    // ── Added in Mission 3: Question Engine V2 ────────────────────────────
    /// Lifecycle status. Defaults to 'active' so existing Firestore docs
    /// without this field are treated as active (backward compatible).
    /// See [QuestionStatus] for valid values.
    @Default('active') String status,
    /// Content intensity level. Defaults to 'medium'.
    /// See [IntensityLevel] for valid values.
    @Default('medium') String intensity,
    /// Audience age rating. Defaults to 'all' (no restriction).
    /// See [AgeRating] for valid values.
    @Default('all') String ageRating,
    /// Semantic version of the question text (for future re-seeding audits).
    @Default(1) int version,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
}

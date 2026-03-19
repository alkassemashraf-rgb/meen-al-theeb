import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_question.freezed.dart';
part 'session_question.g.dart';

/// Lightweight question DTO stored in the RTDB session queue.
///
/// Contains only the fields a game round needs to render — question ID,
/// bilingual text, and the source pack ID for category badge display.
/// Intentionally excludes other metadata fields (intensity, status,
/// ageRating) that the engine uses at queue-generation time but are irrelevant
/// at display time.
///
/// Stored at RTDB: /rooms/{roomId}/session/sessionQueue (as an ordered list).
@freezed
abstract class SessionQuestion with _$SessionQuestion {
  const factory SessionQuestion({
    required String id,
    required String textAr,
    @Default('') String textEn,
    @Default('') String packId,
  }) = _SessionQuestion;

  factory SessionQuestion.fromJson(Map<String, dynamic> json) =>
      _$SessionQuestionFromJson(json);
}

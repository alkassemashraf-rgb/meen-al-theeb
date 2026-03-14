import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_pack.freezed.dart';
part 'question_pack.g.dart';

@freezed
class QuestionPack with _$QuestionPack {
  const factory QuestionPack({
    required String packId,
    required String name,
    @Default('') String description,
    @Default('ar') String language,
    @Default(0) int questionCount,
    @Default('🐺') String icon,
    @Default(false) bool isPremium,
    DateTime? createdAt,
  }) = _QuestionPack;

  factory QuestionPack.fromJson(Map<String, dynamic> json) =>
      _$QuestionPackFromJson(json);
}

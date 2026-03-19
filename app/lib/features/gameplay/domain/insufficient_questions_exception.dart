/// Thrown by [SessionQuestionEngine.generateQueue] when the eligible question
/// pool (after applying filters) is smaller than the requested round count.
///
/// The lobby screen catches this specific type and displays [messageAr] and
/// [messageEn] in a bilingual snackbar without any string construction at the
/// call site.
class InsufficientQuestionsException implements Exception {
  /// How many rounds were requested.
  final int requestedRounds;

  /// How many eligible questions were found after filtering.
  final int availableQuestions;

  /// Pack IDs that were searched.
  final List<String> packIds;

  const InsufficientQuestionsException({
    required this.requestedRounds,
    required this.availableQuestions,
    required this.packIds,
  });

  /// Arabic error message suitable for the lobby snackbar.
  String get messageAr =>
      'عدد الأسئلة المتاحة ($availableQuestions) أقل من عدد الجولات المطلوبة ($requestedRounds). '
      'يرجى تقليل عدد الجولات أو اختيار فئات إضافية.';

  /// English error message for bilingual display.
  String get messageEn =>
      'Not enough questions ($availableQuestions available, $requestedRounds requested). '
      'Please reduce the round count or select more categories.';

  @override
  String toString() =>
      'InsufficientQuestionsException(requested: $requestedRounds, available: $availableQuestions, packs: $packIds)';
}

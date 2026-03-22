import 'session_question.dart';

/// Return type of [SessionQuestionEngine.generateQueue].
///
/// Bundles the shuffled, balanced question queue with generation metadata
/// that gets stored in the RTDB session node for auditability and debugging.
class GenerationResult {
  /// The ordered, pre-shuffled list of questions for the session.
  /// Length is guaranteed to equal the requested round count.
  final List<SessionQuestion> queue;

  /// Pack IDs that were used as the source pool.
  final List<String> packIds;

  /// Total eligible questions found after applying [ContentFilters],
  /// before truncation to the requested round count.
  final int totalPoolSize;

  /// Timestamp when the queue was generated (stored in RTDB).
  final DateTime generatedAt;

  const GenerationResult({
    required this.queue,
    required this.packIds,
    required this.totalPoolSize,
    required this.generatedAt,
  });

  /// Converts to the JSON map stored at RTDB session/generationMeta.
  Map<String, dynamic> toMetaJson() => {
    'packIds': packIds,
    'totalPoolSize': totalPoolSize,
    'queueLength': queue.length,
    'generatedAt': generatedAt.millisecondsSinceEpoch,
  };
}

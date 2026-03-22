import 'package:flutter/foundation.dart';

/// Structured event logger for gameplay telemetry.
///
/// MVP: writes structured log lines to [debugPrint] only.
/// Future: replace each method body with a Firebase Analytics or PostHog call
/// without changing any callers.
class GameplayAnalytics {
  GameplayAnalytics._();

  /// Fired when a session question queue is successfully generated.
  static void sessionQueueGenerated({
    required String roomId,
    required int queueLength,
    required int poolSize,
    required List<String> packIds,
  }) {
    debugPrint(
      '[Analytics] session_queue_generated '
      'room=$roomId queue=$queueLength pool=$poolSize '
      'packs=${packIds.join(",")}',
    );
  }

  /// Fired when room start is blocked due to insufficient eligible questions.
  static void insufficientQuestionsBlocked({
    required String roomId,
    required int requested,
    required int available,
    required List<String> packIds,
  }) {
    debugPrint(
      '[Analytics] insufficient_questions_blocked '
      'room=$roomId requested=$requested available=$available '
      'packs=${packIds.join(",")}',
    );
  }

  /// Fired each round when a question is served from the stored queue.
  static void roundServedFromQueue({
    required String roomId,
    required int queueIndex,
    required String questionId,
  }) {
    debugPrint(
      '[Analytics] round_served_from_queue '
      'room=$roomId index=$queueIndex question=$questionId',
    );
  }
}

import 'question_enums.dart';

/// Immutable filter configuration passed to [SessionQuestionEngine.generateQueue].
///
/// All fields have safe defaults matching the MVP (all content enabled, standard
/// age rating). Designed for extension: add [allowedIntensities] filtering or
/// [maxAgeRating] tightening in a future mission without changing the engine signature.
class ContentFilters {
  /// Only questions with this status are eligible.
  /// Defaults to [QuestionStatus.active] — the standard production filter.
  final String requiredStatus;

  /// Only questions with age rating at or below this level are eligible.
  /// [AgeRating.allAges] means no age restriction.
  final String maxAgeRating;

  /// If non-empty, only questions with one of these intensity levels are eligible.
  /// Empty list = all intensities pass through.
  final List<String> allowedIntensities;

  const ContentFilters({
    this.requiredStatus = QuestionStatus.active,
    this.maxAgeRating = AgeRating.allAges,
    this.allowedIntensities = const [],
  });

  /// The default configuration used in all MVP game sessions.
  static const ContentFilters defaults = ContentFilters();

  /// Constructs a [ContentFilters] from the room-level config chosen by the host.
  ///
  /// [intensityLevel] maps to [allowedIntensities]:
  ///   - [IntensityLevel.light]  → only light questions eligible
  ///   - [IntensityLevel.medium] → light + medium (cumulative)
  ///   - [IntensityLevel.spicy]  → strictly spicy only; engine auto-expands to
  ///                               [spicy, medium] if pool is too small (light
  ///                               is never included as a fallback)
  ///
  /// [ageMode] maps to [maxAgeRating]:
  ///   - [RoomAgeMode.standard] → [AgeRating.teen]  (adult questions blocked)
  ///   - [RoomAgeMode.plus18]   → [AgeRating.adult] (adult questions allowed)
  ///   - [RoomAgeMode.plus21]   → [AgeRating.allAges] (age check bypassed)
  static ContentFilters fromRoomConfig({
    String intensityLevel = IntensityLevel.medium,
    String ageMode = RoomAgeMode.standard,
  }) {
    final List<String> allowedIntensities;
    switch (intensityLevel) {
      case IntensityLevel.light:
        allowedIntensities = [IntensityLevel.light];
        break;
      case IntensityLevel.medium:
        allowedIntensities = [IntensityLevel.light, IntensityLevel.medium];
        break;
      case IntensityLevel.spicy:
        // Strict spicy: only spicy questions are eligible. The engine expands
        // to [spicy, medium] automatically when the pool is too small for the
        // requested round count. Light is never included as a fallback.
        allowedIntensities = [IntensityLevel.spicy];
        break;
      default:
        allowedIntensities = const [];
    }

    final String maxAgeRating;
    switch (ageMode) {
      case RoomAgeMode.plus18:
        maxAgeRating = AgeRating.adult;
        break;
      case RoomAgeMode.plus21:
        maxAgeRating = AgeRating.allAges;
        break;
      default: // standard — block adult content
        maxAgeRating = AgeRating.teen;
    }

    return ContentFilters(
      allowedIntensities: allowedIntensities,
      maxAgeRating: maxAgeRating,
    );
  }

  /// Returns true if a question with the given metadata passes all active filters.
  bool passes({
    required String status,
    required String intensity,
    required String ageRating,
  }) {
    if (status != requiredStatus) return false;
    if (allowedIntensities.isNotEmpty &&
        !allowedIntensities.contains(intensity)) return false;
    if (maxAgeRating != AgeRating.allAges &&
        ageRating == AgeRating.adult &&
        maxAgeRating != AgeRating.adult) return false;
    return true;
  }
}

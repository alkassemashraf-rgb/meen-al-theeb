/// String constant namespaces for question metadata.
///
/// Using classes with string constants (not Dart enums) avoids
/// Freezed/json_annotation enum-serialization complexity while still
/// providing IDE autocomplete and preventing magic strings.

/// Question content intensity levels.
class IntensityLevel {
  IntensityLevel._();

  static const String light  = 'light';
  static const String medium = 'medium';
  static const String spicy  = 'spicy';

  static const List<String> values = [light, medium, spicy];

  static bool isValid(String value) => values.contains(value);
}

/// Question lifecycle statuses.
class QuestionStatus {
  QuestionStatus._();

  /// Live and eligible for session queue generation.
  static const String active   = 'active';

  /// Soft-deleted or under review — filtered out by the engine.
  static const String disabled = 'disabled';

  /// Written but not yet reviewed for quality.
  static const String draft    = 'draft';

  static const List<String> values = [active, disabled, draft];
}

/// Audience age-rating tiers.
class AgeRating {
  AgeRating._();

  /// Suitable for all ages (default for all MVP content).
  static const String allAges = 'all';

  /// Teen content (13+).
  static const String teen    = 'teen';

  /// Adult content (18+).
  static const String adult   = 'adult';

  static const List<String> values = [allAges, teen, adult];
}

/// Room-level age mode selected by the host before game start.
///
/// Maps to [ContentFilters.maxAgeRating] via [ContentFilters.fromRoomConfig].
class RoomAgeMode {
  RoomAgeMode._();

  /// General audience — adult-rated questions are blocked.
  static const String standard = 'standard';

  /// 18+ session — adult-rated questions are allowed.
  static const String plus18   = 'plus18';

  /// 21+ session — all content allowed, age check bypassed entirely.
  static const String plus21   = 'plus21';

  static const List<String> values = [standard, plus18, plus21];

  static bool isValid(String v) => values.contains(v);
}

/// Category registry for Meen Al Theeb question packs.
///
/// ## Design
///
/// Each category key is a normalized string constant that maps 1-to-1 with a
/// Firestore `questionPacks` document ID (the `packId` field on [Question]).
/// The registry is purely in-memory compile-time data — no Firestore
/// serialization required for this layer.
///
/// ## Adding a new category
///
/// 1. Add a constant to [CategoryKeys].
/// 2. Add a corresponding [CategoryMeta] entry to [CategoryRegistry._all].
/// 3. Seed the matching Firestore `questionPacks` document using the same key.

// ── Category key constants ─────────────────────────────────────────────────

/// Normalized string identifiers for every question category.
///
/// These values are used as `packId` in Firestore and as keys in
/// [CategoryRegistry]. Always reference these constants instead of raw strings.
class CategoryKeys {
  CategoryKeys._();

  static const String friends       = 'friends';
  static const String funnyChaos    = 'funny_chaos';
  static const String embarrassing  = 'embarrassing';
  static const String savage        = 'savage';
  static const String deepExposing  = 'deep_exposing';
  static const String majlisGcc     = 'majlis_gcc';
  static const String couples       = 'couples';
  static const String age21Plus     = 'age_21_plus';

  /// All keys in canonical display order.
  static const List<String> values = [
    friends,
    funnyChaos,
    embarrassing,
    savage,
    deepExposing,
    majlisGcc,
    couples,
    age21Plus,
  ];

  static bool isValid(String key) => values.contains(key);
}

// ── Category metadata ──────────────────────────────────────────────────────

/// Immutable display and configuration metadata for a single category.
///
/// [key]        Matches a [CategoryKeys] constant and the Firestore packId.
/// [labelAr]    Arabic display label shown in the lobby.
/// [labelEn]    English display label shown in the lobby.
/// [sortOrder]  Ascending integer controlling lobby list order.
/// [isActive]   If false, the category is hidden from the lobby without
///              requiring a Firestore schema change.
/// [icon]       Emoji used as a visual accent in category cards.
class CategoryMeta {
  final String key;
  final String labelAr;
  final String labelEn;
  final int    sortOrder;
  final bool   isActive;
  final String icon;

  const CategoryMeta({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.sortOrder,
    this.isActive = true,
    this.icon     = '🐺',
  });

  @override
  String toString() =>
      'CategoryMeta(key: $key, labelAr: $labelAr, sortOrder: $sortOrder, '
      'isActive: $isActive)';
}

// ── Registry ───────────────────────────────────────────────────────────────

/// Static registry mapping every [CategoryKeys] value to its [CategoryMeta].
///
/// Usage:
/// ```dart
/// final meta = CategoryRegistry.get(CategoryKeys.friends);
/// final active = CategoryRegistry.activeCategories;
/// ```
class CategoryRegistry {
  CategoryRegistry._();

  static const Map<String, CategoryMeta> _all = {
    CategoryKeys.friends: CategoryMeta(
      key:       CategoryKeys.friends,
      labelAr:   'أصدقاء',
      labelEn:   'Friends',
      sortOrder: 1,
      icon:      '👯',
    ),
    CategoryKeys.funnyChaos: CategoryMeta(
      key:       CategoryKeys.funnyChaos,
      labelAr:   'فوضى مضحكة',
      labelEn:   'Funny Chaos',
      sortOrder: 2,
      icon:      '😂',
    ),
    CategoryKeys.embarrassing: CategoryMeta(
      key:       CategoryKeys.embarrassing,
      labelAr:   'أحراج',
      labelEn:   'Embarrassing',
      sortOrder: 3,
      icon:      '😳',
    ),
    CategoryKeys.savage: CategoryMeta(
      key:       CategoryKeys.savage,
      labelAr:   'ساڤج',
      labelEn:   'Savage',
      sortOrder: 4,
      icon:      '🔥',
    ),
    CategoryKeys.deepExposing: CategoryMeta(
      key:       CategoryKeys.deepExposing,
      labelAr:   'افضح',
      labelEn:   'Deep Exposing',
      sortOrder: 5,
      icon:      '🕵️',
    ),
    CategoryKeys.majlisGcc: CategoryMeta(
      key:       CategoryKeys.majlisGcc,
      labelAr:   'مجلس',
      labelEn:   'Gulf Majlis',
      sortOrder: 6,
      icon:      '🫖',
    ),
    CategoryKeys.couples: CategoryMeta(
      key:       CategoryKeys.couples,
      labelAr:   'أزواج',
      labelEn:   'Couples',
      sortOrder: 7,
      icon:      '💑',
    ),
    CategoryKeys.age21Plus: CategoryMeta(
      key:       CategoryKeys.age21Plus,
      labelAr:   '٢١+',
      labelEn:   '21+',
      sortOrder: 8,
      icon:      '🔞',
    ),
  };

  /// Returns the [CategoryMeta] for [key], or null if the key is unrecognized.
  static CategoryMeta? get(String key) => _all[key];

  /// Returns the [CategoryMeta] for [key].
  /// Throws [ArgumentError] if the key is unrecognized.
  static CategoryMeta getOrThrow(String key) {
    final meta = _all[key];
    if (meta == null) throw ArgumentError('Unknown category key: $key');
    return meta;
  }

  /// All categories in [CategoryMeta.sortOrder] order.
  static List<CategoryMeta> get all {
    final list = _all.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Only categories where [CategoryMeta.isActive] is true, in sort order.
  static List<CategoryMeta> get activeCategories {
    return all.where((m) => m.isActive).toList();
  }

  /// Returns the pack IDs of all active categories, in sort order.
  /// Convenience for passing directly to [SessionQuestionEngine.generateQueue].
  static List<String> get activePackIds =>
      activeCategories.map((m) => m.key).toList();
}

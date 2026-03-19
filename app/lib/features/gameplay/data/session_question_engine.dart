import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category_registry.dart';
import '../domain/content_filters.dart';
import '../domain/generation_result.dart';
import '../domain/insufficient_questions_exception.dart';
import '../domain/question.dart';
import '../domain/question_enums.dart';
import '../domain/session_question.dart';

final sessionQuestionEngineProvider = Provider<SessionQuestionEngine>((ref) {
  return SessionQuestionEngine();
});

/// Stateless service that generates a balanced, deduplicated session question
/// queue from a flat list of [Question] objects.
///
/// The engine is intentionally decoupled from Firebase — it operates on
/// already-fetched data so it can be unit-tested without emulators.
///
/// ## Algorithm
///
/// 1. **Filter** — Keep only questions whose `packId` is in [packIds] and
///    whose metadata passes [ContentFilters.passes].
/// 2. **Insufficient check** — If eligible count < [requestedRounds], throw
///    [InsufficientQuestionsException].
/// 3. **Group** — Bucket eligible questions by `packId`.
/// 4. **Shuffle buckets** — Each bucket is shuffled independently so the
///    selection within a pack is random.
/// 5. **Round-robin interleave** — Walk buckets in sequence, taking one
///    question at a time. This guarantees category variety even before the
///    final sort.
/// 6. **Pacing** — Reorder the interleaved list so intensity escalates across
///    the session (light → medium → spicy). When only one intensity level is
///    available (e.g. light-only mode) a standard shuffle is applied instead.
/// 7. **Map to DTO** — Convert [Question] → [SessionQuestion] (drops metadata).
/// 8. **Return** [GenerationResult].
class SessionQuestionEngine {
  SessionQuestionEngine();

  /// High-risk category keys whose questions should be prioritized in spicy
  /// rooms and positioned toward the back half of single-intensity sessions.
  /// Soft categories (friends, funnyChaos, majlisGcc) are intentionally absent.
  static const Set<String> _highRiskCategoryKeys = {
    CategoryKeys.embarrassing,
    CategoryKeys.savage,
    CategoryKeys.deepExposing,
    CategoryKeys.age21Plus,
    CategoryKeys.couples,
  };

  /// Generates a balanced, paced question queue for a game session.
  ///
  /// [allQuestions]    All questions fetched from the selected packs (raw,
  ///                   unfiltered). Filtering is done here.
  /// [packIds]         The host's selected pack IDs.
  /// [requestedRounds] Number of questions needed (== round count).
  /// [filters]         Content filter configuration. Defaults to MVP defaults.
  /// [random]          Injectable [math.Random] for deterministic unit tests.
  ///
  /// Throws [InsufficientQuestionsException] if the eligible pool is smaller
  /// than [requestedRounds].
  GenerationResult generateQueue({
    required List<Question> allQuestions,
    required List<String> packIds,
    required int requestedRounds,
    ContentFilters filters = ContentFilters.defaults,
    math.Random? random,
    List<String> excludedQuestionIds = const [],
  }) {
    final rng = random ?? math.Random();

    // ── Step 1: Filter ────────────────────────────────────────────────────
    var eligible = allQuestions.where((q) {
      if (!packIds.contains(q.packId)) return false;
      return filters.passes(
        status: q.status,
        intensity: q.intensity,
        ageRating: q.ageRating,
      );
    }).toList();

    // ── Step 1.5: Fallback expansion for strict spicy mode ───────────────
    // When the pool is strict-spicy but too small, expand to [spicy, medium]
    // before throwing. Light is never included as a fallback for spicy rooms.
    var effectiveFilters = filters;
    if (eligible.length < requestedRounds &&
        filters.allowedIntensities.length == 1 &&
        filters.allowedIntensities.first == IntensityLevel.spicy) {
      final expandedFilters = ContentFilters(
        requiredStatus: filters.requiredStatus,
        maxAgeRating: filters.maxAgeRating,
        allowedIntensities: [IntensityLevel.spicy, IntensityLevel.medium],
      );
      final expanded = allQuestions.where((q) {
        if (!packIds.contains(q.packId)) return false;
        return expandedFilters.passes(
          status: q.status,
          intensity: q.intensity,
          ageRating: q.ageRating,
        );
      }).toList();
      if (expanded.length >= requestedRounds) {
        eligible = expanded;
        effectiveFilters = expandedFilters;
      }
      // If still insufficient, Step 2 throws InsufficientQuestionsException.
    }

    // ── isSpicyRoom flag ─────────────────────────────────────────────────
    // True when the host selected strict-spicy intent. Derived from the
    // original filters (not effectiveFilters) so it stays true even after
    // Step 1.5 expanded the pool to [spicy, medium].
    final bool isSpicyRoom =
        filters.allowedIntensities.length == 1 &&
        filters.allowedIntensities.first == IntensityLevel.spicy;

    // ── Step 1.6: Room memory exclusion (Mission 13.3) ───────────────────
    // Filter out questions seen in recent sessions for this room.
    // If the filtered pool is too small, relax the exclusion (allow reuse)
    // while preserving all content/intensity filters. Generation MUST NOT
    // fail due to the exclusion filter alone.
    if (excludedQuestionIds.isNotEmpty) {
      final excludedSet = excludedQuestionIds.toSet();
      final withExclusion =
          eligible.where((q) => !excludedSet.contains(q.id)).toList();
      if (withExclusion.length >= requestedRounds) {
        eligible = withExclusion;
        debugPrint('[Engine] Anti-repetition: excluded ${excludedSet.length} '
            'recent questions; pool: ${eligible.length}');
      } else {
        // Fallback: relax recent filter — content/age filters are preserved.
        debugPrint('[Engine] Anti-repetition fallback: filtered pool '
            '(${withExclusion.length}) < $requestedRounds rounds; '
            'relaxing recent exclusion. Pool stays at ${eligible.length}');
      }
    }

    // ── Step 2: Insufficient check ────────────────────────────────────────
    if (eligible.length < requestedRounds) {
      throw InsufficientQuestionsException(
        requestedRounds: requestedRounds,
        availableQuestions: eligible.length,
        packIds: packIds,
      );
    }

    // ── Step 3: Group by packId ───────────────────────────────────────────
    final buckets = <String, List<Question>>{};
    for (final packId in packIds) {
      buckets[packId] = [];
    }
    for (final q in eligible) {
      buckets[q.packId]?.add(q);
    }
    // Remove packs that ended up with zero eligible questions after filtering.
    buckets.removeWhere((_, v) => v.isEmpty);

    // ── Step 4: Shuffle each bucket independently ─────────────────────────
    for (final bucket in buckets.values) {
      bucket.shuffle(rng);
    }

    // ── Step 5: Round-robin interleave ────────────────────────────────────
    final keys = buckets.keys.toList();
    final pointers = {for (final k in keys) k: 0};
    final interleaved = <Question>[];

    while (interleaved.length < requestedRounds) {
      bool addedAny = false;
      for (final key in keys) {
        if (interleaved.length >= requestedRounds) break;
        final bucket = buckets[key]!;
        final ptr = pointers[key]!;
        if (ptr < bucket.length) {
          interleaved.add(bucket[ptr]);
          pointers[key] = ptr + 1;
          addedAny = true;
        }
      }
      // Safety guard: stop if all buckets are exhausted.
      if (!addedAny) break;
    }

    // ── Step 6: Pacing + Category Distribution ────────────────────────────
    // Use effectiveFilters so the pacing algorithm sees the actual intensity
    // set in the pool. For single-intensity pools, fall back to shuffle; for
    // spicy rooms, follow with category ordering so high-risk content clusters
    // toward the back. The streak-fix pass runs universally after both paths.
    if (effectiveFilters.allowedIntensities.length == 1) {
      interleaved.shuffle(rng);
      if (isSpicyRoom) {
        // Group soft categories to the front and high-risk to the back so
        // the session escalates by category even without intensity variety.
        _applySpicyCategoryOrdering(interleaved, rng);
      }
    } else {
      _applyPacing(interleaved, effectiveFilters, rng, isSpicyRoom: isSpicyRoom);
    }
    // Universal category diversity pass: prevents 3+ consecutive same-category
    // regardless of room type or intensity configuration.
    _fixCategoryStreaks(interleaved);

    // ── Step 7: Map to SessionQuestion DTOs ───────────────────────────────
    final queue = interleaved
        .take(requestedRounds)
        .map((q) => SessionQuestion(
              id: q.id,
              textAr: q.textAr,
              textEn: q.textEn,
              packId: q.packId,
            ))
        .toList();

    // ── Step 7b: Observability logging (debug only) ───────────────────────
    if (kDebugMode) {
      final catCounts = <String, int>{};
      final intensityCounts = <String, int>{};
      for (final q in interleaved.take(requestedRounds)) {
        catCounts[q.packId] = (catCounts[q.packId] ?? 0) + 1;
        intensityCounts[q.intensity] = (intensityCounts[q.intensity] ?? 0) + 1;
      }
      final highRiskCount =
          queue.where((sq) => _highRiskCategoryKeys.contains(sq.packId)).length;
      debugPrint('[Engine] Category distribution: $catCounts');
      debugPrint('[Engine] Intensity distribution: $intensityCounts');
      debugPrint('[Engine] High-risk=$highRiskCount '
          'soft=${queue.length - highRiskCount} isSpicyRoom=$isSpicyRoom');
    }

    return GenerationResult(
      queue: queue,
      packIds: packIds,
      totalPoolSize: eligible.length,
      generatedAt: DateTime.now(),
    );
  }

  // ── Pacing helpers ───────────────────────────────────────────────────────

  /// Reorders [questions] in-place so intensity escalates across the session.
  ///
  /// Two pacing strategies based on available intensities:
  ///
  /// **Modes that include light** (light-only, medium, or all-intensity):
  ///   Fixed escalation thresholds:
  ///   - 0.00 – 0.30 → prefer [IntensityLevel.light]
  ///   - 0.30 – 0.70 → prefer [IntensityLevel.medium]
  ///   - 0.70 – 1.00 → prefer [IntensityLevel.spicy]
  ///
  /// **Modes that exclude light** (spicy → [medium, spicy]):
  ///   Proportional equal-split across available levels:
  ///   - 0.00 – 0.50 → prefer [IntensityLevel.medium]
  ///   - 0.50 – 1.00 → prefer [IntensityLevel.spicy]
  ///   This ensures spicy sessions are evenly balanced between medium and
  ///   spicy rather than being front-loaded with lighter fallback content.
  ///
  /// When the preferred intensity pool is exhausted, the nearest available
  /// intensity is used as a fallback so the queue always fills completely.
  void _applyPacing(
    List<Question> questions,
    ContentFilters filters,
    math.Random rng, {
    bool isSpicyRoom = false,
  }) {
    final n = questions.length;
    if (n == 0) return;

    // Derive the full intensity set available for this session.
    // allowedIntensities.isEmpty is a safety fallback (not triggered by any
    // current UI mode after the spicy filter fix in content_filters.dart).
    final availableIntensities = filters.allowedIntensities.isEmpty
        ? [IntensityLevel.light, IntensityLevel.medium, IntensityLevel.spicy]
        : List<String>.from(filters.allowedIntensities);

    // Bucket questions by intensity; shuffle each bucket to preserve
    // within-intensity randomness.
    final pools = <String, List<Question>>{
      for (final intensity in availableIntensities) intensity: [],
    };
    for (final q in questions) {
      final bucket = pools[q.intensity];
      if (bucket != null) {
        bucket.add(q);
      } else {
        // Safety: unrecognised intensity → assign to first bucket.
        pools[availableIntensities.first]!.add(q);
      }
    }
    for (final bucket in pools.values) {
      bucket.shuffle(rng);
    }

    // Sort available intensities light → medium → spicy so the proportional
    // split in _preferredIntensity is meaningful.
    const intensityOrder = [
      IntensityLevel.light,
      IntensityLevel.medium,
      IntensityLevel.spicy,
    ];
    final sortedAvailable = availableIntensities.toList()
      ..sort((a, b) =>
          intensityOrder.indexOf(a).compareTo(intensityOrder.indexOf(b)));

    // Assign each slot its question using the phase-based preferred intensity.
    // Tracks the last two categories picked to enforce the diversity rule
    // (no more than 2 consecutive same-category when alternatives exist).
    final result = <Question>[];
    String? lastCat;
    String? secondLastCat;

    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final preferred = _preferredIntensity(progress, sortedAvailable,
          isSpicyRoom: isSpicyRoom);
      final bool lastTwoCatsSame =
          lastCat != null && secondLastCat != null && secondLastCat == lastCat;
      final q = _pickCategoryAwareFromPools(
        preferred,
        pools,
        availableIntensities,
        isSpicyRoom: isSpicyRoom,
        lastCat: lastCat,
        lastTwoCatsSame: lastTwoCatsSame,
      );
      if (q != null) {
        result.add(q);
        secondLastCat = lastCat;
        lastCat = q.packId;
      }
    }

    questions
      ..clear()
      ..addAll(result);
  }

  /// Target intensity for a given session progress fraction (0.0 – 1.0).
  ///
  /// When [sortedAvailable] does not include [IntensityLevel.light]:
  ///   - [isSpicyRoom] + exactly 2 levels → 35 % medium / 65 % spicy
  ///     (stronger escalation toward the end vs the old 50/50 split).
  ///   - All other no-light cases → proportional equal-split.
  ///
  /// Otherwise preserves the original fixed escalation curve:
  ///   0–30% light → 30–70% medium → 70–100% spicy.
  String _preferredIntensity(
    double progress,
    List<String> sortedAvailable, {
    bool isSpicyRoom = false,
  }) {
    if (!sortedAvailable.contains(IntensityLevel.light)) {
      if (isSpicyRoom && sortedAvailable.length == 2) {
        // Escalating spicy: 35% medium → 65% spicy.
        // sortedAvailable is [medium, spicy] (sorted light→medium→spicy).
        return progress < 0.35 ? sortedAvailable[0] : sortedAvailable[1];
      }
      // Proportional equal-split for all other no-light configurations.
      final index = (progress * sortedAvailable.length)
          .floor()
          .clamp(0, sortedAvailable.length - 1);
      return sortedAvailable[index];
    }
    // Fixed escalation for modes that include light.
    if (progress < 0.30) return IntensityLevel.light;
    if (progress < 0.70) return IntensityLevel.medium;
    return IntensityLevel.spicy;
  }

  /// Removes and returns one question from the [preferred] pool.
  /// Falls back to the nearest available intensity if [preferred] is exhausted.
  Question? _pickFromPool(
    String preferred,
    Map<String, List<Question>> pools,
    List<String> available,
  ) {
    final preferredPool = pools[preferred];
    if (preferredPool != null && preferredPool.isNotEmpty) {
      return preferredPool.removeLast();
    }

    for (final fallback in _fallbackOrder(preferred, available)) {
      final fallbackPool = pools[fallback];
      if (fallbackPool != null && fallbackPool.isNotEmpty) {
        return fallbackPool.removeLast();
      }
    }

    return null;
  }

  /// Returns intensities in [available] other than [preferred], sorted by
  /// closeness to [preferred] on the light → medium → spicy scale.
  List<String> _fallbackOrder(String preferred, List<String> available) {
    const ordered = [
      IntensityLevel.light,
      IntensityLevel.medium,
      IntensityLevel.spicy,
    ];
    final prefIdx = ordered.indexOf(preferred);
    final fallbacks = available.where((i) => i != preferred).toList();
    fallbacks.sort((a, b) {
      final da = (ordered.indexOf(a) - prefIdx).abs();
      final db = (ordered.indexOf(b) - prefIdx).abs();
      return da.compareTo(db);
    });
    return fallbacks;
  }

  // ── Category-aware helpers (Mission 13.4) ────────────────────────────────

  /// Category-aware replacement for [_pickFromPool].
  ///
  /// Tries the [preferred] intensity pool first using [_bestFromPool], then
  /// falls back through other intensities in nearest-first order. Category
  /// preferences and streak avoidance are applied at every pool level.
  ///
  /// [isSpicyRoom]      When true, high-risk categories are preferred.
  /// [lastCat]          packId of the most recently picked question.
  /// [lastTwoCatsSame]  True when the last two picks share the same packId;
  ///                    triggers streak-avoidance in [_bestFromPool].
  Question? _pickCategoryAwareFromPools(
    String preferred,
    Map<String, List<Question>> pools,
    List<String> available, {
    bool isSpicyRoom = false,
    String? lastCat,
    bool lastTwoCatsSame = false,
  }) {
    final preferredPool = pools[preferred];
    if (preferredPool != null && preferredPool.isNotEmpty) {
      final q = _bestFromPool(
        preferredPool,
        isSpicyRoom: isSpicyRoom,
        lastCat: lastCat,
        avoidStreak: lastTwoCatsSame,
      );
      if (q != null) return q;
    }
    for (final fallback in _fallbackOrder(preferred, available)) {
      final pool = pools[fallback];
      if (pool != null && pool.isNotEmpty) {
        final q = _bestFromPool(
          pool,
          isSpicyRoom: isSpicyRoom,
          lastCat: lastCat,
          avoidStreak: lastTwoCatsSame,
        );
        if (q != null) return q;
      }
    }
    return null;
  }

  /// Removes and returns the best question from [pool] according to category
  /// preferences and streak-avoidance rules.
  ///
  /// Uses [List.lastIndexWhere] (O(n)) to find the best candidate while
  /// respecting the shuffle order already applied to the pool.
  ///
  /// Priority order:
  ///   1. High-risk category AND not [avoidCat]   (spicy rooms)
  ///   2. Any high-risk category                  (spicy rooms, streak forced)
  ///   3. Any category other than [avoidCat]      (all rooms, streak break)
  ///   4. [pool.removeLast()]                     (absolute fallback)
  ///
  /// [avoidStreak]  When true, the picker avoids extending a same-category
  ///                run-of-2. Falls through to [removeLast] only when the
  ///                pool is single-category (no alternative exists).
  Question? _bestFromPool(
    List<Question> pool, {
    bool isSpicyRoom = false,
    String? lastCat,
    bool avoidStreak = false,
  }) {
    if (pool.isEmpty) return null;

    final String? avoidCat = avoidStreak ? lastCat : null;

    if (isSpicyRoom) {
      // Priority 1: high-risk AND does not extend the streak.
      final idx = pool.lastIndexWhere((q) =>
          _highRiskCategoryKeys.contains(q.packId) && q.packId != avoidCat);
      if (idx != -1) return pool.removeAt(idx);

      // Priority 2: any high-risk (streak break not possible with high-risk).
      final idx2 =
          pool.lastIndexWhere((q) => _highRiskCategoryKeys.contains(q.packId));
      if (idx2 != -1) return pool.removeAt(idx2);
    }

    // Priority 3: any question that breaks the streak (all room types).
    if (avoidCat != null) {
      final idx3 = pool.lastIndexWhere((q) => q.packId != avoidCat);
      if (idx3 != -1) return pool.removeAt(idx3);
    }

    // Priority 4: absolute fallback — take whatever is available.
    return pool.removeLast();
  }

  /// Reorders [questions] in-place for single-intensity spicy sessions.
  ///
  /// Groups soft categories (friends, funny_chaos, majlis_gcc) to the front
  /// and high-risk categories to the back. Each group is independently
  /// shuffled to preserve internal randomness. This mirrors the escalation
  /// arc that [_applyPacing] provides for multi-intensity sessions.
  void _applySpicyCategoryOrdering(
      List<Question> questions, math.Random rng) {
    if (questions.isEmpty) return;

    final soft = questions
        .where((q) => !_highRiskCategoryKeys.contains(q.packId))
        .toList()
      ..shuffle(rng);
    final highRisk = questions
        .where((q) => _highRiskCategoryKeys.contains(q.packId))
        .toList()
      ..shuffle(rng);

    questions
      ..clear()
      ..addAll(soft)
      ..addAll(highRisk);
  }

  /// Fixes runs of 3+ consecutive questions from the same category.
  ///
  /// Performs a single left-to-right scan. When a streak-of-3 is detected at
  /// position [i], scans forward for the best swap candidate (same intensity
  /// first, then any differing-category question). If none exists (single-
  /// category pool), the streak is accepted as unavoidable.
  ///
  /// Preserves the intensity pacing curve by preferring same-intensity swaps.
  void _fixCategoryStreaks(List<Question> questions) {
    final n = questions.length;
    if (n < 3) return;

    for (int i = 2; i < n; i++) {
      final streakCat = questions[i].packId;
      if (questions[i - 1].packId != streakCat ||
          questions[i - 2].packId != streakCat) {
        continue;
      }

      // Pass 1: same intensity, different category (preserves pacing curve).
      int bestIdx = -1;
      for (int j = i + 1; j < n; j++) {
        if (questions[j].packId != streakCat &&
            questions[j].intensity == questions[i].intensity) {
          bestIdx = j;
          break;
        }
      }

      // Pass 2: any different category (cross-intensity fallback).
      if (bestIdx == -1) {
        for (int j = i + 1; j < n; j++) {
          if (questions[j].packId != streakCat) {
            bestIdx = j;
            break;
          }
        }
      }

      if (bestIdx != -1) {
        final tmp = questions[i];
        questions[i] = questions[bestIdx];
        questions[bestIdx] = tmp;
      }
      // bestIdx == -1: all remaining are same category — streak is unavoidable.
    }
  }
}

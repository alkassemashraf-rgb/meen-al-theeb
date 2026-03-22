# Mission 13.4 — Intensity Reinforcement & Category Distribution

## Overview

Strengthens how the question engine prioritizes categories and intensities in spicy rooms,
ensuring bold, varied sessions instead of soft or repetitive tone clusters.

---

## Problem Statement

Even with correct intensity selection (spicy), generated queues could feel soft because:

1. Round-robin interleave gives **equal weight** to high-risk and soft categories
2. Spicy fallback pacing was a flat **50/50 medium/spicy** split (not escalating)
3. No streak prevention — same category could appear 4+ times in a row
4. Single-intensity spicy rooms had **no category ordering** at all

---

## Solution Summary

| Problem | Fix | Method |
|---|---|---|
| Equal category weight | Prefer high-risk in every intensity-pool pick | `_bestFromPool` |
| Flat 50/50 spicy split | Skew to 35% medium / 65% spicy | `_preferredIntensity` |
| Same-category streaks | O(n²) swap pass after pacing | `_fixCategoryStreaks` |
| No ordering in single-intensity | Group soft-first, high-risk-last | `_applySpicyCategoryOrdering` |

---

## High-Risk vs Soft Category Classification

### High-Risk Categories
Questions from these categories are prioritized in spicy rooms and placed toward the back
half of single-intensity sessions:

| Key | Label |
|---|---|
| `embarrassing` | Embarrassing |
| `savage` | Savage |
| `deep_exposing` | Deep Exposing |
| `age_21_plus` | 21+ |
| `couples` | Couples |

### Soft Categories
These form the warm-up arc at the front of spicy sessions. They are not excluded — just
deprioritized when high-risk alternatives exist:

| Key | Label |
|---|---|
| `friends` | Friends |
| `funny_chaos` | Funny Chaos |
| `majlis_gcc` | Gulf Majlis |

---

## Intensity Split Change (Spicy Fallback Rooms)

Applies when: `isSpicyRoom == true` AND `effectiveFilters.allowedIntensities == [medium, spicy]`
(spicy pool expanded via Step 1.5 fallback).

| Before (Mission 8.6) | After (Mission 13.4) |
|---|---|
| 50% medium / 50% spicy | **35% medium / 65% spicy** |

All other room modes are unaffected.

---

## Category Ordering (Single-Intensity Spicy Rooms)

When the strict-spicy pool is large enough (no fallback expansion needed),
`effectiveFilters.allowedIntensities.length == 1` — no intensity pacing applies.

**`_applySpicyCategoryOrdering`** restores the escalation arc by category:
1. Soft categories → shuffled → placed at the **front**
2. High-risk categories → shuffled → placed at the **back**

Result: the session opens with lighter banter and escalates into high-risk territory
even without intensity variety.

---

## Category-Aware Pool Picking (`_bestFromPool`)

Called for every slot in the paced multi-intensity path. O(n) scan via `lastIndexWhere`.

**Priority order:**

1. **High-risk category + not streak-extending** *(spicy rooms only)*
2. **Any high-risk category** *(spicy rooms, when streak constraint conflicts)*
3. **Any category other than avoidCat** *(all rooms, streak break)*
4. **`removeLast()`** *(absolute fallback — single-category pool)*

**Streak avoidance** activates only when `lastTwoCatsSame == true` (the last two picks
share the same `packId`). When no alternative exists (single-category pool), the rule
is relaxed gracefully via Priority 4.

---

## Category Streak Fix (`_fixCategoryStreaks`)

Universal cleanup pass — runs after both the single-intensity and multi-intensity paths
in `generateQueue`. Prevents 3+ consecutive same-category questions for **all** room modes.

**Algorithm:**
1. Scan left-to-right
2. When streak-of-3 detected at position `i`:
   - **Pass 1**: Find first `j > i` with different category AND same intensity (preserves pacing)
   - **Pass 2** (fallback): Find first `j > i` with different category (any intensity)
   - Swap `questions[i]` ↔ `questions[j]`
3. If no candidate found: accept unavoidable streak (single-category pool)

---

## `isSpicyRoom` Flag

Derived from the **original** `filters` (not `effectiveFilters`) so it stays `true`
even after Step 1.5 expands the pool to `[spicy, medium]`:

```dart
final bool isSpicyRoom =
    filters.allowedIntensities.length == 1 &&
    filters.allowedIntensities.first == IntensityLevel.spicy;
```

This flag gates all spicy-specific behavior: category prioritization, the 35/65 split,
and category ordering.

---

## Non-Regression Matrix

| Room Mode | `isSpicyRoom` | Pacing Path | Intensity Split | Category Behavior |
|---|---|---|---|---|
| Light-only | false | shuffle | N/A | streak fix only |
| Medium (light+medium) | false | `_applyPacing` | 0–30% L / 30–70% M | streak fix only |
| All-intensity | false | `_applyPacing` | 0–30% L / 30–70% M / 70–100% S | streak fix only |
| Spicy strict (enough Qs) | true | shuffle + `_applySpicyCategoryOrdering` | N/A | soft-front / high-risk-back + streak fix |
| Spicy fallback [medium, spicy] | true | `_applyPacing` (category-aware) | **35% M / 65% S** | high-risk preferred + streak fix |

---

## Observability

Debug logs are emitted at queue generation time (release builds excluded via `kDebugMode`):

```
[Engine] Category distribution: {savage: 4, embarrassing: 3, friends: 3}
[Engine] Intensity distribution: {medium: 4, spicy: 6}
[Engine] High-risk=7 soft=3 isSpicyRoom=true
```

---

## Files Modified

| File | Change |
|---|---|
| `app/lib/features/gameplay/data/session_question_engine.dart` | All engine changes |

No other files modified. No schema changes. No UI changes.

---

## Dependencies

- Mission 3: `SessionQuestionEngine` base architecture
- Mission 8.6: Strict spicy mapping + Step 1.5 fallback expansion
- Mission 13.3: Anti-repetition room memory (Step 1.6)
- Mission 13.1: Prompt intensity/tone framework (upstream content quality)

---

[VERIFICATION START]

Implemented:
- spicy category prioritization added: YES
- category diversity rule added: YES
- late-round escalation strengthened: YES
- controlled fallback refined: YES
- Knowledge Center updated: YES

Validated:
- spicy rooms tested: NO
- category clustering reduced: NO
- escalation tested: NO
- fallback tested: NO
- no regression observed: NO

Files:
- Created: docs/knowledge-center/mission-13-4-intensity-reinforcement.md
- Updated: app/lib/features/gameplay/data/session_question_engine.dart

Notes:

[VERIFICATION END]

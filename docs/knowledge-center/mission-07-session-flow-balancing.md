# Mission 07 — Session Flow Balancing (Pacing & Intensity Distribution)

## Summary

Mission 7 introduces controlled pacing into the session question queue. Instead of presenting
questions in a purely random order, the engine now escalates intensity across the session timeline —
lighter questions appear early, medium questions dominate the middle, and spicy questions close the
session. The change is invisible to the UI; it improves perceived gameplay quality without any new
controls or schema changes.

---

## Algorithm Change

The original Step 6 (global shuffle) is replaced with a pacing step:

```
filter → group by pack → shuffle buckets → round-robin interleave → (NEW) pacing → map to DTOs
```

Specifically, after round-robin produces `requestedRounds` questions:

**Before (Step 6 — removed):**
```dart
interleaved.shuffle(rng);  // purely random order
```

**After (Step 6 — new):**
```dart
if (filters.allowedIntensities.length == 1) {
  interleaved.shuffle(rng);      // single-intensity mode: no escalation
} else {
  _applyPacing(interleaved, filters, rng);  // multi-intensity: apply phases
}
```

---

## Pacing Strategy

### Phase Thresholds

| Session progress | Preferred intensity |
|---|---|
| 0% – 30% | `light` |
| 30% – 70% | `medium` |
| 70% – 100% | `spicy` |

For a 10-round session: rounds 1–3 prefer light, rounds 4–7 prefer medium, rounds 8–10 prefer spicy.

### Pacing Steps (inside `_applyPacing`)

1. Derive `availableIntensities` from `ContentFilters.allowedIntensities`:
   - Empty (spicy/no-filter mode) → `[light, medium, spicy]`
   - Non-empty → use as-is (e.g. `[light, medium]` for medium mode)
2. Bucket the `requestedRounds` questions by intensity
3. Shuffle each intensity bucket independently (preserves within-intensity randomness)
4. For each slot `i` in `[0, requestedRounds)`:
   - Compute `progress = i / requestedRounds`
   - Determine `preferred` intensity from phase thresholds
   - Call `_pickFromPool(preferred, pools)` → removes and returns one question
5. Overwrite `interleaved` with the paced result

---

## Fallback Logic

When a preferred intensity pool is exhausted, `_fallbackOrder` returns the remaining
available intensities sorted by closeness to the preferred intensity on the `light → medium → spicy`
scale:

| Preferred | Fallback order |
|---|---|
| `light` | medium → spicy |
| `medium` | light, spicy (equidistant — light checked first) |
| `spicy` | medium → light |

This ensures late-session slots get medium questions (rather than reverting all the way to light)
when spicy questions run out.

---

## Intensity Filter Interaction

| Host setting | `allowedIntensities` | Pacing applied | Effective progression |
|---|---|---|---|
| `light` | `[light]` | No (single-intensity: global shuffle) | All light, random order |
| `medium` | `[light, medium]` | Yes | Light → medium → medium (spicy falls back to medium) |
| `spicy` | `[]` (no filter) | Yes | Light → medium → spicy |

The host's intensity filter is always respected — pacing only reorders questions within
the already-filtered pool. It cannot surface questions that were excluded by the filter.

---

## Determinism

The algorithm is deterministic for a given `(allQuestions, packIds, requestedRounds, filters, rng)`
tuple. An injectable `math.Random` (existing test hook) makes unit testing straightforward.

---

## Files Modified

### `app/lib/features/gameplay/data/session_question_engine.dart`
- Replaced global shuffle (Step 6) with pacing guard + `_applyPacing` call
- Added import for `question_enums.dart`
- Added private methods: `_applyPacing`, `_preferredIntensity`, `_pickFromPool`, `_fallbackOrder`
- Updated class and method doc comments to reflect the new step

---

## Known Limitations

- **Content dependency**: Pacing quality depends on the actual distribution of intensities in the
  question pool. If seeded content has very few light questions (e.g. 2 light out of 20), early
  rounds will quickly exhaust the light pool and fall back to medium.
- **Round-robin sampling**: The round-robin step (Step 5) samples by pack, not by intensity.
  The pacing step then reorders these samples. For very small sessions (e.g. 5 rounds) with
  uneven pack-intensity distributions, the pacing effect is visible but limited by what
  round-robin sampled.
- **Medium-mode late rounds**: When `intensityLevel = medium`, the late phase (70–100%) prefers
  spicy but falls back to medium (since spicy is not in `allowedIntensities`). This is intentional
  and correct — the session still escalates from light to medium without violating the host's choice.

---

## Test Checklist

- [ ] 10-round session, mixed intensities (light=4, medium=3, spicy=3) → first 3 questions light, middle 4 medium, last 3 spicy
- [ ] 10-round session, light-only (`allowedIntensities=[light]`) → purely shuffled, no escalation
- [ ] 10-round session, medium mode (`allowedIntensities=[light, medium]`) → escalates to medium, no spicy
- [ ] Fallback: session with 0 spicy questions in pool, spicy mode → late rounds fall back to medium then light
- [ ] Queue size always equals `requestedRounds` (no missing questions)
- [ ] Same `Random(42)` seed produces same order for same input (determinism)
- [ ] No regression: `InsufficientQuestionsException` still thrown when pool too small

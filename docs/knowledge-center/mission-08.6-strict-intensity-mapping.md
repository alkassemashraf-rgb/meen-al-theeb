# Mission 08.6 — Strict Intensity Mapping with Controlled Fallback

## Summary

Mission 8.6 tightens the intensity filter for spicy rooms from `[medium, spicy]` (set in
8.5) to strict `[spicy]`. When the strict pool is too small for the requested round count,
the engine expands to `[spicy, medium]` — but never to `[light]`. All other intensity
modes (light, medium) are unchanged.

---

## Change 1 — `ContentFilters.fromRoomConfig`: Strict Spicy Filter

### Before (8.5)
```dart
case IntensityLevel.spicy:
  allowedIntensities = [IntensityLevel.medium, IntensityLevel.spicy];
  break;
```

### After (8.6)
```dart
case IntensityLevel.spicy:
  // Strict spicy: only spicy questions are eligible. The engine expands
  // to [spicy, medium] automatically when the pool is too small for the
  // requested round count. Light is never included as a fallback.
  allowedIntensities = [IntensityLevel.spicy];
  break;
```

**File**: `content_filters.dart`

---

## Change 2 — `SessionQuestionEngine.generateQueue`: Step 1.5 Fallback Expansion

A new step is inserted between Step 1 (filter) and Step 2 (insufficient check).

### Algorithm
1. Filter with strict `[spicy]`.
2. **(New Step 1.5)** If pool < requestedRounds AND filters are strict-spicy:
   - Re-filter with `[spicy, medium]`.
   - If expanded pool >= requestedRounds: use expanded pool, set `effectiveFilters`.
   - If still insufficient: fall through to Step 2's `InsufficientQuestionsException`.
3. Step 2: throw if still insufficient.
4. …Steps 3–5 unchanged…
5. Step 6: use `effectiveFilters` (not original `filters`) for pacing.

### Key Invariants
- Light is **never** included as a fallback for spicy rooms.
- The fallback is silent — no user-visible indicator that medium questions were added.
- `InsufficientQuestionsException` is still thrown when even `[spicy, medium]` is too small.
- `effectiveFilters` drives the pacing so the proportional split applies to the actual
  intensity set in the pool (whether `[spicy]` or `[spicy, medium]`).

**File**: `session_question_engine.dart`

---

## Corrected Intensity Mapping

| Mode | `ContentFilters.allowedIntensities` | Engine fallback | Pacing |
|---|---|---|---|
| `light` | `[light]` | None | Shuffle (single level) |
| `medium` | `[light, medium]` | None | Fixed: 0–30% light → 30–70% medium |
| `spicy` | `[spicy]` (strict) | Expand to `[spicy, medium]` if thin | Proportional: 50% medium → 50% spicy (when expanded); shuffle if pure-spicy pool |

---

## Pacing Behaviour for Spicy Sessions

| Pool after fallback | `effectiveFilters.allowedIntensities.length` | Pacing strategy |
|---|---|---|
| Pure `[spicy]` (enough) | 1 | Global shuffle — all spicy, no escalation needed |
| Expanded `[spicy, medium]` | 2 | Proportional: 0–50% medium → 50–100% spicy |

The proportional split logic (no-light branch of `_preferredIntensity`, added in 8.5) is
reused unchanged. No new pacing logic was needed.

---

## Files Modified

| File | Change |
|---|---|
| `content_filters.dart` | `spicy` → `[spicy]` (strict); docstring updated |
| `session_question_engine.dart` | Step 1.5 fallback; `effectiveFilters` variable; Step 6 uses `effectiveFilters` |

---

## Known Limitations

- **Silent fallback**: Players in a spicy room may occasionally receive medium questions
  without any notification. This is intentional — transparency about pool exhaustion is
  deferred to a future analytics/telemetry mission.
- **No light fallback**: If a pack contains only light questions and is the only pack in
  a spicy room, `InsufficientQuestionsException` is thrown at game start. The host must
  select a pack with spicy or medium content.

---

## Test Checklist

- [ ] Spicy room with enough spicy questions: all questions are spicy (no medium)
- [ ] Spicy room with thin spicy pool (< rounds) but enough spicy+medium: session starts,
      first 50% are medium, last 50% are spicy
- [ ] Spicy room with no spicy or medium questions at all: `InsufficientQuestionsException`
      thrown, game start blocked
- [ ] Medium room unchanged: still gets light → medium escalation
- [ ] Light room unchanged: all light, random order

---

[VERIFICATION START]

Implemented:
- Strict spicy filter: YES (content_filters.dart: spicy → [spicy])
- Engine fallback expansion (spicy → [spicy, medium] when thin): YES
- Light never included in spicy fallback: YES (only expands to [spicy, medium])
- effectiveFilters drives Step 6 pacing: YES
- InsufficientQuestionsException still thrown when expansion insufficient: YES
- Medium/light modes unchanged: YES (no changes to those branches)
- Knowledge Center updated: YES

Validated:
- Strict spicy filter code review: YES (single-element list [spicy])
- Fallback expansion condition: YES (length==1 && first==spicy guard)
- effectiveFilters scoping: YES (var, initialized to filters, overwritten only on successful expansion)
- Step 6 uses effectiveFilters.allowedIntensities: YES
- Proportional pacing reused for [spicy, medium] pool: YES (unchanged _preferredIntensity no-light branch)

Files:
- Created:
  - docs/knowledge-center/mission-08.6-strict-intensity-mapping.md
- Updated:
  - app/lib/features/gameplay/domain/content_filters.dart
  - app/lib/features/gameplay/data/session_question_engine.dart

Notes:
- When the expanded pool is [spicy, medium], effectiveFilters.allowedIntensities.length == 2,
  so _applyPacing is called (not shuffle). The no-light branch in _preferredIntensity gives
  proportional 50/50 split — spicy-biased toward the end.
- When the strict [spicy] pool is sufficient, effectiveFilters.allowedIntensities.length == 1,
  so interleaved.shuffle(rng) is called — pure spicy, randomised order.
- The fallback only fires during generateQueue; ContentFilters.fromRoomConfig always returns
  [spicy] for spicy rooms. The expansion is an engine-internal detail.

[VERIFICATION END]

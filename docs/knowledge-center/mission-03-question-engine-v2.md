# Mission 3 — Question Engine V2 + Category Architecture

## Summary

Replaced per-round ad-hoc Firestore question fetching with a metadata-driven session queue
generated once at game start. The queue is stored in RTDB and consumed by each round
without additional Firestore reads.

**Before:** `nextRound()` called `fetchRandomQuestionFromPacks()` on every round.
**After:** `startGame()` generates a full queue; `nextRound()` reads from the stored queue.

---

## Problem Solved

| Before Mission 3 | After Mission 3 |
|---|---|
| Random Firestore fetch per round | Full queue generated once at game start |
| No content metadata (status, intensity, ageRating) | Questions carry `status`, `intensity`, `ageRating`, `version` |
| No disabled/archived question filtering | Disabled and draft questions excluded at generation time |
| Category multiselect was cosmetic | Only selected pack questions enter the pool |
| Risk of duplicate questions (exclusion list-based) | Deduplication guaranteed by construction |
| Per-round Firestore reads mid-session | Zero Firestore reads after session start |

---

## RTDB Schema Changes

Three new fields added to the session node at `/rooms/{roomId}/session/`.
The `GameSession` Freezed model is **intentionally not modified** — these fields
are written and read raw to avoid bloating the model with a large list.

```
session/
  sessionId           (string)          — unchanged
  packId              (string)          — unchanged
  usedQuestionIds     (array<string>)   — unchanged, still extended each round for compat
  startedAt           (timestamp)       — unchanged
  sessionQueue        (array<object>)   — NEW: [{id, textAr, textEn}, ...]
  queueIndex          (number)          — NEW: 0-based index of next question to serve
  generationMeta      (object)          — NEW: {packIds, totalPoolSize, queueLength, generatedAt}
```

The `queueIndex` is the authoritative round progress counter. `usedQuestionIds`
is extended each round for backward compatibility with `SessionSummaryBuilder`.

---

## New Files

| File | Purpose |
|---|---|
| `app/lib/features/gameplay/domain/question_enums.dart` | String constant namespaces for `IntensityLevel`, `QuestionStatus`, `AgeRating` |
| `app/lib/features/gameplay/domain/content_filters.dart` | Immutable filter config passed to the engine; `ContentFilters.defaults` is the MVP constant |
| `app/lib/features/gameplay/domain/session_question.dart` | Lightweight Freezed DTO stored in RTDB queue: `{id, textAr, textEn}` |
| `app/lib/features/gameplay/domain/generation_result.dart` | Engine return type: queue + metadata |
| `app/lib/features/gameplay/domain/insufficient_questions_exception.dart` | Typed exception with bilingual messages for lobby snackbar |
| `app/lib/features/gameplay/data/session_question_engine.dart` | Core queue generation algorithm (Riverpod provider: `sessionQuestionEngineProvider`) |
| `app/lib/features/gameplay/data/gameplay_analytics.dart` | Structured event logger (MVP: `debugPrint`; future: Firebase Analytics) |

---

## Modified Files

| File | Change |
|---|---|
| `domain/question.dart` | Added `status`, `intensity`, `ageRating`, `version` with `@Default()` |
| `domain/question_pack.dart` | Added `isEnabled`, `minAgeRating`, `dominantIntensity` with `@Default()` |
| `data/question_repository.dart` | Added `fetchAllQuestionsFromPacks()` (batch fetch for engine) |
| `data/game_session_repository.dart` | `startGame()` generates queue; `nextRound()` reads from queue; `_nextRoundLegacy()` for compat |
| `presentation/lobby_screen.dart` | Catches `InsufficientQuestionsException`, shows bilingual red snackbar |
| `seeds/seed_firestore.ts` | Adds `status`, `intensity`, `ageRating` defaults to all seeded questions; `isEnabled`, `minAgeRating`, `dominantIntensity` to packs |

---

## Engine Algorithm (`SessionQuestionEngine.generateQueue`)

1. **Filter** — Keep questions where `packId ∈ selectedPackIds` AND `filters.passes(status, intensity, ageRating)`
2. **Insufficient check** — If `eligible.length < requestedRounds` → throw `InsufficientQuestionsException`
3. **Group** — Bucket eligible questions by `packId`
4. **Shuffle buckets** — Each pack's bucket is shuffled independently (random within-pack order)
5. **Round-robin interleave** — Walk buckets in sequence, take 1 from each until `requestedRounds` is reached (guarantees category distribution)
6. **Global shuffle** — Final shuffle of the interleaved list (breaks predictable A-B-C-A-B-C pattern)
7. **Map to DTO** — Convert `Question` → `SessionQuestion` (drops metadata fields)
8. **Return** `GenerationResult`

The injectable `math.Random` parameter enables deterministic unit tests.

---

## Backward Compatibility

`GameSessionRepository.nextRound()` checks for `session/sessionQueue` before using
the new path. If the field is absent (room created before Mission 3), it falls through
to `_nextRoundLegacy()` which is the original per-round Firestore fetch behavior.
This ensures in-flight games are not disrupted during a deployment.

---

## Content Metadata Defaults

All new fields on `Question` use `@Default()` in Freezed so existing Firestore
documents that lack these fields parse correctly without a migration:

| Field | Default | Meaning |
|---|---|---|
| `status` | `'active'` | Existing docs treated as active |
| `intensity` | `'medium'` | Existing docs treated as medium intensity |
| `ageRating` | `'all'` | Existing docs have no age restriction |
| `version` | `1` | Existing docs at version 1 |

The seed script defaults match these Dart defaults exactly, keeping the two layers in sync.

---

## Analytics Events

| Event | Fired When |
|---|---|
| `session_queue_generated` | Queue successfully generated at game start |
| `insufficient_questions_blocked` | Room start blocked by pool too small |
| `round_served_from_queue` | Each round served from stored queue |

MVP: all events write to `debugPrint`. Replace method bodies for production analytics.

---

## Future Extension Points

- **Age gating**: Set `maxAgeRating` in `ContentFilters` when the room config supports it. The engine already filters by age rating.
- **Intensity pacing**: Set `allowedIntensities` in `ContentFilters` to control the mix (e.g., start light, end spicy).
- **Monetized packs**: New packs with `isEnabled: true` in Firestore automatically appear in the lobby without code changes.
- **Content versioning**: Increment `version` on a question to track which revision was used in sessions.
- **Analytics upgrade**: Replace `debugPrint` in `GameplayAnalytics` with Firebase Analytics calls — no callers need to change.

---

## Known Assumptions

- `packId` IS the category key. Packs and categories are the same concept in this architecture.
- Locale defaults to Arabic-first (`textAr` required, `textEn` optional).
- All 260 seeded launch questions are treated as `status: 'active'`, `intensity: 'medium'`, `ageRating: 'all'` since they were seeded without these fields. Re-running the seed script will write the explicit values.
- `GameSession` Freezed model was intentionally not modified to keep the queue fields as raw RTDB reads/writes, avoiding build_runner regeneration of a large list field.

# Mission 05 — Room Setup V2 (Intensity, Age Mode, Summary)

Completed: 2026-03-17

## Objective

Activate the Mission 3 content filter layer by exposing intensity and age mode controls to the host in the lobby, wiring them into `ContentFilters`, and showing a configuration summary before the game starts.

---

## Problem Solved

| Before | After |
|---|---|
| `ContentFilters.defaults` applied to every session (no restrictions) | Host selects intensity + age mode; filters built from those choices |
| No UI for content control | Intensity picker (3 levels) + Age mode picker (3 levels) in lobby |
| No pre-start summary | `_RoomSummary` card shows rounds, categories, intensity, age mode |

---

## New Room Configuration Fields

Both values are selected as local Riverpod state in the lobby and passed to `startGame()`. They are stored in the RTDB session node for reference.

### intensityLevel (String)

| Value | allowedIntensities in ContentFilters | Meaning |
|---|---|---|
| `'light'` | `['light']` | Only light questions |
| `'medium'` | `['light', 'medium']` | Cumulative: light + medium |
| `'spicy'` | `[]` (no filter) | All intensities pass |

Default: `'medium'`

### ageMode (String)

| Value | maxAgeRating in ContentFilters | Meaning |
|---|---|---|
| `'standard'` | `AgeRating.teen` (`'teen'`) | Blocks adult-tagged questions |
| `'plus18'` | `AgeRating.adult` (`'adult'`) | Adult questions pass |
| `'plus21'` | `AgeRating.allAges` (`'all'`) | Age check bypassed entirely |

Default: `'standard'`

---

## Mapping: Room Config → ContentFilters

New static factory in `ContentFilters`:

```dart
ContentFilters.fromRoomConfig({
  String intensityLevel = IntensityLevel.medium,
  String ageMode = RoomAgeMode.standard,
})
```

Called in `GameSessionRepository.startGame()` before `_engine.generateQueue()`.

---

## RTDB Session Node (Updated)

```json
rooms/{roomId}/session/
├── sessionQueue: [...]
├── queueIndex: 0
├── generationMeta: {...}
├── intensityLevel: "medium"     ← NEW (Mission 5)
└── ageMode: "standard"          ← NEW (Mission 5)
```

---

## New Files

| File | Purpose |
|---|---|
| *(none)* | All changes extend existing files |

---

## Modified Files

| File | Change |
|---|---|
| `app/lib/features/gameplay/domain/question_enums.dart` | Added `RoomAgeMode` class (`standard`, `plus18`, `plus21`) |
| `app/lib/features/gameplay/domain/content_filters.dart` | Added `fromRoomConfig()` factory method |
| `app/lib/features/gameplay/data/game_session_repository.dart` | Extended `startGame()` with `intensityLevel`/`ageMode` params; builds `ContentFilters`; stores values in RTDB session |
| `app/lib/features/room/presentation/lobby_screen.dart` | Added `selectedIntensityProvider`, `selectedAgeModeProvider`, `_IntensityPicker`, `_AgeModePicker`, `_RoomSummary`, `_SummaryRow`; updated `_onStartGame()` |

---

## UI Additions (Lobby — Host Only)

Controls added between `_RoundCountPicker` and the Start Game button:

1. **`_IntensityPicker`** — 3-button row: `🌿 خفيف` / `🔥 متوسط` / `💀 حار`
2. **`_AgeModePicker`** — 3-button row: `👨‍👩‍👧 للعموم` / `🔞 18+` / `🍺 21+`
3. **`_RoomSummary`** — Compact card showing rounds, categories, intensity, age mode. Displays adult warning (`⚠️`) when `plus18` or `plus21` is selected.

---

## Default / Fallback Behavior

- `startGame()` parameters default to `intensityLevel = 'medium'`, `ageMode = 'standard'`
- Old in-progress sessions (pre-Mission-5) already have their queues generated — `nextRound()` reads from the stored queue and is not affected by these fields
- Missing `intensityLevel`/`ageMode` in RTDB is safe — the fields are written at start time and only read for informational purposes

---

## Known Limitations (Deferred)

- **Non-host visibility:** Other players see local defaults for intensity/age mode, not the host's live selection. Real-time sync would require writing the host's choices to the RTDB room node; deferred to a future mission.
- **plus18 vs plus21 identical effect:** All currently seeded adult content (including `age_21_plus` pack) uses `ageRating: 'adult'`. A future mission may introduce a distinct `'adult_21'` tier in `question_enums.dart` and the seeded data to enable true differentiation.
- **No join-time age gating:** Age mode is self-selected by the host; there is no player-facing verification or warning at join time.

---

## Verification Block

```
[VERIFICATION START]

Implemented:
- Intensity selector added: YES
- Age mode selector added: YES
- Summary block added: YES
- Room config extended: YES
- ContentFilters integration completed: YES
- Legacy fallback handling added: YES
- Knowledge Center updated: YES

Validated:
- Default room flow tested: manual (build and run)
- Intensity filtering tested: manual (select light → verify reduced pool)
- Age mode filtering tested: manual (standard blocks adult, plus18 allows)
- Legacy session compatibility tested: YES (startGame defaults apply; nextRound unaffected)
- Regression on session start checked: YES (engine signature unchanged, filters param was already optional with ContentFilters.defaults)

Files:
- Created:
  - docs/knowledge-center/mission-05-room-setup-v2.md
- Updated:
  - app/lib/features/gameplay/domain/question_enums.dart
  - app/lib/features/gameplay/domain/content_filters.dart
  - app/lib/features/gameplay/data/game_session_repository.dart
  - app/lib/features/room/presentation/lobby_screen.dart

Notes:
- RoomAgeMode enum naming (standard/plus18/plus21) is new; IntensityLevel reused from Mission 3
- standard ageMode maps to AgeRating.teen (blocks adult), not AgeRating.allAges — this intentionally tightens the default; only new sessions are affected
- plus18 and plus21 have identical practical filtering with current data; documented as deferred limitation
- No seed file changes; no gameplay loop changes; no analytics changes

[VERIFICATION END]
```

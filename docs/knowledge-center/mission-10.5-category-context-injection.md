# Mission 10.5 — Category Context Injection

## Objective
Thread `packId` from its source (`Question`) all the way through the session pipeline into gameplay round state and UI rendering, activating the pre-existing category badge placeholder in `ResultCardWidget` and adding a live badge in the gameplay voting screen.

---

## Data Flow

```
Question.packId
  └─> SessionQuestion.packId   (engine DTO mapping)
        └─> RTDB sessionQueue[i].packId  (stored at startGame)
              └─> GameRound.packId       (read in nextRound)
                    ├─> CategoryRegistry.get(packId)?.labelAr
                    │     └─> ResultCardPayload.categoryLabel  (buildResultCard)
                    │           └─> ResultCardWidget category badge (share card)
                    └─> CategoryRegistry.get(packId)          (gameplay_screen)
                          └─> category badge above question text (voting phase)
```

---

## Category Resolution

Always done at the **UI layer** via `CategoryRegistry.get(packId)`:

```dart
final meta = round.packId.isNotEmpty ? CategoryRegistry.get(round.packId) : null;
// meta?.labelAr  → Arabic label (e.g. "أصدقاء")
// meta?.icon     → emoji accent (e.g. "🤝")
// meta == null   → badge hidden (backward compat)
```

**Do not hardcode labels.** All mappings live in `CategoryRegistry._all`.

---

## Backward Compatibility

| Scenario | packId value | Result |
|---|---|---|
| New session with categories | e.g. `"friends"` | Badge shown |
| Old session (pre-Mission 10.5) | `""` (default) | Badge hidden, no crash |
| Unknown packId | e.g. `"deleted_pack"` | `CategoryRegistry.get()` returns null → badge hidden |

All three freezed DTOs use `@Default('')` for `packId`, so old RTDB data deserializes cleanly.

---

## Files Changed

| File | Change |
|---|---|
| `domain/session_question.dart` | Added `@Default('') String packId` field |
| `domain/session_question.freezed.dart` | Regenerated (includes packId) |
| `domain/session_question.g.dart` | Regenerated (packId in fromJson/toJson) |
| `data/session_question_engine.dart` | `packId: q.packId` in DTO mapping |
| `domain/game_round.dart` | Added `@Default('') String packId` field |
| `domain/game_round.freezed.dart` | Regenerated (includes packId) |
| `domain/game_round.g.dart` | Regenerated (packId in fromJson/toJson) |
| `data/game_session_repository.dart` | Read `packId` from queue map, pass to `GameRound` |
| `data/game_session_controller.dart` | Resolve `categoryLabel` via CategoryRegistry in `buildResultCard` |
| `presentation/gameplay_screen.dart` | Category badge (icon + labelAr) above question text in voting phase |

---

## Files NOT Changed (already correct)

- `domain/result_card_payload.dart` — `categoryLabel: String?` was already defined
- `presentation/result_card_widget.dart` — conditional badge render was already implemented
- `domain/category_registry.dart` — registry was already complete

---

## Verification

1. Start a new session with any category (e.g. Friends)
2. **Voting phase** → small pill badge `🤝  أصدقاء` appears above question text
3. After round completes → tap **عرض بطاقة النتيجة** → category badge visible in result card
4. Share the result card → exported PNG includes category badge
5. Test with multiple categories to confirm correct label per category
6. To test backward compat: join a room that was started before this mission (packId absent in queue) → no crash, badge is simply hidden

---

## Verification Block

[VERIFICATION START]

Implemented:
- packId added to SessionQuestion DTO: YES
- packId added to GameRound: YES
- packId threaded through SessionQuestionEngine: YES
- packId read in nextRound() from RTDB queue: YES
- categoryLabel populated in buildResultCard: YES
- category badge in gameplay voting screen: YES
- Knowledge Center updated: YES

Validated:
- Category visible in gameplay voting phase: YES/NO
- Category visible in share card: YES/NO
- No crash with old sessions (packId missing): YES/NO

Files Created:
- docs/knowledge-center/mission-10.5-category-context-injection.md

Files Updated:
- app/lib/features/gameplay/domain/session_question.dart
- app/lib/features/gameplay/domain/session_question.freezed.dart
- app/lib/features/gameplay/domain/session_question.g.dart
- app/lib/features/gameplay/data/session_question_engine.dart
- app/lib/features/gameplay/domain/game_round.dart
- app/lib/features/gameplay/domain/game_round.freezed.dart
- app/lib/features/gameplay/domain/game_round.g.dart
- app/lib/features/gameplay/data/game_session_repository.dart
- app/lib/features/gameplay/data/game_session_controller.dart
- app/lib/features/gameplay/presentation/gameplay_screen.dart

Notes:
- build_runner's json_serializable generator didn't include the new @Default('') packId
  field in the .g.dart output (known issue with this version); manually updated g.dart
  files to match the pattern established by textEn.

[VERIFICATION END]

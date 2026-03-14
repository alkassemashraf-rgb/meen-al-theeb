# Mission 9 — Question Pack & Content Engine

## Objective

Surface pack selection in the Lobby so the host can choose which question pack powers the session. Add the `QuestionPack` domain model and `QuestionPackRepository`. Pack exhaustion handling and question deduplication were already implemented in previous missions — Mission 9 only adds the model layer and the selection UI.

---

## Scope

- `QuestionPack` Freezed domain model (Firestore-backed)
- `QuestionPackRepository` with `fetchAllPacks()`
- `allPacksProvider` — cached `FutureProvider` consumed by the lobby
- `selectedPackProvider` — `StateProvider.family` for host's in-lobby selection
- Pack picker UI in `LobbyScreen` (host-only, above "Start Game" button)
- Non-host observer text while host selects
- `_onStartGame` wired to pass selected `packId` to `startGame()`
- Knowledge Center updated (4 docs)

### Scope Out

- Payment / premium gate enforcement
- Pack purchases or ads
- Analytics
- Per-pack analytics or tracking
- Any change to the gameplay loop, `GameplayService`, or `GameSessionRepository`

---

## Pre-conditions (Already Built — No Changes Required)

| What | File | How |
|---|---|---|
| Question deduplication | `game_session_repository.dart:nextRound()` | `fetchRandomQuestion(excludedIds: usedQuestionIds)` |
| Pack exhaustion → session end | `game_session_repository.dart:nextRound()` | `null` question → `room.status = 'ended'` |
| `packId` bound to session | `game_session_repository.dart:startGame()` | `session.packId = packId ?? getDefaultPackId()` |
| Default pack fallback | `question_repository.dart:getDefaultPackId()` | First Firestore pack or `'default_pack'` |

`GameSessionRepository.startGame(roomId, {String? packId})` already accepted an optional `packId`. No changes were needed there.

---

## New Files

### `app/lib/features/gameplay/domain/question_pack.dart`

Freezed model. Serialized to/from Firestore `questionPacks/{packId}` documents.

| Field | Type | Default | Description |
|---|---|---|---|
| `packId` | `String` | required | Firestore document ID |
| `name` | `String` | required | Display name (e.g. "أصدقاء") |
| `description` | `String` | `''` | Short pack description |
| `language` | `String` | `'ar'` | `ar` / `en` / `mixed` |
| `questionCount` | `int` | `0` | Pre-computed in Firestore |
| `icon` | `String` | `'🐺'` | Emoji icon |
| `isPremium` | `bool` | `false` | Premium gate (not enforced yet) |
| `createdAt` | `DateTime?` | `null` | Optional Firestore timestamp |

Requires `build_runner` to generate `.freezed.dart` / `.g.dart`.

### `app/lib/features/gameplay/data/question_pack_repository.dart`

```
QuestionPackRepository.fetchAllPacks()
  → Firestore.collection('questionPacks').orderBy('name').get()
  → maps docs to List<QuestionPack>

allPacksProvider (FutureProvider<List<QuestionPack>>)
  → cached by Riverpod; consumed by _PackPicker in LobbyScreen

selectedPackProvider (StateProvider.family<String?, String>)
  → scoped by roomId
  → null = no explicit selection → startGame falls back to getDefaultPackId()
```

---

## Modified Files

### `app/lib/features/room/presentation/lobby_screen.dart`

**Added:** `_PackPicker` widget (host-only section above Start button).

**`_PackPicker` layout:**

- Label: `"اختر مجموعة الأسئلة"`
- Horizontal `ListView` of `_PackCard` widgets (one per pack)
- Each `_PackCard`: icon emoji + name + question count
- Selected card: `AppColors.primary` border (2 px) + shadow glow
- Loading state: `CircularProgressIndicator`
- Error state: `SizedBox.shrink()` — silent, `startGame` falls back to default
- Empty packs: `SizedBox.shrink()` — no picker shown

**Non-host:** `"المضيف يختار مجموعة الأسئلة"` static text.

**`_onStartGame` change:**

```dart
final packId = ref.read(selectedPackProvider(widget.roomId));
await ref.read(gameSessionRepositoryProvider)
    .startGame(widget.roomId, packId: packId);
```

---

## Architecture Notes

- Pack selection is **lobby-only, host-only**. Non-hosts see a status line.
- `selectedPackProvider` uses `.family` scoped by `roomId` — consistent with `roomStreamProvider`, `gameSessionControllerProvider`, and `sessionSummaryProvider` patterns.
- `isPremium` is modelled for future monetization but has no enforcement logic in Mission 9.
- `questionCount` is a pre-computed Firestore field; not dynamically counted from the `questions` collection.
- No new RTDB nodes. No new routes. No new packages.
- **Default fallback:** `getDefaultPackId()` uses `.collection('questionPacks').limit(1)` with no `orderBy` clause — Firestore returns the document with the lexicographically smallest document ID. To make this deterministic, use document IDs such as `friends`, `spicy` so `friends` is always returned first. This is the MVP "Friends default" guarantee — it depends on the seed IDs, not on any code-level ordering.

---

## Data Flow

```
LobbyScreen mounts (host)
  → ref.watch(allPacksProvider) → Firestore questionPacks (ordered by name)
  → _PackPicker renders horizontal RoundedCard tiles
  → host taps card → selectedPackProvider(roomId).notifier.state = packId

Host taps "ابدأ اللعبة"
  → _onStartGame reads selectedPackProvider(roomId) → packId or null
  → GameSessionRepository.startGame(roomId, packId: packId)
      → null → getDefaultPackId() → first Firestore pack
      → GameSession(packId: targetPackId) written to RTDB /rooms/{roomId}/session
      → nextRound() → fetchRandomQuestion(packId, excludedIds: []) → round begins

During session
  → nextRound() always uses session.packId; usedQuestionIds grows each round
  → questions never repeat within the session

Pack exhausted
  → nextRound() → fetchRandomQuestion returns null
  → room.status = 'ended' → all clients navigate to /summary/:roomId (Mission 8 flow)
```

---

## Firestore Seed Requirements

Use short lowercase document IDs. The `friends` ID is lexicographically earlier than `spicy`, which makes `getDefaultPackId()` deterministically return the Friends pack when no pack is selected.

**`questionPacks` collection** (minimum 2 documents):

```text
questionPacks/friends
  name:          "أصدقاء"
  description:   "أسئلة خفيفة مناسبة للأصدقاء"
  language:      "ar"
  questionCount: 20
  icon:          "👫"
  isPremium:     false
  createdAt:     <Timestamp>

questionPacks/spicy
  name:          "جريء"
  description:   "أسئلة جريئة للجلسات الناضجة"
  language:      "ar"
  questionCount: 15
  icon:          "🌶️"
  isPremium:     false
  createdAt:     <Timestamp>
```

**`questions` collection** (minimum 3 per pack — needed to clear the 3-vote `insufficient_votes` threshold):

```text
questions/q_friends_001
  packId:  "friends"
  textAr:  "من أكثر شخص هنا يحب النوم؟"
  textEn:  "Who loves to sleep the most?"

questions/q_friends_002
  packId:  "friends"
  textAr:  "من الأكثر تنظيماً في المجموعة؟"
  textEn:  "Who is the most organized?"

questions/q_friends_003
  packId:  "friends"
  textAr:  "من يأكل أكثر من الجميع؟"
  textEn:  "Who eats the most?"

questions/q_spicy_001
  packId:  "spicy"
  textAr:  "من أكثر شخص هنا يكذب؟"
  textEn:  "Who lies the most?"
```

**Required Firestore index:** The `questions` query uses `.where('packId', isEqualTo: ...)`. Firestore will generate a direct link to create the composite index on the first query run if it does not already exist.

---

## Acceptance Criteria

- Packs load from Firestore and render in the lobby picker (host only)
- Tapping a card highlights it with `AppColors.primary` border
- No pack tapped → `startGame` uses `getDefaultPackId()` (first Firestore pack)
- Pack selected → `GameSession.packId` in RTDB matches the chosen pack
- Questions during gameplay belong to the selected pack (`packId` matches)
- Questions never repeat within a session (`usedQuestionIds` guard)
- Exhausting all questions ends the session gracefully and navigates to summary
- Non-host players see static text, not the picker
- `isPremium` packs display normally (no gate enforcement in Mission 9)

---

## Build Notes

Run after adding files:

```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

# Mission 8 — Share Export & End-of-Session Summary

## Objective

Complete the session wrap-up flow: route all players to a real `SessionSummaryScreen` after the game ends, aggregate round history into per-player stats, wire the `ResultCardWidget` share button to real image capture and native share-sheet, and defer room node cleanup so the summary screen can read RTDB data.

---

## Scope

- End-of-session summary screen with round recaps and player stats
- `SessionSummaryBuilder` — one-shot RTDB aggregation layer
- Real image export via `RepaintBoundary.toImage()` (no external screenshot package)
- Native share sheet via `share_plus`
- `ResultCardWidget` converted from `StatelessWidget` → `StatefulWidget` with real share
- Navigation change: session-end now routes to `/summary/:roomId` instead of `/home`
- New route registered in `app_router.dart`
- Knowledge Center updated (5 docs)

---

## New Packages

| Package | Version | Purpose |
|---|---|---|
| `share_plus` | `^10.0.0` | Native iOS/Android share sheet |
| `path_provider` | `^2.1.0` | Temp directory for PNG write before sharing |

No screenshot/capture package added. Flutter's built-in `RenderRepaintBoundary` is sufficient.

---

## New Files

### `app/lib/features/gameplay/domain/session_summary.dart`

Plain Dart classes — never serialized, not Freezed.

**`RoundRecap`**

| Field | Type | Description |
|---|---|---|
| `roundNumber` | `int` | 1-indexed position in session |
| `roundId` | `String` | Matches RTDB key |
| `questionAr` | `String` | Arabic question text |
| `resultType` | `String` | `normal` / `tie` / `insufficient_votes` |
| `winnerDisplayNames` | `List<String>` | Resolved from player roster |
| `voteCounts` | `Map<String, int>` | `playerId → count` |
| `totalValidVotes` | `int` | |

Getters: `wasSkipped` (`resultType == 'insufficient_votes'`), `wasTie` (`resultType == 'tie'`).

**`SessionSummary`**

| Field | Type | Description |
|---|---|---|
| `rounds` | `List<RoundRecap>` | Ordered by `completedAt` |
| `totalVotesReceived` | `Map<String, int>` | `playerId → cumulative votes` |
| `playerDisplayNames` | `Map<String, String>` | `playerId → displayName` |
| `totalRounds` | `int` | |
| `skippedRounds` | `int` | `resultType == 'insufficient_votes'` |
| `tieRounds` | `int` | `resultType == 'tie'` |
| `mostVotedPlayerId` | `String?` | Player with highest cumulative votes |
| `mostVotedCount` | `int` | |

Getters: `mostVotedDisplayName`, `hasAnyRounds`.

---

### `app/lib/features/gameplay/data/session_summary_builder.dart`

Static utility. One-shot RTDB read. No Riverpod provider on the class itself.

```
SessionSummaryBuilder.build(roomId, db)
  → db.ref('rooms/$roomId').get()
  → parse players → Map<String, String>
  → parse roundHistory → List<RoundHistoryItem>, sort by completedAt
  → aggregate totalVotesReceived, skippedRounds, tieRounds, mostVotedPlayerId
  → build List<RoundRecap> with resolved winner names
  → return SessionSummary
```

Resilient: malformed history entries are skipped (try/catch per entry). Returns `null` if room node missing.

Riverpod entry point:

```dart
final sessionSummaryProvider =
    FutureProvider.family<SessionSummary?, String>((ref, roomId) =>
        SessionSummaryBuilder.build(roomId, FirebaseDatabase.instance));
```

---

### `app/lib/features/gameplay/presentation/session_summary_screen.dart`

`ConsumerWidget` — receives `roomId` as constructor param.

**Layout (top → bottom):**

1. `AppBar` — "ملخص الجلسة"
2. `_StatsBar` — total rounds / ties / skipped
3. `_MostVotedCard` — highlighted if `summary.mostVotedPlayerId != null`
4. `ListView` of `_RoundRecapCard` items — question text, `_ResultBadge`, winner names, vote count
5. Sticky bottom `_HomeButton` → `context.go('/home')`

**States:**

- Loading: `CircularProgressIndicator`
- Error: error message + retry prompt
- Empty (`!summary.hasAnyRounds`): "لا توجد جولات مكتملة"
- Data: full layout above

**Data source:** `ref.watch(sessionSummaryProvider(roomId))`

---

### `app/lib/services/share/share_service.dart`

Static utility. No Riverpod.

```
ShareService.shareWidget({
  required GlobalKey repaintBoundaryKey,
  String shareText,
  double pixelRatio = 3.0,
  String fileName,
})
  → Future.delayed(20ms)           // ensure paint is flushed
  → boundary.toImage(pixelRatio)   // RenderRepaintBoundary
  → image.toByteData(png)
  → File(temp/$fileName).writeAsBytesSync(bytes)
  → Share.shareXFiles([XFile(file.path)])
```

Also exposes `ShareService.shareText(String text)` for plain text fallback.

---

## Modified Files

### `app/pubspec.yaml`

Added:

```yaml
share_plus: ^10.0.0
path_provider: ^2.1.0
```

### `app/lib/features/gameplay/presentation/result_card_widget.dart`

- Converted `ResultCardWidget`: `StatelessWidget` → `StatefulWidget` (`_ResultCardWidgetState`)
- Added `final _repaintBoundaryKey = GlobalKey()` in state
- Added `bool _isSharing = false` in state
- Outermost gradient `Container` wrapped in `RepaintBoundary(key: _repaintBoundaryKey, ...)`
- `_onShareRequested()` now calls `ShareService.shareWidget(repaintBoundaryKey: _repaintBoundaryKey)` with guard (`_isSharing`) and error SnackBar
- Share button shows `CircularProgressIndicator` while `_isSharing`

### `app/lib/features/gameplay/presentation/gameplay_screen.dart`

Single navigation change in the room-ended handler:

```dart
// Before (Mission 7):
if (mounted) context.go('/home');
// After (Mission 8):
if (mounted) context.go('/summary/${widget.roomId}');
```

### `app/lib/core/routing/app_router.dart`

Added import for `SessionSummaryScreen` and one new route:

```dart
GoRoute(
  path: '/summary/:roomId',
  builder: (context, state) =>
      SessionSummaryScreen(roomId: state.pathParameters['roomId']!),
),
```

---

## Data Flow

```
Session ends
  → room.status == 'ended' detected in GameplayScreen stream
  → context.go('/summary/:roomId')
  → GameplayScreen.dispose() → GameplayService.stopWatching()

SessionSummaryScreen mounts
  → sessionSummaryProvider(roomId) fires
  → SessionSummaryBuilder reads /rooms/{roomId} (one-shot RTDB)
  → Parses roundHistory + players → SessionSummary
  → Screen renders stats bar + round list

User taps "مشاركة النتيجة" in ResultCardWidget (bottom sheet)
  → _onShareRequested() → ShareService.shareWidget()
  → RepaintBoundary.toImage() → PNG bytes
  → File written to temp dir via path_provider
  → Share.shareXFiles() → native share sheet
```

---

## Key Decisions

- **Room node not deleted on session end** — `SessionSummaryScreen` reads `roundHistory` and `players` after the room is ended. Deleting on end would make the summary impossible. Cleanup deferred to Cloud Function / TTL (Mission 9+). See `decision-log.md`.
- **No screenshot package** — Flutter's `RenderRepaintBoundary.toImage()` is sufficient. Avoids a heavy dependency.
- **`share_plus` + `path_provider` only** — Two minimal packages; no other new dependencies.
- **`SessionSummaryBuilder` is a static utility** — Never needs to react to state; a `FutureProvider` wrapper is enough.
- **Plain Dart models for summary** — `RoundRecap` and `SessionSummary` are never serialized. No Freezed overhead needed.

---

## Events

| Event | Trigger | Owner | Resulting State |
|---|---|---|---|
| `SessionSummaryBuilt` | `sessionSummaryProvider` completes | `SessionSummaryBuilder` | `SessionSummary` available in UI |
| `ShareImageGenerated` | `boundary.toImage()` completes | `ShareService` | PNG bytes in memory |
| `ShareRequested` | `Share.shareXFiles()` called | `ShareService` | Native share sheet opens |
| `SessionCleanupComplete` | `GameplayScreen.dispose()` fires | `GameplayService.stopWatching()` | All timers and subscriptions stopped |

---

## Acceptance Criteria

- All players (host + non-host) navigate to `SessionSummaryScreen` when session ends
- Summary screen shows correct round count, tie count, skipped count
- Most-voted player is highlighted (if applicable)
- Each `RoundRecapCard` shows question, result badge, winner names, and vote total
- Empty state shown if session ended with 0 completed rounds
- "الصفحة الرئيسية" navigates to `/home`
- Tapping "مشاركة النتيجة" on a result card opens native share sheet with PNG image
- No timer or stream event fires from the old gameplay session after navigating to summary

---

## Build Notes

`RoundHistoryItem` (added in Mission 7) uses `@freezed`. Before building, run:

```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

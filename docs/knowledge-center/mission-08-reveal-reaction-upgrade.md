# Mission 08 — Reveal & Reaction Upgrade (Emotional Payoff Layer)

## Summary

Mission 8 upgrades the emotional impact of two key gameplay moments: the winner reveal and
real-time emoji reactions. The changes are confined to the data and presentation layers — no
schema changes to the Freezed domain models, no new Firebase collections.

---

## 1. Reaction System Overhaul

### RTDB Path Change

| Before | After |
|---|---|
| `rooms/{roomId}/reactions` (push-based, never cleared) | `rooms/{roomId}/currentRound/reactions/{playerId}` (keyed, auto-cleared) |

**Why this matters:**
- The old path accumulated reactions across all rounds. There was no per-round lifecycle.
- The new path lives under `currentRound`, which `GameSessionController.advanceToNextRound()`
  overwrites entirely — reactions are automatically cleared when the round advances.
- Keying by `playerId` instead of `push()` enforces one reaction per player per round.
  A second tap simply overwrites the player's previous reaction.

### One Reaction Per Player

Achieved structurally: writing to a fixed key (`/reactions/{playerId}`) means the second write
replaces the first. No client-side guard is required.

### RTDB Data Shape

```
rooms/{roomId}/currentRound/reactions/{playerId}: {
  emoji: "😂",
  timestamp: "2026-03-17T12:00:00.000"
}
```

---

## 2. Files Modified

### `app/lib/features/gameplay/data/game_session_repository.dart`

- **`sendReaction`** — rewrote to write to `currentRound/reactions/{playerId}` (overwrite):
  ```dart
  Future<void> sendReaction({required String roomId, required String playerId, required String emoji}) async {
    await roomRef(roomId).child('currentRound/reactions/$playerId')
        .set({'emoji': emoji, 'timestamp': DateTime.now().toIso8601String()});
  }
  ```
- **`observeReactionMap`** — replaced `observeReactions(Stream<Reaction>)` with a map-based stream:
  ```dart
  Stream<Map<String, String>> observeReactionMap(String roomId) {
    return roomRef(roomId).child('currentRound/reactions').onValue.map((event) {
      // Returns playerId → emoji for all active reactions in the round
    });
  }
  ```
  Returns `Map<String, String>` (playerId → emoji). The full map is emitted on every RTDB change,
  making count derivation trivial on the client.

### `app/lib/features/gameplay/data/gameplay_service.dart`

- Removed `reaction.dart` import (no longer needed).
- `observeReactions` renamed to `observeReactionMap`, return type changed to `Stream<Map<String,String>>`.

### `app/lib/features/gameplay/presentation/gameplay_screen.dart`

#### State fields

```dart
StreamSubscription<Map<String, String>>? _reactionSub;
final Map<String, String> _reactionMap = {};  // playerId → emoji (current round)
```

`_reactionMap` doubles as the source of truth for count badge display.

#### `_startReactionListener` — map-diff approach

Instead of listening to a stream of individual `Reaction` events, the listener receives the full
`Map<String,String>` for the current round on every update. A diff against `_reactionMap` detects
new or changed reactions and spawns the floating bubble + avatar emotion overlay for each.

```dart
void _startReactionListener() {
  _reactionSub = _gameplayService.observeReactionMap(widget.roomId).listen((newMap) {
    newMap.forEach((playerId, emoji) {
      if (_reactionMap[playerId] != emoji) {
        // New or changed reaction → spawn bubble, update emotion overlay
      }
    });
    setState(() { _reactionMap.clear(); _reactionMap.addAll(newMap); });
  });
}
```

On round advance, RTDB emits an empty map → `_reactionMap` clears → count badges reset to zero.

#### `_buildReactionPicker` — new emoji set + count badges

Emoji set updated from `['🐺', '😂', '🕵️', '😳', '🤔', '🔥']` to `['😂', '😱', '🔥', '💀', '👀']`.

Count badges are derived from `_reactionMap` without a separate stream:
```dart
final counts = <String, int>{};
for (final emoji in _reactionMap.values) {
  counts[emoji] = (counts[emoji] ?? 0) + 1;
}
```
Each emoji button shows a small red pill badge (`Container` + `BorderRadius.circular(10)`)
positioned at `top: -6, right: -10` when `count > 0`.

#### `_buildRevealContent` — winner pop animation + winner glow

Each winner card is wrapped with `_RevealPopAnimation`:
```dart
_RevealPopAnimation(
  child: Column(
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.6), blurRadius: 28, spreadRadius: 6)],
        ),
        child: AvatarWidget(..., isWinner: true),
      ),
      ...
    ],
  ),
)
```

The `Container` wrapping `AvatarWidget` has a circular `BoxShadow` in `AppColors.accent` at 60% opacity,
creating the winner glow effect without modifying `AvatarWidget` itself.

#### `_RevealPopAnimation` (new widget)

```dart
class _RevealPopAnimation extends StatelessWidget {
  final Widget child;
  const _RevealPopAnimation({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, scale, _) => Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
```

- Starts at 40% scale, bounces to 100% via `Curves.elasticOut`
- `TweenAnimationBuilder` re-runs whenever the widget is inserted into the tree (phase flip triggers it)
- The elastic overshoot gives the winner card a "pop" quality

---

## 3. Reaction Lifecycle Summary

| Event | Effect on `currentRound/reactions` |
|---|---|
| Player taps emoji | `reactions/{playerId}` written (overwrites previous if any) |
| Player taps different emoji | `reactions/{playerId}` overwritten with new emoji |
| Host advances to next round | Entire `currentRound` node overwritten → reactions cleared |
| Host ends session | Room status → `ended` → reactions irrelevant |

---

## 4. Known Limitations

- **Offline tap**: If the player is briefly offline, `sendReaction` throws — the exception is
  silently swallowed (no UI feedback). This is acceptable for MVP.
- **Late joiners**: A player joining mid-round will see whatever reactions are in `currentRound`
  at join time. This is correct and expected.
- **Reaction count badge reset**: Because `_reactionMap` is an in-memory local state, it resets on
  widget rebuild from scratch (e.g., hot restart). In production (always release mode) this is not
  an issue.

---

## 5. Test Checklist

- [ ] Tapping an emoji sends a reaction visible to all players (floating bubble appears)
- [ ] Tapping a second emoji replaces the first (count badge decrements for old, increments for new)
- [ ] Count badge shows correct total per emoji across all players
- [ ] Badges reset to zero on round advance
- [ ] Winner reveal shows pop animation (elastic bounce on phase flip)
- [ ] Winner avatar has visible glow (accent colour)
- [ ] Tie result shows multiple winners, each with pop + glow
- [ ] `insufficient_votes` result shows no winner cards (no pop/glow)

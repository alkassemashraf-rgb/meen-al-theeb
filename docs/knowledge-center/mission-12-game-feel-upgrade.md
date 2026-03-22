# Mission 12 — Game Feel Upgrade: Micro-Interactions & Motion Polish

## Overview

Mission 12 adds lightweight micro-interactions and motion polish to the gameplay screen without changing any game logic, layouts, or introducing heavy animation systems. All changes are confined to `gameplay_screen.dart`.

---

## Animation Timing Rules

| Interaction | Duration | Curve | Notes |
|---|---|---|---|
| Player card press scale | 80ms | easeOut | Scale 1.0 → 0.90 on press, back on release |
| Emoji picker press pop | 80ms | easeOut | Scale 1.0 → 1.35 on press, back on release |
| Checkmark pop-in | 250ms | elasticOut | Scale 0.0 → 1.0 when vote registered |
| Round content fade | 300ms | linear | AnimatedSwitcher FadeTransition keyed by roundId |
| Reveal delay hold | 300ms | — | Client-side gap before flip fires |
| Flip card (voting↔reveal) | 500ms | — | Existing AnimatedSwitcher rotationY (unchanged) |
| Winner pop | 450ms | elasticOut | Existing TweenAnimationBuilder (unchanged) |
| Confetti burst | 1500ms | — | Existing (unchanged) |
| Waiting dots cycle | 500ms interval | — | Timer-based, no AnimationController needed |

**General rules:**
- Tap feedback: 80ms (imperceptible latency, feels instant)
- State feedback (checkmark): 250ms with elasticOut for satisfying bounce
- Content transitions: 300ms with fade for smooth, non-jarring changes
- Never block UI updates or RTDB sync with animations

---

## Interaction Patterns

### 1. Press Scale (Player Cards & Emoji Buttons)

Pattern: `onTapDown` / `onTapUp` / `onTapCancel` + `AnimatedScale`

- No `AnimationController` needed
- `onTapDown` sets pressed state → immediate scale change
- `onTapUp` clears pressed state AND fires action → scale returns
- `onTapCancel` clears pressed state without firing action

```dart
GestureDetector(
  onTapDown: (_) => setState(() => _pressed[id] = true),
  onTapUp: (_) {
    setState(() => _pressed[id] = false);
    _doAction(id);
  },
  onTapCancel: () => setState(() => _pressed[id] = false),
  child: AnimatedScale(
    scale: _pressed[id] == true ? 0.90 : 1.0,
    duration: const Duration(milliseconds: 80),
    curve: Curves.easeOut,
    child: // content
  ),
)
```

**Player cards**: scale DOWN (0.90) — physical "button press" feel
**Emoji buttons**: scale UP (1.35) — "launch" feel on send

### 2. Checkmark Pop Animation

`AnimatedScale` with `Curves.elasticOut` gives the checkmark a bouncy, satisfying pop-in.

```dart
AnimatedScale(
  scale: amITarget ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 250),
  curve: Curves.elasticOut,
  child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
)
```

The icon is always in the widget tree (scale 0 = invisible). When the vote registers, `amITarget` becomes true and the icon bounces in. This prevents the layout from shifting.

### 3. Waiting Indicator (Timer-Based Dots)

For looping text animations, a `Timer.periodic` is simpler and more predictable than an `AnimationController`:

```dart
Timer? _dotsTimer;
int _dotsCount = 0;  // 0, 1, 2

void _startDotsTimer() {
  if (_dotsTimer != null) return;
  _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
    if (mounted) setState(() => _dotsCount = (_dotsCount + 1) % 3);
  });
}

void _stopDotsTimer() {
  _dotsTimer?.cancel();
  _dotsTimer = null;
  _dotsCount = 0;
}
```

Usage: `'ننتظر الآخرين${'.' * (_dotsCount + 1)}'` → cycles between `.`, `..`, `...`

**When to show**: `myCurrentVote != null && !allVoted` (voted but others haven't)

**Important**: Call `_startDotsTimer()` / `_stopDotsTimer()` from `build()` (inside `_buildVotingPhase`), not from async callbacks. This avoids race conditions with state.

### 4. Reveal Transition Delay

**Problem**: When `vote_locked` transitions to `result_ready`, the flip animation could fire immediately, feeling abrupt.

**Solution**: A two-flag pattern (`_revealScheduled`, `_revealReady`) holds the loading state for 300ms before allowing the flip:

```dart
// In build(), after computing isReveal:
if (isReveal && !_revealScheduled) {
  _revealScheduled = true;
  Future.delayed(const Duration(milliseconds: 300), () {
    if (mounted) setState(() => _revealReady = true);
  });
} else if (!isReveal) {
  _revealReady = false;
  _revealScheduled = false;
}

final showReveal = isReveal && _revealReady;
final showPreparing = round.phase == 'preparing' ||
    round.phase == 'vote_locked' ||
    (isReveal && !_revealReady);
```

Effect: The loading spinner shows for an extra 300ms after all votes are in, creating anticipation before the flip fires.

**Do NOT** use this pattern for delays longer than ~500ms — it creates a perceived lag.

### 5. Round Content Fade

`AnimatedSwitcher` keyed by `round.roundId` wraps the question card + instruction text + player grid:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
  child: _buildVotingRoundBody(
    round, roomAsync, user,
    key: ValueKey(round.roundId),
  ),
)
```

This is separate from the outer `_buildFlipTransition` (voting↔reveal). The outer flip uses `ValueKey(false/true)`. The inner fade uses `ValueKey(round.roundId)`. They do not interfere.

---

## Performance Considerations

1. **RepaintBoundary**: The confetti burst and floating reactions are already wrapped in `RepaintBoundary` — no change needed.
2. **AnimatedScale**: Uses the Flutter compositor's layer promotion — no Dart-side per-frame work.
3. **Timer vs AnimationController**: For simple looping text, `Timer.periodic` avoids the overhead of vsync-bound AnimationController.
4. **setState frequency**: The dots timer fires at 500ms — negligible rebuild cost for a single Text widget.
5. **No animation blocks logic**: All state writes to RTDB happen in `onTapUp`, not in animation callbacks.

---

## Files Modified

- `app/lib/features/gameplay/presentation/gameplay_screen.dart` — all changes in this single file

## New Classes / Methods

| Name | Type | Purpose |
|---|---|---|
| `_buildVotingRoundBody()` | private method | Extracted from `_buildVotingPhase`; contains question card + instruction + grid; keyed by roundId for fade |
| `_startDotsTimer()` | private method | Starts 500ms periodic timer for waiting dots |
| `_stopDotsTimer()` | private method | Cancels timer and resets dots count |

---

## Verification Checklist

- [ ] Player card tap → brief scale-down (0.90) then snap back
- [ ] Vote registered → green checkmark bounces in (elasticOut)
- [ ] After voting, others still voting → "ننتظر الآخرين." cycles to ".."/"..."
- [ ] Waiting dots stop when all voted or when revealing
- [ ] All votes in → 300ms loading hold → flip to reveal (not immediate)
- [ ] Emoji tap → scale-up pop (1.35) then returns
- [ ] New round start → question + grid fade (not hard jump)
- [ ] `vote_locked` phase shows "جاري حساب النتائج..." (not raw string)
- [ ] No frame drops or jank during any animation
- [ ] Full round cycle (vote → reveal → next round) completes without regression

[VERIFICATION START]

Implemented:
- Voting interaction feedback added: YES
- Waiting state added: YES
- Reveal transition improved: YES
- Reaction animation added: YES
- Round transition improved: YES
- Knowledge Center updated: YES

Validated:
- Voting responsiveness tested: NO
- Waiting state tested: NO
- Reveal transition tested: NO
- Reaction feedback tested: NO
- No performance issues observed: NO

Files:
- Created: docs/knowledge-center/mission-12-game-feel-upgrade.md
- Updated: app/lib/features/gameplay/presentation/gameplay_screen.dart

Notes:
- All animations use simple Flutter tools (AnimatedScale, AnimatedSwitcher, FadeTransition, TweenAnimationBuilder)
- No AnimationController introduced (dots use Timer.periodic instead)
- No layout changes
- No game logic changes

[VERIFICATION END]

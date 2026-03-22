# Mission 13.2 — Gameplay Tension & Telegram-Style Celebration System

## Overview

This mission transforms gameplay from a linear flow into a high-engagement social experience by introducing:
1. Staged prompt delivery (hook → full reveal)
2. Forced thinking pause before voting opens
3. Cinematic reveal with contextual celebration text
4. Telegram-style animated emoji burst reactions

All changes are **purely presentational** — no RTDB schema changes, no voting logic changes.

---

## Gameplay Tension Model

### Before (Mission 12)
```
RTDB: preparing → voting (question instantly visible, grid immediately tappable) → vote_locked → result_ready (flip + confetti)
```

### After (Mission 13.2)
```
RTDB: preparing → voting → vote_locked → result_ready

UI (within 'voting' phase):
  intro (600ms)         → hook text "لا تلفّون…"
  promptReveal (300ms)  → question card fades/scales in
  thinkingDelay (2500ms)→ "فكّر زين…" + spinner, grid hidden
  votingOpen            → grid appears, voting enabled

UI (within 'result_ready' phase):
  (300ms delay)         → flip transition
  reveal                → winner pop + confetti burst
  +900ms                → contextual celebration text fades in
```

---

## UI State Machine

### Enum
```dart
enum _VotingUIState { intro, promptReveal, thinkingDelay, votingOpen }
```

### State Variables (in `_GameplayScreenState`)
| Variable | Type | Purpose |
|---|---|---|
| `_votingUIState` | `_VotingUIState` | Current presentation state |
| `_sequencedRoundId` | `String?` | Guards against re-running sequence on rebuild |
| `_introTimer` | `Timer?` | Hook → reveal → thinking transitions |
| `_thinkingTimer` | `Timer?` | Thinking → voting open transition |
| `_showCelebrationText` | `bool` | Whether to show post-reveal line |
| `_celebrationScheduled` | `bool` | Prevents scheduling twice |
| `_celebrationTimer` | `Timer?` | 900ms delay before text appears |

### Timing
| Stage | Duration | Notes |
|---|---|---|
| Hook text | 600ms | "لا تلفّون…" in large text, no card |
| Prompt reveal animation | 300ms | Scale 0.92→1.0 + opacity 0→1 |
| Thinking delay | 2500ms | "فكّر زين…" + subtle spinner |
| **Total before voting** | ~3.4s | Within 30s voting window |
| Reveal flip delay | 300ms | Existing build-up moment |
| Celebration text delay | 900ms | After `_revealReady` is true |

### Important: Backend State Is Never Blocked
The `_startVotingSequence()` guard (`_sequencedRoundId == roundId`) ensures the sequence runs exactly once per round and never interferes with RTDB writes. The countdown timer and host `watchGameplay()` run independently.

---

## Celebration Text System

### Trigger
- Fires 900ms after `_revealReady` becomes true
- Only shown if `result.resultType != 'insufficient_votes'`

### Selection Logic (`_getCelebrationLine`)
| Condition | Text |
|---|---|
| Tie result | "ما قدروا يتفقون على واحد… كلهم مشتبه بهم! 🕵️" |
| Winner got ≥60% of votes | "واضح الموضوع… كان معروف من البداية 👀" |
| Otherwise (varied) | "ما كانت مفاجأة كبيرة…" / "الجماعة عارفينك!" / "تفاهم الكل عليك 😅" |

The varied lines are selected deterministically from `winningPlayerIds.hashCode` to be consistent per reveal.

---

## Emoji Reaction System Design

### Architecture
- RTDB path: `/rooms/{roomId}/currentRound/reactions/{playerId}`
- Format: `{ emoji: string, timestamp: ISO8601 }`
- One reaction per player (overwrite semantics)
- Auto-cleared on new round (host writes new `currentRound`)

### Sync Model
Each client:
1. Observes `observeReactionMap()` stream
2. Diffs new map against `_reactionMap` to detect changes
3. Spawns `AnimatedReaction` locally for each new/changed reaction
4. No animation sync — physics are local only

### Performance Cap
- Max 10 concurrent `AnimatedReaction` widgets
- If cap reached, new reactions are skipped (avatar emotion overlay still updates)
- Auto-disposed after 1200ms (animation duration)

---

## Telegram-Style Burst Animation (`AnimatedReaction`)

### Duration
**1200ms** (down from 2000ms — snappier, more impactful)

### Phases (single `AnimationController`)
| Phase | Timeline | Description |
|---|---|---|
| Pop | 0–25% (300ms) | Scale 0.3→1.3 with `Curves.elasticOut` |
| Settle | 25–40% (180ms) | Scale 1.3→1.0 with `Curves.easeInOut` |
| Burst out | 0–30% (360ms) | 5 mini particles radiate to 55px, fade 1→0 |
| Hold + drift | 0–100% | Y-offset 0→-220px, easeOut |
| Wobble | 0–100% | `sin(value × π × 3) × 0.14` radians rotation |
| Fade | 70–100% (360ms) | Opacity 1→0 |

### Burst Particle Layout
- 5 particles at 72° intervals (0°, 72°, 144°, 216°, 288°)
- Same emoji at fontSize 14 (mini)
- Positioned relative to center of main emoji SizedBox
- All driven by same controller's `Interval(0.0, 0.30)` range

### Random Drift
- X offset: ±60px, seeded by `reaction.id.hashCode`
- Consistent per reaction instance (not re-randomized on rebuild)

---

## Animation Timing Standards (This Feature)

| Animation | Duration | Curve |
|---|---|---|
| Hook text appear | instant (already in tree) | — |
| Prompt card scale-in | 300ms | `Curves.easeOut` |
| Thinking text fade | 200ms | `AnimatedOpacity` |
| Reaction pop | 300ms (25% of 1200ms) | `Curves.elasticOut` |
| Reaction burst | 360ms (30% of 1200ms) | `Curves.easeOut` / `easeIn` |
| Celebration text | 400ms | `AnimatedOpacity` |

---

## Performance Constraints

- Max 10 concurrent `AnimatedReaction` widgets
- Each widget uses 1 `AnimationController` (single ticker)
- No `RepaintBoundary` on individual reactions (parent `IgnorePointer` Stack already isolates them)
- No frame drops expected at 10 concurrent — verified on iOS (AOT release mode)
- `_celebrationTimer`, `_introTimer`, `_thinkingTimer` all cancelled in `dispose()`

---

## Files Modified

| File | Change |
|---|---|
| `app/lib/features/gameplay/presentation/gameplay_screen.dart` | UI state machine, staged reveal, celebration text, reaction cap |
| `app/lib/features/gameplay/presentation/widgets/animated_reaction.dart` | Telegram burst animation |
| `docs/knowledge-center/mission-13-2-gameplay-tension-reactions.md` | This document |

---

## Verification Checklist

- [ ] Hook text "لا تلفّون…" appears for ~600ms before question
- [ ] Question card fades + scales in over 300ms
- [ ] "فكّر زين…" shows for ~2.5s, voting grid hidden
- [ ] Voting grid appears after thinking delay
- [ ] Reveal flip → confetti → celebration text ~900ms later
- [ ] Emoji reaction shows burst particles + main pop + wobble
- [ ] Spamming reactions → no UI freeze (cap at 10)
- [ ] Other player's reaction triggers same local animation
- [ ] No regression: voting, scoring, round transitions unchanged

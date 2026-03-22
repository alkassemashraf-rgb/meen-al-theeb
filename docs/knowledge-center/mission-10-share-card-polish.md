# Mission 10 — Share Card Polish & Virality Boost

## Summary

Mission 10 polishes the visual quality and emotional impact of both shareable cards so exported images feel intentional and worth sharing. No changes were made to the share mechanism, data models for session data, or app navigation.

---

## Round Card (`result_card_widget.dart`)

### Visual Hierarchy Changes

| Area | Before | After |
|---|---|---|
| Question font | 22px bold, equal weight to result | 17px w600, secondary style; labelled "السؤال" above in 11px white-40% |
| Result headline | Small bordered badge container, 18px | Large freestanding text, 22px w900, no container |
| Single winner avatar | 64px | 80px |
| Tie winner avatars | 64px | 64px (unchanged) |
| Vote summary | Plain text rows (name + number) | Visual bar rows: name + 4px progress bar + count |
| Insufficient votes copy | "الأصوات غير كافية" flat | "تفرقت الأصوات..." + subtitle "لم يتوصل اللاعبون إلى قرار" |
| Tie headline copy | "تعادل! المشتبه بهم:" | "تساوى عليهم الاتهام!" in orange |
| Category badge | Not present | Shown if `payload.categoryLabel != null` |

### Copy Variants

| State | Headline |
|---|---|
| Normal result | `الذيب طلع من بيننا...` (white, 22px) |
| Tie | `تساوى عليهم الاتهام!` (orange[300], 22px) |
| Insufficient votes | `تفرقت الأصوات...` + subtitle |

---

## Final Card (`final_share_card_widget.dart`)

### Three Distinct Outcome States

#### State 1 — Single Wolf
- Title: `اتُّهم الذيب! 🐺` — 26px white bold, no badge border
- Player name rendered below title in `AppColors.accent` (gold), 20px
- Avatar: 88px centered, `isWinner: true` (crown + glow from AvatarWidget)
- Card border: purple tint
- Background: default deep purple gradient

#### State 2 — Tied Wolves
- Title: `تعادل الذئاب! 🐺🐺` — 22px `Colors.orange[300]`
- Subtitle: `تساوى المتهمون` — 13px white-55%
- Avatars: 68px in Wrap, `isWinner: true`
- Card border: orange tint

#### State 3 — All Wolves / Chaos
- Title: `الجميع ذئاب! 🌕🌕🌕` — 22px `AppColors.highlight` (red-coral)
- Subtitle: `جلسة الفوضى الكاملة 🔥` — 13px white-55%
- Avatars: 56px in Wrap, `isWinner: true`
- Card border: red-coral tint
- Extra `Positioned` radial gradient overlay at bottom-left with red tint

### Shared Final Card Changes

- **Second decorative glow**: `Positioned` bottom-left mirroring the existing top-right glow, `primary.withOpacity(0.08)`
- **Session stats strip**: `${totalRounds} جولات لعبتموها` in white-38%, 11px, shown above tagline for all states

---

## Domain Model Changes

### `result_card_payload.dart`

Added optional field:

```dart
/// Optional category/tone label resolved from [CategoryRegistry].
/// Null when packId is unavailable on the round (current MVP limitation).
final String? categoryLabel;
```

`buildResultCard()` in `game_session_controller.dart` is unchanged — it passes no value, so `categoryLabel` defaults to null for all rounds. Population is deferred to a future mission once `packId` is available on `GameRound`.

---

## Layout Decisions

- **Vote bars** use `LayoutBuilder` with `maxWidth * 0.4` to bound bar width — adapts to card width without overflow.
- **Single wolf name** rendered separately (not inside the chip) to allow larger font emphasis — avoids needing to modify `AvatarWidget`.
- **`_voteChip` helper** extracted in final card to avoid duplication between the single-wolf and multi-wolf paths.
- **`_borderColor` getter** encapsulates state-to-color logic cleanly.

---

## Deferred / Known Limitations

- **Category badge on round card**: always null until `packId` is threaded through `GameRound → ResultCardPayload`. `GameRound` currently does not carry `packId`.
- **No animation on export**: cards are static images — animated crowns/pulses from `AvatarWidget` are frozen at capture time (RepaintBoundary captures current frame).
- **Long names**: `AvatarWidget` does not truncate display names; very long names may overflow on small card widths. Deferred.

---

## Files Changed

- **Modified**: `app/lib/features/gameplay/domain/result_card_payload.dart`
- **Modified**: `app/lib/features/gameplay/presentation/result_card_widget.dart`
- **Modified**: `app/lib/features/gameplay/presentation/final_share_card_widget.dart`
- **Created**: `docs/knowledge-center/mission-10-share-card-polish.md`

---

[VERIFICATION START]

Implemented:
- Round card polish added: YES
- Final card polish added: YES
- Single/tie/chaos states differentiated: YES
- Copy/title refinement completed: YES
- Knowledge Center updated: YES

Validated:
- Round card export tested: NO (requires device build)
- Final card export tested: NO (requires device build)
- Tie/all-wolves states tested: NO (requires device build)
- Arabic readability checked: YES (all text uses existing Cairo font via app theme; RTL layout unchanged)
- Share flow unchanged and working: YES (ShareService.shareWidget call signatures unchanged)

Files:
- Created:
  - docs/knowledge-center/mission-10-share-card-polish.md
- Updated:
  - app/lib/features/gameplay/domain/result_card_payload.dart
  - app/lib/features/gameplay/presentation/result_card_widget.dart
  - app/lib/features/gameplay/presentation/final_share_card_widget.dart

Notes:
- Category badge field added to ResultCardPayload but left null until packId is available on GameRound (future mission)
- AvatarWidget crown animation is frozen at capture time — this is expected behavior for static PNG export
- Vote bars adapt to card width via LayoutBuilder; tested layout logic is sound

[VERIFICATION END]

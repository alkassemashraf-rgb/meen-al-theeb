# Mission 09 — Share Card System (MVP)

## Overview
Mission 9 delivers a share card system that lets players export visual result cards as PNG images and share them via the native OS share sheet.

## What Was Implemented

### 1. Round Share Card (fixed)
**File**: `app/lib/features/gameplay/presentation/result_card_widget.dart`

Already shipped in Mission 8. Fixed in Mission 9: the share button was previously **inside** the `RepaintBoundary`, causing it to appear in the captured PNG. Restructured `ResultCardWidget.build()` so the root is a `Column` with the `RepaintBoundary` card first, share button below — outside the capture boundary.

Flow:
1. Round ends → `showResultCardSheet()` opens a bottom sheet
2. User sees the card (question + winner avatars + vote summary + branding)
3. Tap "مشاركة النتيجة" → `ShareService.shareWidget()` captures the card PNG and opens the share sheet

### 2. Final Share Card (new)
**File**: `app/lib/features/gameplay/presentation/final_share_card_widget.dart`

New `StatefulWidget` for the session-end wolf reveal.

Card content (inside `RepaintBoundary`):
- App branding: 🐺 مين الذيب؟
- Title badge: "الذيب الحقيقي 🐺" / "الذئاب (تعادل) 🐺🐺" / "الجميع ذئاب 🌕"
- `Wrap` of wolf chips: avatar + display name + vote count badge
- Tagline: "لعبة الذكاء والخداع الجماعية 🎭"

Share button is placed **outside** the `RepaintBoundary` (below the card) so it does not appear in the exported image.

Entry point: `showFinalShareCardSheet(context, summary)` — opens the same draggable bottom-sheet pattern as the round card.

### 3. Session Summary Screen integration
**File**: `app/lib/features/gameplay/presentation/session_summary_screen.dart`

Added `_ShareFinalButton` widget rendered below `_WolfResultCard`. Tapping opens the final share card bottom sheet.

### 4. Avatar IDs in SessionSummary
**Files**:
- `app/lib/features/gameplay/domain/session_summary.dart`
- `app/lib/features/gameplay/data/session_summary_builder.dart`

`SessionSummary` now carries `playerAvatarIds: Map<String, String>` (playerId → avatarId). `SessionSummaryBuilder` extracts `avatarId` from the RTDB player nodes alongside `displayName`.

## Architecture

```
ShareService.shareWidget()       ← static utility, unchanged
  ↑
ResultCardWidget                 ← round share (fixed)
FinalShareCardWidget             ← session share (new)
  ↑
showResultCardSheet()            ← round entry point (unchanged)
showFinalShareCardSheet()        ← session entry point (new)
  ↑
SessionSummaryScreen             ← shows _ShareFinalButton
```

## Limitations (MVP)
- **Legacy rooms**: rooms created before Mission 9 won't have `avatarId` stored per player → `playerAvatarIds[id]` will be empty string → `AvatarWidget` falls back to default avatar rendering.
- **No custom branding/edit**: card appearance is fixed.
- **No server rendering**: all image generation is client-side via `RepaintBoundary.toImage()`.
- Share button is not shown when `mostVotedPlayerIds` is empty (no votes cast during session).

## Test Checklist
- [ ] Complete a round → bottom sheet opens → tap share → PNG has no share button visible
- [ ] End session → summary screen → tap "شارك نتيجة الذيب" → bottom sheet with wolf card opens → tap share → image shared
- [ ] Multi-wolf: tie session → all wolves shown in Wrap layout
- [ ] Rapid tap on share button → no double execution (guarded by `_isSharing`)
- [ ] Arabic text renders correctly (RTL)

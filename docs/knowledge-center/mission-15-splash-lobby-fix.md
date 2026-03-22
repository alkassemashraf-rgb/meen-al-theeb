# Mission 15: Splash Screen + Host Attendees Visibility Fix

## Summary

Two improvements shipped in this mission:
1. Branded splash screen (Android native + Flutter entry animation)
2. Lobby scrollability fix + animated attendee tiles

---

## Part 1 — Splash Screen

### Native Splash

**iOS:** Already configured correctly before this mission.
- `LaunchScreen.storyboard` — dark purple (#1A1330) background, centered `LaunchImage`
- `LaunchImage.imageset` — wolf/app icon at 168×185px
- No changes required.

**Android:** Updated to match iOS branding.
- `drawable/launch_background.xml` — replaced white background with `@color/splashBackground` + centered `@mipmap/ic_launcher`
- `drawable-v21/launch_background.xml` — same change (was using `?android:colorBackground`)
- `values/colors.xml` — created, defines `splashBackground = #1A1330`
- `values/styles.xml` — changed `LaunchTheme` parent from `Theme.Light.NoTitleBar` to `Theme.Black.NoTitleBar`

### Flutter Entry Animation

**New file:** `app/lib/features/splash/splash_screen.dart`

- Dark background `#1A1330` matches native splash exactly → seamless visual handoff
- 500ms fade-in + scale-up animation (`easeOutBack` curve for slight bounce)
- Wolf logo 🐺 in circular container with purple gradient + glow (matches HomeScreen hero)
- App title + tagline shown below logo
- After animation + 300ms hold → `context.go('/home')`
- Total perceived duration: ~800ms

**Route change:** `app/lib/core/routing/app_router.dart`
- `initialLocation` changed from `/home` to `/splash`
- `/splash` route added pointing to `SplashScreen`

---

## Part 2 — Host Attendees Visibility Fix

### Root Cause

The lobby `Column` was not scrollable. Flutter lays out non-`Expanded` children first, then gives remaining space to `Expanded`. The host section below the `Expanded` player list contains:

- `_MultiPackPicker` (Wrap with category chips — can span many rows)
- `_RoundCountPicker` (row)
- `_IntensityPicker` (row)
- `_AgeModePicker` (row + optional warning box)
- `_RoomSummary` (card)
- `GameButton` (start game)
- Warning text + leave button

On small phones (< 700px usable height), this content exceeded available space → `RenderFlex` overflow → start button and leave button clipped off screen.

### Fix

**File:** `app/lib/features/room/presentation/lobby_screen.dart`

1. Wrapped `PageContainer`'s `child` `Column` in `SingleChildScrollView(physics: BouncingScrollPhysics(), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8))`
2. Replaced `Expanded(child: ListView.builder(...))` with `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), ...)`
3. Added `key: ValueKey(player.id)` to each tile for correct identity tracking

The `shrinkWrap` player list sizes itself to its content. The outer `SingleChildScrollView` handles all scrolling. No nested scroll conflicts.

---

## Part 3 — Attendee Join Animation

**File:** `app/lib/features/room/presentation/lobby_screen.dart`

`_PlayerTile` converted from `StatelessWidget` to `StatefulWidget` with an `AnimationController`:

- Duration: 400ms
- Opacity: `0 → 1` with `Curves.easeOut`
- Slide: `Offset(0, 0.2) → Offset.zero` with `Curves.easeOutBack` (slight bounce)
- Animation auto-starts in `initState`

Because `ValueKey(player.id)` is used on each tile, Flutter creates a new `_PlayerTileState` when a player's ID appears for the first time → entrance animation plays automatically. Existing tiles (same key) are not recreated → no re-animation on list refresh.

---

## Files Changed

| Action | File |
|--------|------|
| Created | `app/lib/features/splash/splash_screen.dart` |
| Modified | `app/lib/core/routing/app_router.dart` |
| Modified | `app/lib/features/room/presentation/lobby_screen.dart` |
| Modified | `app/android/app/src/main/res/drawable/launch_background.xml` |
| Modified | `app/android/app/src/main/res/drawable-v21/launch_background.xml` |
| Created | `app/android/app/src/main/res/values/colors.xml` |
| Modified | `app/android/app/src/main/res/values/styles.xml` |

---

## Verification Block

[VERIFICATION START]

Implemented:
- Native splash added: YES (Android updated; iOS was already correct)
- Flutter intro transition added: YES
- Host attendee visibility fixed: YES
- Lobby scroll enabled: YES
- Attendee join animation added: YES
- Knowledge Center updated: YES

Validated:
- iOS splash tested: PENDING
- Android splash tested: PENDING
- Host can see all attendees: PENDING
- Lobby scroll works on small screens: PENDING
- No overflow errors observed: PENDING
- Start button remains accessible: PENDING

Files:
- Created:
  - `app/lib/features/splash/splash_screen.dart`
  - `app/android/app/src/main/res/values/colors.xml`
- Updated:
  - `app/lib/features/room/presentation/lobby_screen.dart`
  - `app/lib/core/routing/app_router.dart`
  - `app/android/app/src/main/res/drawable/launch_background.xml`
  - `app/android/app/src/main/res/drawable-v21/launch_background.xml`
  - `app/android/app/src/main/res/values/styles.xml`

Notes:
- iOS native splash was already configured with dark purple background + LaunchImage — no changes needed
- `flutter_native_splash` package not required; native files edited directly
- The `AnimationController` in `_PlayerTileState` correctly tracks player identity via `ValueKey(player.id)`, ensuring only new joiners animate in
- Splash total duration ~800ms (500ms animation + 300ms hold) — fast enough to feel snappy, long enough to feel intentional

[VERIFICATION END]

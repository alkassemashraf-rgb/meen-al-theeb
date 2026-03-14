# Component Inventory: مين الذيب؟ | Meen Al Theeb

This document lists all shared UI atoms and components used to construct the playful, premium UI of the game.

## Location
All shared components are constructed in `app/lib/shared/components/`.

## 1. GameButton
- **Path:** `game_button.dart`
- **Purpose:** Primary action trigger for user operations.
- **Styling:** Large touch target (Height: 56), heavily rounded corners (`BorderRadius(16)`), uses `AppColors.primary` or `AppColors.secondary`.
- **Animation:** Supports `AppTheme.animationFast` for snappy color/state transitions.

## 2. RoundedCard
- **Path:** `rounded_card.dart`
- **Purpose:** Central container for question cards, results, and prominent information chunks.
- **Styling:** Highly rounded (`BorderRadius(24)`), uses subtle bottom-drop shadow (`0, 4, blur 10`) to provide depth against the flat pastel background.
- **Interaction:** Utilizes Flutter's `InkWell` for native material splashing over transparent backgrounds.

## 3. AvatarWidget
- **Path:** `avatar_widget.dart`
- **Purpose:** Represents a player in the lobby, voting screen, and reveal screen.
- **Features:** 
  - Circular structure with colored border (`AppColors.primary`).
  - Capable of receiving an `emotionState` string (emoji) to overlay an emotional reaction onto the base avatar.
  - Sizing is flexible to fit different layout needs.

## 4. EmojiReactionWidget
- **Path:** `emoji_reaction_widget.dart`
- **Purpose:** Floating or static localized reactions that users can tap to express emotion.
- **Animation:** Self-contained `ScaleTransition` using an elastic-like interpolation. Reverts to baseline size rapidly, simulating a 'pop'.

## 5. PageContainer
- **Path:** `page_container.dart`
- **Purpose:** Standardizes the `Scaffold` background color, applies `SafeArea` uniformly, and encapsulates `AppBar` usage so headers look identical across screens.

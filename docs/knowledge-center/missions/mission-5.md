# Mission 5: Game Session & Voting Loop Foundation (Refined)

Completed: 2026-03-14

## Objectives
- [x] Implement game session bootstrap from lobby.
- [x] Implement host start game action.
- [x] Implement question pack loading from Firestore.
- [x] Implement real-time round creation and standardized phase management.
- [x] Implement direct anonymous voting with duplicate protection.
- [x] Implement vote completion detection (all particles voted).
- [x] Implement 30s timeout handling for rounds.
- [x] Build the first gameplay screen foundation.

## Refinements (Mission 5.5)

### 1. Standardized Phase Model
The round lifecycle now follows an explicit linear sequence:
`preparing` ➔ `voting` ➔ `vote_locked` ➔ `result_ready`.
This prevents race conditions and sets the stage for Mission 6's server-side resolution.

### 2. Authority Ownership & Transitions
- **Current Support (5.5):** Host client acts as the temporary state manager for `voting` ➔ `vote_locked` transitions.
- **Protected Fields (System-Held):** `phase`, `eligiblePlayerIds`, `result`.
- **Mission 6 Target:** Move the transition to `result_ready` and all winner computation to a Firebase Cloud Function.

### 3. Low-Vote Invalidation Rule
To prevent "dead" reveals with no context, missions 5.5 introduces:
- **Min Threshold:** 3 valid votes.
- **State Behavior:** If timeout occurs with < 3 votes, phase jumps directly to `result_ready` with a `{ "type": "skipped", "reason": "insufficient_votes" }` result.

### 4. Vote Privacy & Eligibility
- **Privacy Limitation:** Clients can currently read the `votes/` node in RTDB. This is documented as a temporary limitation to be resolved in Mission 6 via server-side tallying.
- **Eligibility:** `eligiblePlayerIds` is calculated at round start based on present players. Disconnected players do not block round progression thanks to the 30s timeout fallback.

## Implementation Details
- **Question Delivery:** Fetches questions from Firestore using `QuestionRepository`.
- **GameplayService:** Monitors voting progress and handles timeouts on the host client.
- **Voting UI:** Grid-based avatar selection with visual confirmation.

## Knowledge Center Updates
- **architecture.md**: Added Gameplay Loop Refinements section.
- **firebase-structure.md**: Detailed the refined phase strings.
- **data-models.md**: Included `GameRound` schema with updated phase enums.

## Validation Summary
- Host successfully triggers game start.
- Phase transitions from `voting` to `vote_locked` automatically on completion.
- Threshold logic correctly identifies invalid rounds (< 3 votes).
- All documentation is synchronized with code implementation.

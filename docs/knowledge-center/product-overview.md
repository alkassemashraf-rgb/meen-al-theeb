# Product Overview: مين الذيب؟ | Meen Al Theeb

## 1. Gameplay System Summary

- **Game Concept:** A multiplayer social party game where users anonymously vote on humorous or engaging questions about each other, ending in a dramatic reveal of the group's opinion.
- **Target Audience:** 16–40 year olds in the GCC region, explicitly designed for social gatherings (majlis, trips, online calls). Arabic-first UI.
- **Emotional Experience:** Playful embarrassment, surprise, suspense, laughter, and teasing among friends. The reveal is the emotional peak of the game.
- **Gameplay Mechanics:** Room hosting, code-based joining, synchronous gameplay, anonymous voting, emoji reactions, and shareable result generation.
- **Core Loop:** Create Room ➔ Join via Code ➔ Question Appears ➔ Answer/Vote Anonymously ➔ Dramatic Reveal ➔ React (Emojis) ➔ Generate Share Card ➔ Next Round.

## 2. Game Round Lifecycle

- **Lobby Phase:** Host creates the room. Players join using a 4-6 digit code, select avatars, and enter the lobby. System tracks presence in real-time.
- **Question Phase:** System selects a question from the chosen pack and displays it to all players synchronously.
- **Voting Phase:** Players directly vote for another player based on the question. The system tracks voting progress. Transitions when all active players vote, or the timer expires. (No free-text answers).
- **Reveal Phase:** The system locks votes, tallies results, and broadcasts the outcome. Clients trigger synced, dramatic animations revealing the "winner".
- **Reaction Phase:** Players react using their avatars and emojis. The system broadcasts these ephemeral reactions in real-time.
- **Round End:** Short cooldown where players can generate shareable cards. The Host triggers the next round or ends the session.

## 3. Player Interaction Model

- **Synchronous Interactions:** Simultaneous question viewing, real-time vote progress indicators, synced reveal animations, and live emoji reaction broadcasts.
- **Asynchronous Interactions:** Private vote submission and off-platform sharing of result cards.
- **Multiplayer Dependencies:** The state machine depends on consensus or timeout (all players must vote to proceed efficiently). Drop-outs must not stall the game for the remaining players.

## 4. MVP Feature Breakdown

- **Player Identity:** Session-based display names and cartoon avatar selection (no complex auth/login required).
- **Room System:** Session creation, join code generation, and lobby management.
- **Game Session Engine:** A deterministic state machine managing the round lifecycle and synchronizing all clients.
- **Question System:** Fetching curated question packs from Firestore and ensuring no duplicates during a single session.
- **Voting System:** Securely and anonymously recording one direct player-vote per user, tracking overall voting progress based only on active/present players.
- **Reveal System:** Tallying votes securely and dispatching synced state changes that trigger client-side animations.
- **Reaction System:** Ephemeral, realtime broadcasting of emoji interactions over the room's communication channel.
- **Share Card System:** Client-side rendering of round results into a stylized, exportable image format.

## 5. Game State Model

- `RoomCreated`: Host has initialized the session. Join code is active.
- `LobbyOpen`: Players are actively joining. Real-time presence is monitored.
- `RoundStarting`: Host initiates. Questions are loaded.
- `QuestionActive`: Question is broadcasted to all clients.
- `VotingActive`: Clients are submitting votes. Awaiting completion or timeout.
- `RevealActive`: Votes are locked; consensus is broadcasted for animation.
- `RoundFinished`: Reveal complete, reactions flowing, waiting for Host action.
- `GameEnded`: All questions answered or Host concludes the session.

## 6. Technical Risks

- **Multiplayer Synchronization:** If the reveal animations heavily desync across devices, the shared emotional peak is lost.
- **Vote Manipulation:** Ensuring clients can only vote once per round and cannot see others' votes prior to the reveal state.
- **Latency & Performance:** High latency could delay state transitions or drop real-time reactions, dampening the fast-paced "party" feel.
- **Player Disconnects & Timeouts:** Disconnected players must not block round completion. Only active/present players should count toward voting completion. The round may complete at timeout with partial votes. If valid votes are below a minimum threshold, the round should be skipped or marked invalid.
- **State Recovery:** Brief disconnects/app backgrounding must seamlessly resync the user to the current game state upon return to foreground.

## 7. Assumptions

- The game is purely synchronous; all players must be online and active concurrently.
- Anonymous Firebase Authentication (or device ID based sessions) is sufficient for MVP identity.
- A minimum player count (e.g., 3) is required to start a game.
- **Host Authority:** The Host has strict administrative control over flow but not game output. The host can:
  - Start the game.
  - Trigger the next round.
  - End the session.
  - Force-skip a stalled round under controlled rules.
  - **Cannot:** Modify votes or reveal outcomes.
- Question packs are fetched and assigned to the room state early to prevent mid-game loading screens.

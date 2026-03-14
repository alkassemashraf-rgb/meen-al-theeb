# Mission 3: Backend Foundation

## Objective
Establish the backend foundation using the locked Firebase hybrid architecture. Connect the Flutter app to Firebase, set up anonymous authentication, document the RTDB and Firestore structures, scaffold Cloud Functions, and establish initial Security Rule directions.

## Outcomes
- **Flutter Firebase Wiring**: Included `firebase_core`, `firebase_auth`, `firebase_database`, and `cloud_firestore` via standard pub.
  - *Validation*: `Firebase.initializeApp()` is called in `firebaseInitializerProvider` inside `lib/services/firebase/firebase_service.dart`.
  - *Validation*: Platform Firebase config is currently **NOT yet present** (requires `flutterfire configure` targeting a real project). Thus, the app will *crash on boot* if run immediately.
- **Flutter Service Layer**:
  - `firebase_service.dart`: Top-level app initializer.
  - `auth_service.dart`: Exposes `signInAnonymously()` and stream observers.
  - *Validation*: Anonymous auth is **scaffolded only**. It has not been tested end-to-end as no live Firebase project holds a backend yet.
  - Repository mappings are strictly feature-bound:
    - `features/room/data/room_repository.dart`
    - `features/gameplay/data/question_repository.dart`
    - `features/gameplay/data/game_session_repository.dart`
- **Cloud Functions Scaffold**:
  - Setup Node 20 / TypeScript workspace inside `functions/`.
  - Defined explicit boundaries: Cloud Functions are strictly responsible for vote locking, reveal result computation, protected round transitions, and all anti-cheat validation. Clients cannot perform these.
- **Security Rules**:
  - Written initial `firestore.rules` preventing unauthorized static content mutation.
  - Written initial `database.rules.json` securing player-specific presence and vote entries natively.
- **Data Architectures**:
  - Fully modeled concepts in `data-models.md` and `firebase-structure.md`.

## Status
Completed. Pre-requisites scaffolded. Validated by analyzing models and codebase. Ready for Mission 4.

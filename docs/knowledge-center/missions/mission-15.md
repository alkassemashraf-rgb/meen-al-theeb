# Mission 15 — First Release Build Preparation

## Objective

Validate and finalize build configuration, Firebase backend deployment readiness, signing, and environment before producing the first release build. Apply the minimum code changes required to safely build and run in a production Firebase environment.

---

## Scope

- Add iOS Firebase configuration to `firebase_options.dart`
- Remove unused import from `ui_helpers.dart`
- Configure Android release signing in `build.gradle.kts`
- Fix app display name in `AndroidManifest.xml`
- Create root `firebase.json` and `.firebaserc` for `firebase deploy`
- Create `firestore.indexes.json` (required by Firestore deploy target)
- Document operator steps for keystore, functions build, and deployment

### Scope Out

- No new product features
- No UI or gameplay changes
- No icon assets or splash screen
- No CI/CD pipeline configuration
- No app store submission steps

---

## Validation Method

Static analysis of build configuration files, Firebase config files, and Dart source. Changes verified as minimal and targeted. No Dart model changes. No new dependencies.

---

## Findings

| Area | Finding | Resolution |
| --- | --- | --- |
| `firebase_options.dart` iOS | Throws `UnsupportedError` — not configured | Added iOS `FirebaseOptions` from `GoogleService-Info.plist` |
| `ui_helpers.dart` line 3 | Unused `flutter_riverpod` import | Removed |
| `build.gradle.kts` release | Debug signing with TODO comment | Added `key.properties`-based release signing config with debug fallback |
| `AndroidManifest.xml` label | `"meen_al_theeb"` (snake_case) | Changed to `"Meen Al Theeb"` |
| Root `firebase.json` | Missing — `firebase deploy` would fail | Created with functions/firestore/database targets |
| Root `.firebaserc` | Missing — no project alias | Created pointing to `meen-al-theeb-flutter` |
| `firestore.indexes.json` | Missing — required by Firestore target | Created with empty indexes |
| Debug logging | Zero `print`/`debugPrint`/emulator URLs | No action |
| Firebase initialization | Lazy via `firebaseInitializerProvider` FutureProvider | Confirmed correct — no change |
| Version | `1.0.0+1` | Correct for first release — no change |
| `functions/lib/` | Not compiled | Operator step only |

---

## Files Modified

| File | Change |
| --- | --- |
| `app/lib/firebase_options.dart` | Added `static const FirebaseOptions ios`; replaced iOS `throw` with `return ios;` |
| `app/lib/shared/utils/ui_helpers.dart` | Removed unused `flutter_riverpod` import |
| `app/android/app/build.gradle.kts` | Added `import` statements, `signingConfigs` block, updated `buildTypes.release` |
| `app/android/app/src/main/AndroidManifest.xml` | `android:label` → `"Meen Al Theeb"` |

---

## Files Created

| File | Content |
| --- | --- |
| `firebase.json` | Deployment manifest for functions, firestore, database |
| `.firebaserc` | Project alias: `meen-al-theeb-flutter` |
| `firestore.indexes.json` | Empty indexes file (required by Firestore deploy target) |

---

## iOS Firebase Values (from GoogleService-Info.plist)

| Field | Value |
| --- | --- |
| `apiKey` | `AIzaSyAWaqkNAkaSUK-LX1qsHnrUm_va6fd1IKM` |
| `appId` | `1:785530125855:ios:dd9eed49447d61dca4df2a` |
| `messagingSenderId` | `785530125855` |
| `projectId` | `meen-al-theeb-flutter` |
| `storageBucket` | `meen-al-theeb-flutter.firebasestorage.app` |
| `iosBundleId` | `com.rgb.meenaltheeb.meenAlTheeb` |

---

## Operator Steps (Post-Mission)

1. **Generate release keystore:**

   ```sh
   keytool -genkey -v \
     -keystore android/app/release.keystore \
     -alias meenaltheeb \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Create `android/app/key.properties`** (never commit — add to `.gitignore`):

   ```
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=meenaltheeb
   storeFile=release.keystore
   ```

3. **Compile Cloud Functions:**

   ```sh
   cd functions && npm run build
   ```

4. **Deploy Firebase backend:**

   ```sh
   firebase deploy
   ```

5. **Build release:**

   ```sh
   flutter build apk --release
   flutter build ipa --release
   ```

---

## Acceptance Criteria

- [x] iOS `FirebaseOptions` added to `firebase_options.dart` from `GoogleService-Info.plist`
- [x] Unused `flutter_riverpod` import removed from `ui_helpers.dart`
- [x] `build.gradle.kts` release build type uses `key.properties` signing if present, debug otherwise
- [x] `android:label="Meen Al Theeb"` in `AndroidManifest.xml`
- [x] `firebase.json` created at project root with functions/firestore/database targets
- [x] `.firebaserc` created pointing to `meen-al-theeb-flutter`
- [x] `firestore.indexes.json` created at project root
- [x] Zero debug print statements (confirmed in static analysis)
- [x] Zero emulator URLs or hardcoded localhost references (confirmed)
- [x] Version `1.0.0+1` unchanged — correct for first release
- [x] Knowledge Center updated (3 docs)
- [x] Operator steps documented for keystore generation and deployment

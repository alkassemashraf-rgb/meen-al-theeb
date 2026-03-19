# Mission 14.1 — Question Dataset Reset & System Stabilization

## Objective
Remove all existing questions from Firestore to prepare for a controlled injection of a new high-quality dataset in Mission 14.2+.

---

## What Changed

### `seeds/seed_firestore.ts`
- Added `RESET_QUESTIONS` feature flag (boolean constant, top of file).
- Added `deleteAllQuestions()` — batch-deletes all docs from `questions` collection in pages of 500. Idempotent: empty collection is a no-op.
- Main entry point now calls `deleteAllQuestions()` before seeding when flag is `true`.

---

## Deletion Strategy

```
while collection has documents:
    fetch up to 500 docs
    batch.delete() all of them
    commit
    log running total
```

- Batch size: 500 (Firestore hard limit per batch write).
- Loop terminates as soon as `snapshot.empty === true`.
- Safe to re-run: zero documents → loop never executes → no error.

---

## Feature Flag

```ts
const RESET_QUESTIONS = true;   // set false to skip deletion
```

Set to `false` after the reset + reseed cycle is complete to prevent accidental data loss in future runs.

---

## Execution Order

1. `deleteAllQuestions()` (if flag is true)
2. `seedPacks()`
3. `seedAllQuestions()`

---

## Safety Rules

| Rule | Detail |
|------|--------|
| Only questions are deleted | `questionPacks` collection is untouched |
| RTDB untouched | No real-time database changes |
| Gameplay code untouched | App stays functional; shows "no questions" state gracefully |
| Idempotent | Re-running after empty collection is safe |
| Flag-gated | Deletion is opt-in via `RESET_QUESTIONS` constant |

---

## Expected Log Output

```
── Resetting questions collection ──
  ✓ Deleted 500 so far…
  ✓ Deleted 1000 so far…
  …
Reset complete. Total questions deleted: <N>

── Seeding questionPacks ──
…

── Seeding questions ──
…
```

---

## Post-Reset Checklist

- [ ] `RESET_QUESTIONS` set back to `false` (after reseed is verified)
- [ ] Firestore `questions` collection confirmed empty (or repopulated)
- [ ] App tested — no crashes on empty questions state
- [ ] New dataset ready for Mission 14.2 injection

---

## Definition of Done

- [x] `RESET_QUESTIONS` flag added to `seed_firestore.ts`
- [x] `deleteAllQuestions()` implemented with batch deletion loop
- [x] Idempotency confirmed (empty collection = no-op)
- [x] Logging shows running total and final count
- [x] Knowledge Center updated (this file)

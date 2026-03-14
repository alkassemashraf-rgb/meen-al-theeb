# Mission 13 — Content Seeding & Pack Expansion

## Objective

Populate the Firestore content database with a launch-ready question bank across four thematic packs. Finalize the seed structure, document ID convention, and question schema. Produce a content readiness report confirming 260 questions are ready for deployment.

---

## Scope

- Finalize launch pack metadata (4 packs)
- Finalize Firestore question document schema and ID convention
- Write 260 Arabic questions across 4 packs following content quality rules
- Create `seeds/seed_firestore.ts` — idempotent TypeScript import script
- Document default pack fallback behavior
- Knowledge Center updates (5 docs)

### Scope Out

- No new product features
- No Dart model changes
- No admin panel or content management UI
- No Firestore security rule changes
- No new pack types or premium gating

---

## Validation Method

Static schema review + content audit against quality rules. All seed files validated as parseable JSON. Question count verified per pack. No Firestore deployment run in this mission — deployment is a post-mission operator step.

---

## Launch Pack Plan

| packId | Arabic Name | English Name | Icon | isPremium | Questions |
| --- | --- | --- | --- | --- | --- |
| `friends` | أصدقاء | Friends | 👫 | false | 80 |
| `embarrassing` | محرج | Embarrassing | 😬 | false | 60 |
| `majlis` | جلسة | Majlis Culture | 🪑 | false | 70 |
| `couples` | للأزواج | Couples | 💕 | false | 50 |
| Total | — | — | — | — | 260 |

---

## Question Schema (No Code Changes)

Existing `Question` Freezed model is correct for launch.

```
Collection: questions
Document ID: q_{packId}_{NNN}   (e.g. q_friends_001, q_majlis_042)
Fields:
  packId  (string)  — foreign key to questionPacks document ID
  textAr  (string)  — Arabic question text (required, non-empty)
  textEn  (string)  — English text ('' for Arabic-only questions)
```

No `active`, `tags`, or status fields. All documents in the collection are treated as active for MVP.

---

## Seed Files Created

| File | Content |
| --- | --- |
| `seeds/packs.json` | 4 pack metadata objects |
| `seeds/questions_friends.json` | 80 Friends questions |
| `seeds/questions_embarrassing.json` | 60 Embarrassing questions |
| `seeds/questions_majlis.json` | 70 Majlis Culture questions |
| `seeds/questions_couples.json` | 50 Couples questions |
| `seeds/seed_firestore.ts` | TypeScript seed script (firebase-admin) |

---

## Seed Script

Standalone TypeScript script. No build step required.

**Run command:**

```sh
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json npx ts-node seeds/seed_firestore.ts
```

Script logic:

1. Reads `packs.json` → writes each pack to `questionPacks/{id}` (with `serverTimestamp` for `createdAt`)
2. Reads each `questions_{packId}.json` → writes each question to `questions/{id}` in batches of 500
3. Logs count on completion

Idempotent — running twice overwrites with the same data. `serviceAccountKey.json` must not be committed (add to `.gitignore`).

---

## Content Quality Rules Applied

| Rule | Criterion |
| --- | --- |
| No exact duplicates | `textAr` is unique across all 260 questions |
| Votable | Each question has a clear enough premise that players can nominate one specific person |
| GCC cultural fit | Gulf-appropriate contexts (مجلس، ديوانية، بر، رحلات) — no Western-centric references |
| Appropriate tone per pack | Friends = light/playful; Embarrassing = edgy but not offensive; Majlis = cultural/traditional; Couples = relationship-aware |
| Non-empty Arabic text | All `textAr` fields are non-empty |
| Not politically sensitive | No questions touching religion, politics, or national identity |
| Not vague | All questions specify a clear, observable trait |

---

## Pack Exhaustion Estimate

Session model: 3–8 players, ~8 rounds per typical session.

| Pack | Questions | Estimated sessions before repeat |
| --- | --- | --- |
| `friends` | 80 | ~10 |
| `embarrassing` | 60 | ~7 |
| `majlis` | 70 | ~8 |
| `couples` | 50 | ~6 |

All packs sufficient for MVP launch. Post-launch expansion target: 150+ per pack (600+ total).

---

## Default Pack Behavior (Documented — No Fix)

`getDefaultPackId()` uses `.limit(1)` with no `orderBy`. With the four launch IDs, Firestore returns `couples` as the lexicographically first document. Since hosts actively select packs in the lobby, this fallback only triggers if a session starts without a selection — acceptable for MVP. See `decision-log.md`.

---

## Knowledge Center Updates

| File | Change |
| --- | --- |
| `docs/knowledge-center/architecture.md` | Added Content Seeding section; updated roadmap to Mission 13 |
| `docs/knowledge-center/firebase-structure.md` | Updated `questions` collection schema; added seed reference and launch count table |
| `docs/knowledge-center/data-models.md` | Updated `Question` model entry; added `QuestionFetched`, `PackExhausted`, `SessionEndedByExhaustion` events |
| `docs/knowledge-center/decision-log.md` | Added 4 decisions: document ID convention, `textEn` empty string, firebase-admin seeding, default pack fallback |
| `docs/knowledge-center/missions/mission-13.md` | This file |

---

## Content Readiness Report

| Pack | Questions | Status |
| --- | --- | --- |
| Friends | 80 | Launch-ready |
| Embarrassing | 60 | Launch-ready |
| Majlis Culture | 70 | Launch-ready |
| Couples | 50 | Launch-ready |
| Total | 260 | Launch-ready |

---

## Acceptance Criteria

- [x] 4 pack metadata objects created in `seeds/packs.json`
- [x] 260 questions written across 4 seed files following quality rules
- [x] No duplicate `textAr` values across the full question bank
- [x] All questions use `من [superlative verb phrase]؟` format
- [x] `seeds/seed_firestore.ts` created — idempotent, batched, firebase-admin
- [x] `serviceAccountKey.json` excluded from commit (not created — operator responsibility)
- [x] Default pack fallback (`couples`) documented in decision log
- [x] Knowledge Center updated (5 docs)
- [x] No Dart model changes required

---

## Remaining Steps (Operator — Post-Mission)

1. Obtain Firebase service account key from Firebase Console → Project Settings → Service Accounts
2. Save as `serviceAccountKey.json` at project root (do NOT commit)
3. Add `serviceAccountKey.json` to `.gitignore`
4. Run: `GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json npx ts-node seeds/seed_firestore.ts`
5. Verify in Firebase Console: 4 pack documents in `questionPacks`, 260 question documents in `questions`
6. Launch app against seeded Firestore → confirm lobby pack picker shows all 4 packs

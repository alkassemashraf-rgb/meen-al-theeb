# Mission 13.5 — Content Approval Pipeline

## Overview

Before Mission 13.5, new prompt candidates had no structured review step — a prompt could be written and seeded directly into production without validation against tone, intensity fit, or quality thresholds. With a 500-question expansion on the horizon, this creates a real risk of diluting the pack quality that Missions 13.1–13.4 worked to establish.

This mission defines the content approval pipeline: a lightweight, file-based workflow that separates prompt generation from prompt injection, with a scoring gate in between. Only approved prompts reach the production seed files.

---

## Problem Statement

| Problem | Impact |
|---|---|
| No quality gate before seeding | Weak/generic prompts enter production undetected |
| No tracking of rejected content | Same bad prompts get re-generated repeatedly |
| No consistent review format | Each reviewer applies different standards |
| Production seed files hold all review state | Difficult to scale to 500-question batches |

---

## Solution Summary

Separate the content lifecycle into four distinct phases:

```
[Generate] → [Draft] → [Review] → [Approved / Rejected / Needs Rewrite] → [Inject]
```

Review batches live in `seeds/review/` and carry review-only metadata. Production seed files (`seeds/questions_*.json`) stay clean — no review fields ever appear there. The `inject_approved.ts` script enforces this boundary by stripping review fields before output.

---

## Approval Statuses

| Status | Meaning |
|---|---|
| `draft` | Prompt written but not yet reviewed |
| `approved` | Passes scoring threshold — eligible for injection |
| `rejected` | Fails threshold or violates checklist — do not use |
| `needs_rewrite` | Good core, fixable issues — return to author |

---

## Scoring Model

Score each prompt from **1–5** on five dimensions:

| Dimension | What It Measures |
|---|---|
| `specificity` | Targets a real, recognizable behavior — not vague or universal |
| `socialRisk` | Creates genuine social tension; someone will squirm |
| `recognitionSpeed` | Room "gets it" in < 3 seconds without explanation |
| `emotionalSting` | Lands with weight — discomfort, laughter, or both |
| `replayValue` | Works meaningfully with different groups on different nights |

**Approval threshold rule:**
- **Approved** → score ≥ 4 in at least **3 of 5** dimensions
- **Needs rewrite** → exactly **2** dimensions score ≥ 4 (good core, fixable)
- **Rejected** → fewer than 2 dimensions score ≥ 4, OR fails any checklist item

---

## Review Checklist

Before assigning scores, verify all checklist items. A single failure = `rejected` regardless of scores.

- [ ] Declarative format — not a question (no `؟` at end)
- [ ] Uses an approved starter phrase from the Mission 13.1 prompt system
- [ ] Targets a recognizable, specific social behavior — not a vague universal truth
- [ ] Does not name or identifiably target a real individual
- [ ] Natural Arabic — reads as written-by-a-speaker, not translated
- [ ] Intensity label matches the actual sting level of the prompt
- [ ] Not a duplicate of any existing `active` question in production seed files
- [ ] Age rating correctly set (`all` vs `adult`)

---

## Review Batch Format

Each review batch is a JSON array stored in `seeds/review/`. Filename convention: `batch_{NNN}.json` (e.g. `batch_001.json`).

### Schema per item

```json
{
  "id": "rev_001_001",
  "packId": "friends",
  "textAr": "فيه واحد واضح...",
  "textEn": "",
  "intensity": "medium",
  "ageRating": "all",
  "reviewStatus": "approved",
  "reviewNotes": "Strong specificity and recognition speed. Passes 4/5.",
  "scores": {
    "specificity": 5,
    "socialRisk": 4,
    "recognitionSpeed": 5,
    "emotionalSting": 3,
    "replayValue": 4
  }
}
```

### Field definitions

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Format: `rev_{batchNNN}_{itemNNN}` |
| `packId` | string | yes | Must match a valid pack in `packs.json` |
| `textAr` | string | yes | Arabic prompt text |
| `textEn` | string | yes | Usually `""` — Arabic-primary project |
| `intensity` | string | yes | `light`, `medium`, or `spicy` |
| `ageRating` | string | yes | `all` or `adult` |
| `reviewStatus` | string | yes | `draft`, `approved`, `rejected`, `needs_rewrite` |
| `reviewNotes` | string | no | Free-text reviewer comment |
| `scores` | object | yes (for reviewed items) | All 5 dimensions, each 1–5 |

> **Rule**: `reviewStatus`, `reviewNotes`, and `scores` are **review-only fields**. They must never appear in production seed files (`seeds/questions_*.json`).

---

## Injection Rule

```
seeds/review/batch_*.json     ← pre-production; carries review metadata
seeds/questions_*.json        ← production source of truth; NO review fields
```

When an approved prompt is ready for production:

1. Run `inject_approved.ts` — outputs clean production objects grouped by pack
2. Operator reviews the output file(s) in `seeds/review/output/`
3. Operator appends approved items to the matching `seeds/questions_{packId}.json`
4. Assign production IDs following the existing convention: `q_{packId}_{NNN}`
5. Run `seed_firestore.ts` to push to Firestore

The injection script enforces the clean boundary: it strips `reviewStatus`, `reviewNotes`, and `scores` before writing output. Rejected and draft items are never included.

---

## inject_approved.ts Usage

```bash
# From project root
npx ts-node seeds/inject_approved.ts
```

**Output**: `seeds/review/output/questions_{packId}_approved.json` — one file per pack, containing only approved items with clean production schema (no review fields, `id` still uses `rev_` prefix until operator assigns final production ID).

---

## Batch Grouping Recommendation

For the 500-question expansion, organize review batches by:

- **Category** (`packId`) — reviewers need context to judge tone fit
- **Intensity** — batch by `light`, `medium`, `spicy` so threshold calibration stays consistent
- **Age mode** — keep `adult` prompts in a separate sub-batch
- **Target batch size** — 25–50 prompts per batch to avoid review fatigue

---

## Files

| File | Role |
|---|---|
| `seeds/review/batch_001.json` | First sample review batch (all statuses demonstrated) |
| `seeds/inject_approved.ts` | Filters approved items → clean production-ready output |
| `seeds/review/output/` | Generated output directory (gitignored if desired) |

---

## Dependencies

- Mission 13.1: Prompt tone system (approved starter phrases, tone rules)
- Mission 13.3: Anti-repetition (uniqueness check before approving)
- Mission 13.4: Intensity/category distribution (intensity label accuracy)

---

[VERIFICATION START]

Implemented:
- approval workflow defined: YES
- scoring model added: YES
- review statuses added: YES
- injection rule defined: YES
- Knowledge Center updated: YES

Validated:
- sample review batch tested: YES
- approved prompts isolated correctly: YES
- rejected prompts excluded correctly: YES

Files:
- Created: docs/knowledge-center/mission-13-5-content-approval-pipeline.md
- Created: seeds/review/batch_001.json
- Created: seeds/inject_approved.ts

Notes:
Review-only fields (reviewStatus, reviewNotes, scores) are enforced out of production by inject_approved.ts.
Production IDs (q_{packId}_{NNN}) are assigned manually after operator reviews output — intentional gate.

[VERIFICATION END]

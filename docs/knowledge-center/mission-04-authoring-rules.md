# Mission 4.2 — Question Authoring Rules & Seed Contract

## Summary

Defines the authoritative rules for writing and seeding Meen Al Theeb questions.
These rules govern all future question generation (human-authored or AI-assisted),
quality review, and seed JSON file production.

Compatible with:
- `Question` Freezed model — `question.dart` (M3 schema: `status`, `intensity`, `ageRating`, `version`)
- `QuestionSeed` TypeScript interface — `seed_firestore.ts`
- `CategoryKeys` constants — `category_registry.dart` (M4.1 registry)
- `IntensityLevel`, `QuestionStatus`, `AgeRating` string constants — `question_enums.dart`

---

## 1. Seed JSON Schema Contract

Every question entry in a seed file (`seeds/questions_{packId}.json`) must conform to
the `QuestionSeed` interface used by `seed_firestore.ts`.

```json
{
  "id":        "q_{packId}_{NNN}",
  "packId":    "{CategoryKeys constant}",
  "textAr":    "النص العربي بصيغة سؤال؟",
  "textEn":    "English translation or equivalent phrasing.",
  "status":    "active",
  "intensity": "light | medium | spicy",
  "ageRating": "all | teen | adult"
}
```

### Field rules

| Field | Required | Valid values | Notes |
|---|---|---|---|
| `id` | ✅ | `q_{packId}_{NNN}` | Zero-padded 3-digit sequence. Must be globally unique. Never reuse a retired ID. |
| `packId` | ✅ | See §3 category keys | Must match a `CategoryKeys` constant. This IS the Firestore pack document ID. |
| `textAr` | ✅ | 10–200 chars | Must end with `؟` (U+061F). No newlines. Gulf Arabic dialect preferred over MSA. |
| `textEn` | ✅ | 10–200 chars | Must end with `?`. Empty string `""` permitted for initial batch but should be filled before launch. |
| `status` | recommended | `active`, `disabled`, `draft` | Default applied by seed script: `active`. Only `active` questions enter the session queue. |
| `intensity` | recommended | `light`, `medium`, `spicy` | Default: `medium`. Must match category matrix (§6). |
| `ageRating` | recommended | `all`, `teen`, `adult` | Default: `all`. `adult` is restricted to `age_21_plus` pack only. |

> **Note:** `status`, `intensity`, and `ageRating` may be omitted in the JSON — the seed script
> applies the same safe defaults as the Dart `@Default()` annotations. For new content, explicit
> values are strongly preferred to make the audit trail clear.

---

## 2. Game Format Constraint

All questions must follow the **"من في هذه الجلسة...؟"** format — a single-round group
vote where players nominate one person.

### A valid question must:

- Point to a specific **observable behavior or trait** (not a hypothetical or opinion)
- Be answerable immediately by the group without writing, drawing, or prior preparation
- Generate a reaction: laughter, a revelation, or playful conflict
- Be specific enough to force a clear nomination (not "everyone equally" or "no one")
- Stand alone — require no context outside the current session

### A question is disqualified if it:

- Requires private history the group may not share (e.g., childhood events)
- Has only one obviously correct answer with no drama (e.g., "من الأكبر في العمر؟")
- Is phrased as a statement, not a question
- Does not end with `؟`
- Names a real person, celebrity, politician, or brand

---

## 3. Seed File and Pack ID Map

| `CategoryKeys` constant | Firestore pack doc ID | Seed file |
|---|---|---|
| `CategoryKeys.friends` | `friends` | `questions_friends.json` |
| `CategoryKeys.funnyChaos` | `funny_chaos` | `questions_funny_chaos.json` |
| `CategoryKeys.embarrassing` | `embarrassing` | `questions_embarrassing.json` |
| `CategoryKeys.savage` | `savage` | `questions_savage.json` |
| `CategoryKeys.deepExposing` | `deep_exposing` | `questions_deep_exposing.json` |
| `CategoryKeys.majlisGcc` | `majlis_gcc` | `questions_majlis_gcc.json` |
| `CategoryKeys.couples` | `couples` | `questions_couples.json` |
| `CategoryKeys.age21Plus` | `age_21_plus` | `questions_age_21_plus.json` |

> **Legacy migration (`majlis` → `majlis_gcc`):**
> The pre-M4 pack used document ID `majlis` and seed file `questions_majlis.json`.
> The canonical key from M4.1 is `majlis_gcc`. New questions must target `majlis_gcc`.
> Existing `majlis` questions should be re-seeded with `packId: "majlis_gcc"` and renumbered
> `q_majlis_gcc_NNN` before launch. Until then, both pack IDs may coexist in Firestore.
>
> The `seedAllQuestions()` function in `seed_firestore.ts` must be updated to reference
> all 8 files before M4.3 (question seeding).

---

## 4. Per-Category Authoring Rules

### 4.1 `friends`

| | |
|---|---|
| **Tone** | Warm, playful, observational. Celebrates group dynamics without targeting anyone negatively. |
| **Intensity** | `light` (primary), `medium` acceptable |
| **ageRating** | `all` only |
| **Focus** | Shared habits, group roles, recurring behaviors: who sleeps the most, who's always late, who grabs from others' plates. |
| **Avoid** | Romantic/sexual content, money references, family criticism, anything that feels like a genuine accusation. |
| **Archetype** | "من أكثر شخص في الجلسة يتأخر على المواعيد؟" |

---

### 4.2 `funny_chaos`

| | |
|---|---|
| **Tone** | Absurdist, ridiculous. The question itself should provoke laughter before the answer does. |
| **Intensity** | `light` (primary), `medium` acceptable |
| **ageRating** | `all` only |
| **Focus** | Improbable but plausible scenarios, exaggerated behavior, surreal social situations. |
| **Avoid** | Dark humor, exclusionary punchlines, forced edginess, anything that requires explanation. |
| **Archetype** | "من يبدو وكأنه يمثل في فيلم وهو يطلب طلبه من الكافيه؟" |

---

### 4.3 `embarrassing`

| | |
|---|---|
| **Tone** | Cringe-inducing but affectionate. Should make people laugh at themselves, not feel attacked. |
| **Intensity** | `medium` (primary), `light` and occasional `spicy` acceptable |
| **ageRating** | `all` (mild), `teen` (clean-suggestive) |
| **Focus** | Past social mishaps, awkward behaviors, self-sabotaging habits. |
| **Avoid** | Physical appearance mockery, financial shaming, anything that could genuinely humiliate rather than amuse. |
| **Archetype** | "من أرسل رسالة غلط لشخص ما كان المفروض يشوفها؟" |

---

### 4.4 `savage`

| | |
|---|---|
| **Tone** | Honest, pointed, slightly ruthless. Edgy but fair — targets universally recognizable behavior patterns, not personal wounds. |
| **Intensity** | `medium` (primary), `spicy` acceptable |
| **ageRating** | `all`, `teen` |
| **Focus** | Hypocrisy, overcompensation, passive-aggression, pretentiousness. |
| **Avoid** | Physical attributes, family, financial status, anything that could genuinely damage a friendship. |
| **Archetype** | "من يقول 'ما عندي مشكلة' وعنده أكبر مشكلة؟" |

---

### 4.5 `deep_exposing`

| | |
|---|---|
| **Tone** | Calm, direct, serious undertone. Goes beneath the surface without cruelty. Revelations should feel earned, not ambush-style. |
| **Intensity** | `medium` to `spicy` |
| **ageRating** | `all`, `teen` |
| **Focus** | Genuine confessions, hidden feelings, private opinions about the group, real vulnerabilities masked by confident exteriors. |
| **Avoid** | Exposing genuinely painful personal history uninvited. The question should feel bold, not cruel. |
| **Archetype** | "من يبدو قوياً من الخارج لكن يتحطم من أبسط شيء؟" |

---

### 4.6 `majlis_gcc`

| | |
|---|---|
| **Tone** | Warm, culturally resonant, rooted in Gulf Arab social norms — family gatherings, diwaniyyas, traditional hospitality customs. |
| **Intensity** | `light` (primary), `medium` acceptable |
| **ageRating** | `all` only |
| **Focus** | Family dynamics, generational humor, Gulf cultural habits, collective GCC experiences. |
| **Avoid** | Content that disrespects religious or cultural values; non-Gulf references that break immersion. |
| **Archetype** | "من يقلد كبار أهله أكثر مما يتوقع؟" |

---

### 4.7 `couples`

| | |
|---|---|
| **Tone** | Playful and romantic. Warm disclosure rather than confrontation. Assumes a mixed group where not everyone is coupled. |
| **Intensity** | `medium` (primary), `light` and occasional `spicy` acceptable |
| **ageRating** | `all`, `teen` |
| **Focus** | Relationship dynamics, romantic habits, partner observations, shared couple behaviors. |
| **Avoid** | Explicit sexual content (belongs in `age_21_plus`), content that could trigger genuine relationship insecurity. |
| **Archetype** | "من يتذكر كل التفاصيل الصغيرة في علاقته؟" |

---

### 4.8 `age_21_plus`

| | |
|---|---|
| **Tone** | Bold, adult, explicit. Maintains the "who in the group" format — not generic adult trivia. |
| **Intensity** | `spicy` **only** |
| **ageRating** | `adult` **only** (mandatory, no exceptions) |
| **Focus** | Adult social behavior, mature relationship themes, explicit but non-graphic content. |
| **Avoid** | Graphic sexual descriptions, content that could be construed as harassment, anything singling out a person's body. |
| **Archetype** | Same group-nomination format as other packs, addressing adult behaviors and mature situations. |
| **Lobby gate** | The lobby must require age confirmation before enabling this pack. Any session including `age_21_plus` must configure `ContentFilters(maxAgeRating: AgeRating.adult)`. |

---

## 5. Duplication Avoidance Policy

Similarity is determined by **semantic meaning, not string matching**.

### Same-pack duplicates — banned

Two questions are duplicates if they would produce the same nomination in a typical group:

| Example A | Example B | Verdict |
|---|---|---|
| "من أكثر شخص يتأخر على المواعيد؟" | "من دائماً آخر شخص يوصل؟" | ❌ Duplicate — same observable behavior |
| "من ينام كثيراً؟" | "من يحب النوم الكثير؟" | ❌ Duplicate — same trait |
| "من ينسى أشياء كثيرة؟" | "من دماغه مشغولة دايماً؟" | ✅ Distinct — different root trait |

### Cross-pack duplicates — discouraged

Near-identical wording must not appear in two packs. A similar scenario with
a clearly different tone (e.g., the `friends` version is warm, the `savage` version
is pointed) is acceptable if the wording is distinct and the tone gap is evident.

### ID retirement rule

Question IDs are sequential and never recycled. If `q_friends_042` is deleted,
the next new question is `q_friends_043`, not `q_friends_042`.

---

## 6. Intensity × Age Rating Compatibility Matrix

| Category | `light` | `medium` | `spicy` | Allowed `ageRating` |
|---|---|---|---|---|
| `friends` | ✅ primary | ✅ | ❌ | `all` |
| `funny_chaos` | ✅ primary | ✅ | ❌ | `all` |
| `embarrassing` | ✅ | ✅ primary | ✅ (rare) | `all`, `teen` |
| `savage` | ✅ | ✅ primary | ✅ | `all`, `teen` |
| `deep_exposing` | ❌ | ✅ primary | ✅ | `all`, `teen` |
| `majlis_gcc` | ✅ primary | ✅ | ❌ | `all` |
| `couples` | ✅ | ✅ primary | ✅ (rare) | `all`, `teen` |
| `age_21_plus` | ❌ | ❌ | ✅ **only** | `adult` **only** |

A question seeded outside this matrix is not rejected by the engine but will be
flagged during content review.

---

## 7. Banned Patterns (All Categories)

The following are hard bans across every category:

- Named real individuals (celebrities, politicians, public figures, players' contacts)
- Geographic references beyond cultural region (GCC/Arab world)
- Content implying illegal activity
- Negative references to physical appearance
- Questions that could serve as genuine harassment evidence if screenshot
- Exact or near-exact wording that appeared in any previously published question

---

## 8. Pre-Commit Review Checklist

> ⚠️ **Superseded by Mission 13.1.** Use the checklist in `mission-13-1-prompt-system.md` §8 for all new and rewritten prompts. The items below are kept for historical reference only.

Before adding a question to a seed JSON file:

- [ ] ~~Ends with `؟`~~ (Mission 13.1: prompts are now declarative — must NOT end with `؟`)
- [ ] `packId` matches a valid `CategoryKeys` constant
- [ ] `intensity` and `ageRating` are within the category matrix (§6)
- [ ] Does not semantically duplicate an existing question in the same pack (§5)
- [ ] Does not name a real person, place, or brand
- [ ] Forces a clear group nomination (more than one plausible candidate; not "everyone equally")
- [ ] Arabic is natural Gulf dialect — not formal Modern Standard Arabic
- [ ] `textEn` is present or explicitly set to `""` — never omitted from the JSON object
- [ ] `id` follows `q_{packId}_{NNN}` format and has not been used before

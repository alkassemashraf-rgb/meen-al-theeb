"""
clean_questions.py

Pipeline:
  1. Parse malformed 500_questions.json (multiple disconnected arrays → regex extraction)
  2. Validate required fields
  3. Normalize Arabic text (for comparison only)
  4. Remove exact duplicates (by normalized text)
  5. Remove semantic duplicates (TF-IDF cosine similarity > 0.88)
  6. Re-index IDs sequentially: q_0001, q_0002, ...
  7. Write Dataset/500_questions_clean.json (valid JSON)
  8. Print report

Usage:
  cd "/Users/ashrafal-kassem/Desktop/مين الذيب؟ | Meen Al Theeb"
  pip3 install scikit-learn   # if not already installed
  python3 Dataset/clean_questions.py
"""

import re
import json
import os
import sys

try:
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity
except ImportError:
    sys.exit("❌ scikit-learn not installed. Run: pip3 install scikit-learn")

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_PATH = os.path.join(SCRIPT_DIR, "500_questions.json")
OUTPUT_PATH = os.path.join(SCRIPT_DIR, "500_questions_clean.json")

SIMILARITY_THRESHOLD = 0.88

REQUIRED_FIELDS = {"id", "packId", "textAr", "intensity", "ageRating"}
VALID_PACKS = {"age_21_plus", "deep_exposing", "savage", "embarrassing", "funny_chaos"}
VALID_INTENSITIES = {"light", "medium", "spicy"}
VALID_AGE_RATINGS = {"all", "adult"}

# ---------------------------------------------------------------------------
# Step 1: Parse malformed JSON via regex
# ---------------------------------------------------------------------------
# The file contains 5 disconnected JSON arrays (no comma between them).
# json.load() fails at line 43. We extract every {...} object via regex instead.

print("Loading Dataset/500_questions.json …")
with open(INPUT_PATH, encoding="utf-8") as f:
    raw = f.read()

# Extract all {...} objects. Questions have no nested braces so this is safe.
raw_objects = re.findall(r"\{[^{}]+\}", raw)

questions = []
for obj_str in raw_objects:
    try:
        d = json.loads(obj_str)
        if "textAr" in d and "id" in d:
            questions.append(d)
    except json.JSONDecodeError:
        pass

original_count = len(questions)
print(f"  Parsed {original_count} question objects")

# ---------------------------------------------------------------------------
# Step 2: Validate required fields
# ---------------------------------------------------------------------------

validated = []
validation_removed = 0

for q in questions:
    missing = REQUIRED_FIELDS - q.keys()
    if missing:
        validation_removed += 1
        continue
    if (
        q["packId"] not in VALID_PACKS
        or q["intensity"] not in VALID_INTENSITIES
        or q["ageRating"] not in VALID_AGE_RATINGS
        or not isinstance(q["textAr"], str)
        or not q["textAr"].strip()
    ):
        validation_removed += 1
        continue
    validated.append(q)

print(f"  After validation: {len(validated)} (removed {validation_removed})")

# ---------------------------------------------------------------------------
# Step 3: Normalize Arabic text (comparison only — never stored)
# ---------------------------------------------------------------------------

def normalize_arabic(text: str) -> str:
    # Keep only Arabic Unicode block + spaces
    text = re.sub(r"[^\u0600-\u06FF\s]", "", text)
    # Alef variants → ا
    text = re.sub(r"[أإآٱ]", "ا", text)
    # ى → ي
    text = text.replace("ى", "ي")
    # ة → ه (comparison only)
    text = text.replace("ة", "ه")
    # Remove tatweel (U+0640)
    text = text.replace("\u0640", "")
    # Remove diacritics (harakat) U+064B–U+065F
    text = re.sub(r"[\u064B-\u065F]", "", text)
    # Collapse whitespace
    return re.sub(r"\s+", " ", text).strip()

# ---------------------------------------------------------------------------
# Step 4: Exact deduplication (by normalized text)
# ---------------------------------------------------------------------------

seen_keys: dict[str, bool] = {}
exact_deduplicated = []
exact_duplicates_removed = 0

for q in validated:
    key = normalize_arabic(q["textAr"])
    if key in seen_keys:
        exact_duplicates_removed += 1
    else:
        seen_keys[key] = True
        exact_deduplicated.append(q)

print(f"  After exact dedup: {len(exact_deduplicated)} (removed {exact_duplicates_removed})")

# ---------------------------------------------------------------------------
# Step 5: Semantic deduplication via TF-IDF cosine similarity
# ---------------------------------------------------------------------------
# char_wb n-grams handle Arabic morphology better than word-level on short texts.
# sublinear_tf reduces weight of the shared "فيكم واحد" prefix.

corpus = [normalize_arabic(q["textAr"]) for q in exact_deduplicated]

vectorizer = TfidfVectorizer(
    analyzer="char_wb",
    ngram_range=(2, 4),
    sublinear_tf=True,
)
tfidf_matrix = vectorizer.fit_transform(corpus)

# Pairwise cosine similarity — N~270, so ~73K pairs, trivially fast
sim_matrix = cosine_similarity(tfidf_matrix)

# For each pair (i, j) where i < j: if sim > threshold → remove j (keep i = earlier)
to_remove: set[int] = set()
n = len(exact_deduplicated)

for i in range(n):
    if i in to_remove:
        continue
    for j in range(i + 1, n):
        if j in to_remove:
            continue
        if sim_matrix[i, j] > SIMILARITY_THRESHOLD:
            to_remove.add(j)

semantic_duplicates_removed = len(to_remove)
semantic_deduplicated = [q for idx, q in enumerate(exact_deduplicated) if idx not in to_remove]

print(f"  After semantic dedup: {len(semantic_deduplicated)} (removed {semantic_duplicates_removed})")

# ---------------------------------------------------------------------------
# Step 6: Re-index IDs sequentially
# ---------------------------------------------------------------------------

final_questions = []
for idx, q in enumerate(semantic_deduplicated, start=1):
    final_questions.append({
        "id": f"q_{idx:04d}",
        "packId": q["packId"],
        "textAr": q["textAr"],   # original, unnormalized
        "intensity": q["intensity"],
        "ageRating": q["ageRating"],
    })

final_count = len(final_questions)

# ---------------------------------------------------------------------------
# Step 7: Write output (valid JSON)
# ---------------------------------------------------------------------------

output = {
    "version": "meen_al_theeb_questions_v2_clean",
    "totalQuestions": final_count,
    "packs": ["age_21_plus", "deep_exposing", "savage", "embarrassing", "funny_chaos"],
    "questions": final_questions,
}

with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

# ---------------------------------------------------------------------------
# Step 8: Report
# ---------------------------------------------------------------------------

print()
print("=== Clean Report ===")
print(f"original_count:              {original_count}")
print(f"validation_removed:          {validation_removed}")
print(f"exact_duplicates_removed:    {exact_duplicates_removed}")
print(f"semantic_duplicates_removed: {semantic_duplicates_removed}")
print(f"final_count:                 {final_count}")
print(f"upload_status:               pending (run seed_question_bank.ts next)")
print(f"\nOutput: {OUTPUT_PATH}")

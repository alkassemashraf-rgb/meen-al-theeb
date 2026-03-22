"""
inject_question_bank.py

Injects Dataset/500_questions_clean.json into Firestore collection `question_bank`.
Uses Python firebase-admin SDK (installed to ~/Library/Python, not on iCloud Drive).

Usage:
  pip3 install firebase-admin          # one-time setup
  cd "/path/to/Meen Al Theeb"
  GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/secrets/serviceAccountKey.json" \
    python3 Dataset/inject_question_bank.py

Collection written:
  question_bank/{questionId}

Idempotent: running twice overwrites with the same data.
"""

import json
import os
import sys
from datetime import datetime, timezone

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    sys.exit("❌ firebase-admin not installed. Run: pip3 install firebase-admin")

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_PATH = os.path.join(SCRIPT_DIR, "500_questions_clean.json")
CREDENTIALS_PATH = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")

# ---------------------------------------------------------------------------
# Init Firebase
# ---------------------------------------------------------------------------

if not CREDENTIALS_PATH:
    sys.exit("❌ GOOGLE_APPLICATION_CREDENTIALS env var not set.")
if not os.path.exists(CREDENTIALS_PATH):
    sys.exit(f"❌ Credentials file not found: {CREDENTIALS_PATH}")

cred = credentials.Certificate(CREDENTIALS_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

# ---------------------------------------------------------------------------
# Read clean dataset
# ---------------------------------------------------------------------------

print(f"Reading {INPUT_PATH} …")
with open(INPUT_PATH, encoding="utf-8") as f:
    dataset = json.load(f)

questions = dataset["questions"]
print(f"Loaded {len(questions)} questions")

# ---------------------------------------------------------------------------
# Inject in batches of 500
# ---------------------------------------------------------------------------

COLLECTION = "question_bank"
BATCH_SIZE = 500
written = 0

print(f"\n── Seeding {COLLECTION} ──")

for i in range(0, len(questions), BATCH_SIZE):
    chunk = questions[i:i + BATCH_SIZE]
    batch = db.batch()

    for q in chunk:
        doc_ref = db.collection(COLLECTION).document(q["id"])
        batch.set(doc_ref, {
            "packId": q["packId"],
            "textAr": q["textAr"],
            "intensity": q["intensity"],
            "ageRating": q["ageRating"],
            "createdAt": datetime.now(timezone.utc),
        })

    batch.commit()
    written += len(chunk)
    print(f"  ✓ Batch committed: {written}/{len(questions)}")

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print(f"\nupload_status: OK — {written} documents written to {COLLECTION}")
print("\n✅ Injection complete.")

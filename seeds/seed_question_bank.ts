/**
 * seed_question_bank.ts
 *
 * Injects cleaned question bank into Firestore collection `question_bank`.
 * Reads from Dataset/500_questions_clean.json (output of Dataset/clean_questions.py).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./secrets/serviceAccountKey.json \
 *     node --loader ts-node/esm seeds/seed_question_bank.ts
 *
 * Collection written:
 *   question_bank/{questionId}   ← cleaned question documents
 *
 * Idempotent: running twice overwrites with the same data.
 */

import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import admin from 'firebase-admin';
const { credential } = admin;
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------------------------------------------------------------------------
// Firebase init
// ---------------------------------------------------------------------------

initializeApp({
  credential: credential.applicationDefault(),
});

const db = getFirestore();

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CleanQuestion {
  id: string;
  packId: string;
  textAr: string;
  intensity: string;
  ageRating: string;
}

interface CleanDataset {
  version: string;
  totalQuestions: number;
  packs: string[];
  questions: CleanQuestion[];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function readCleanDataset(): CleanDataset {
  // __dirname is seeds/ — go up one level to reach Dataset/
  const filePath = path.join(__dirname, '..', 'Dataset', '500_questions_clean.json');
  const raw = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(raw) as CleanDataset;
}

async function writeBatched(
  collection: FirebaseFirestore.CollectionReference,
  docs: Array<{ id: string; data: Record<string, unknown> }>,
): Promise<number> {
  const BATCH_SIZE = 500;
  let written = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const chunk = docs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    for (const { id, data } of chunk) {
      const ref = collection.doc(id);
      batch.set(ref, data);
    }

    await batch.commit();
    written += chunk.length;
    console.log(`  ✓ Batch committed: ${written}/${docs.length}`);
  }

  return written;
}

// ---------------------------------------------------------------------------
// Seed
// ---------------------------------------------------------------------------

async function seedQuestionBank(): Promise<void> {
  console.log('\n── Seeding question_bank ──');

  const dataset = readCleanDataset();
  console.log(`Loaded ${dataset.questions.length} questions (header totalQuestions: ${dataset.totalQuestions})`);

  const collection = db.collection('question_bank');

  const docs = dataset.questions.map((q) => {
    const { id, ...data } = q;
    return {
      id,
      data: {
        ...data,
        createdAt: FieldValue.serverTimestamp(),
      } as Record<string, unknown>,
    };
  });

  const count = await writeBatched(collection, docs);
  console.log(`\nupload_status: OK — ${count} documents written to question_bank`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

(async () => {
  try {
    console.log('Starting question_bank seed…');
    await seedQuestionBank();
    console.log('\n✅ Seed complete.');
    process.exit(0);
  } catch (err) {
    console.error('\n❌ Seed failed:', err);
    process.exit(1);
  }
})();

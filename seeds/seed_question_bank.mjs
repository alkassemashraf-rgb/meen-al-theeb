/**
 * seed_question_bank.mjs
 *
 * Plain ESM JavaScript — no TypeScript compilation required.
 * Works with Node.js v24+ without ts-node or tsx.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./secrets/serviceAccountKey.json \
 *     node seeds/seed_question_bank.mjs
 */

import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const { credential } = admin;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------------------------------------------------------------------------
// Firebase init
// ---------------------------------------------------------------------------

initializeApp({ credential: credential.applicationDefault() });
const db = getFirestore();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function readCleanDataset() {
  const filePath = path.join(__dirname, '..', 'Dataset', '500_questions_clean.json');
  const raw = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(raw);
}

async function writeBatched(collection, docs) {
  const BATCH_SIZE = 500;
  let written = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const chunk = docs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const { id, data } of chunk) {
      batch.set(collection.doc(id), data);
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

async function seedQuestionBank() {
  console.log('\n── Seeding question_bank ──');

  const dataset = readCleanDataset();
  console.log(`Loaded ${dataset.questions.length} questions`);

  const collection = db.collection('question_bank');

  const docs = dataset.questions.map(({ id, packId, textAr, intensity, ageRating }) => ({
    id,
    data: {
      packId,
      textAr,
      intensity,
      ageRating,
      createdAt: FieldValue.serverTimestamp(),
    },
  }));

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

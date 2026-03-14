/**
 * seed_firestore.ts
 *
 * Imports launch content (packs + questions) into Firestore.
 *
 * Prerequisites:
 *   npm install -g ts-node typescript
 *   npm install firebase-admin
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json npx ts-node seeds/seed_firestore.ts
 *
 * serviceAccountKey.json must NOT be committed to the repo.
 * Add it to .gitignore before use.
 *
 * Collections written:
 *   questionPacks/{packId}    ← pack metadata
 *   questions/{questionId}    ← question documents
 *
 * Idempotent: running twice will overwrite with the same data (no duplicates).
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

// ---------------------------------------------------------------------------
// Firebase init
// ---------------------------------------------------------------------------

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface PackSeed {
  id: string;
  name: string;
  description: string;
  language: string;
  questionCount: number;
  icon: string;
  isPremium: boolean;
}

interface QuestionSeed {
  id: string;
  packId: string;
  textAr: string;
  textEn: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function readJson<T>(filename: string): T {
  const filePath = path.join(__dirname, filename);
  const raw = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(raw) as T;
}

/**
 * Writes documents to Firestore in batches of up to 500 operations.
 * Returns the total number of documents written.
 */
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
// Seed packs
// ---------------------------------------------------------------------------

async function seedPacks(): Promise<void> {
  console.log('\n── Seeding questionPacks ──');
  const packs = readJson<PackSeed[]>('packs.json');
  const collection = db.collection('questionPacks');

  const docs = packs.map((pack) => {
    const { id, ...data } = pack;
    return {
      id,
      data: {
        ...data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    };
  });

  const count = await writeBatched(collection, docs);
  console.log(`Packs written: ${count}`);
}

// ---------------------------------------------------------------------------
// Seed questions
// ---------------------------------------------------------------------------

async function seedQuestions(filename: string): Promise<number> {
  const questions = readJson<QuestionSeed[]>(filename);
  const collection = db.collection('questions');

  const docs = questions.map((q) => {
    const { id, ...data } = q;
    return { id, data: data as Record<string, unknown> };
  });

  return writeBatched(collection, docs);
}

async function seedAllQuestions(): Promise<void> {
  console.log('\n── Seeding questions ──');

  const files = [
    'questions_friends.json',
    'questions_embarrassing.json',
    'questions_majlis.json',
    'questions_couples.json',
  ];

  let total = 0;
  for (const file of files) {
    console.log(`\nProcessing ${file}…`);
    const count = await seedQuestions(file);
    console.log(`  → ${count} questions written`);
    total += count;
  }

  console.log(`\nTotal questions written: ${total}`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

(async () => {
  try {
    console.log('Starting Firestore seed…');

    await seedPacks();
    await seedAllQuestions();

    console.log('\n✅ Seed complete.');
    process.exit(0);
  } catch (err) {
    console.error('\n❌ Seed failed:', err);
    process.exit(1);
  }
})();

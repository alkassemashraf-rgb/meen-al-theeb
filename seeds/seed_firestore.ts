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

interface PackSeed {
  id: string;
  name: string;
  description: string;
  language: string;
  questionCount: number;
  icon: string;
  isPremium: boolean;
  // Mission 3 optional fields — defaults applied in seedPacks()
  minAgeRating?: string;
  isEnabled?: boolean;
  dominantIntensity?: string;
}

interface QuestionSeed {
  id: string;
  packId: string;
  textAr: string;
  textEn: string;
  // Mission 3 optional fields — defaults applied in seedQuestions()
  status?: string;
  intensity?: string;
  ageRating?: string;
}

// ---------------------------------------------------------------------------
// Feature flags
// ---------------------------------------------------------------------------

/**
 * Set to true to delete ALL documents from the `questions` collection before
 * seeding. This is a destructive, irreversible operation — use with care.
 * Set to false to skip deletion and only write/overwrite documents.
 */
const RESET_QUESTIONS = true;

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
// Reset questions
// ---------------------------------------------------------------------------

/**
 * Deletes every document in the `questions` collection using batches of 500.
 * Idempotent: calling on an empty collection is a no-op.
 */
async function deleteAllQuestions(): Promise<void> {
  console.log('\n── Resetting questions collection ──');
  const collection = db.collection('questions');
  const BATCH_SIZE = 500;
  let totalDeleted = 0;

  while (true) {
    const snapshot = await collection.limit(BATCH_SIZE).get();
    if (snapshot.empty) break;

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    totalDeleted += snapshot.size;
    console.log(`  ✓ Deleted ${totalDeleted} so far…`);
  }

  console.log(`Reset complete. Total questions deleted: ${totalDeleted}`);
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
        // Mission 3: pack-level metadata with safe defaults
        minAgeRating: data.minAgeRating ?? 'all',
        isEnabled: data.isEnabled ?? true,
        dominantIntensity: data.dominantIntensity ?? 'medium',
        createdAt: FieldValue.serverTimestamp(),
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
    return {
      id,
      data: {
        ...data,
        // Mission 3: question-level metadata with safe defaults.
        // Questions in JSON files that omit these fields get the same defaults
        // as the Dart @Default() annotations in question.dart — staying in sync.
        status: data.status ?? 'active',
        intensity: data.intensity ?? 'medium',
        ageRating: data.ageRating ?? 'all',
      } as Record<string, unknown>,
    };
  });

  return writeBatched(collection, docs);
}

async function seedAllQuestions(): Promise<void> {
  console.log('\n── Seeding questions ──');

  const files = [
    'questions_friends.json',
    'questions_funny_chaos.json',
    'questions_embarrassing.json',
    'questions_savage.json',
    'questions_deep_exposing.json',
    'questions_majlis_gcc.json',
    'questions_couples.json',
    'questions_age_21_plus.json',
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

    if (RESET_QUESTIONS) {
      await deleteAllQuestions();
    }

    await seedPacks();
    await seedAllQuestions();

    console.log('\n✅ Seed complete.');
    process.exit(0);
  } catch (err) {
    console.error('\n❌ Seed failed:', err);
    process.exit(1);
  }
})();

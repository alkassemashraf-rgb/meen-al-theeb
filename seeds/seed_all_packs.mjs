/**
 * seed_all_packs.mjs
 *
 * Comprehensive seed for question_bank Firestore collection.
 * Combines:
 *  1. seeds/questions_*.json (pack files — include status, friends, majlis_gcc)
 *  2. Dataset/500_questions_clean.json (richer spicy content)
 *
 * Deduplicates by id. Excludes couples pack.
 * All questions written with status: 'active'.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./secrets/serviceAccountKey.json \
 *     node seeds/seed_all_packs.mjs
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

initializeApp({ credential: credential.applicationDefault() });
const db = getFirestore();

// ---------------------------------------------------------------------------
// Load sources
// ---------------------------------------------------------------------------

function loadPackFiles() {
  const seedsDir = __dirname;
  const packFiles = fs.readdirSync(seedsDir)
    .filter(f => f.startsWith('questions_') && f.endsWith('.json') && !f.includes('couples'));

  const all = [];
  for (const fname of packFiles) {
    const qs = JSON.parse(fs.readFileSync(path.join(seedsDir, fname), 'utf-8'));
    all.push(...qs);
    console.log(`  ${fname}: ${qs.length} questions`);
  }
  return all;
}

function loadDataset() {
  const filePath = path.join(__dirname, '..', 'Dataset', '500_questions_clean.json');
  if (!fs.existsSync(filePath)) {
    console.log('  Dataset/500_questions_clean.json not found, skipping.');
    return [];
  }
  const raw = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  const qs = Array.isArray(raw) ? raw : raw.questions;
  console.log(`  Dataset/500_questions_clean.json: ${qs.length} questions`);
  return qs;
}

// ---------------------------------------------------------------------------
// Merge & deduplicate
// ---------------------------------------------------------------------------

function merge(packQuestions, datasetQuestions) {
  const map = new Map();

  // Pack files first (they have status field, authoritative for friends/majlis_gcc)
  for (const q of packQuestions) {
    if (q.packId === 'couples') continue;
    map.set(q.id, q);
  }

  // Dataset second — only add questions NOT already present by id
  for (const q of datasetQuestions) {
    if (q.packId === 'couples') continue;
    if (!map.has(q.id)) {
      map.set(q.id, q);
    }
  }

  return Array.from(map.values());
}

// ---------------------------------------------------------------------------
// Write to Firestore
// ---------------------------------------------------------------------------

async function writeBatched(docs) {
  const BATCH_SIZE = 400;
  let written = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const chunk = docs.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const q of chunk) {
      const ref = db.collection('question_bank').doc(q.id);
      batch.set(ref, {
        packId:    q.packId,
        textAr:    q.textAr,
        textEn:    q.textEn || '',
        intensity: q.intensity,
        ageRating: q.ageRating,
        status:    'active',
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    written += chunk.length;
    console.log(`  ✓ ${written}/${docs.length} written`);
  }

  return written;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

(async () => {
  try {
    console.log('\n── Loading pack files ──');
    const packQs = loadPackFiles();

    console.log('\n── Loading dataset ──');
    const datasetQs = loadDataset();

    const merged = merge(packQs, datasetQs);

    // Stats
    const spicy  = merged.filter(q => q.intensity === 'spicy').length;
    const medium = merged.filter(q => q.intensity === 'medium').length;
    const light  = merged.filter(q => q.intensity === 'light').length;
    const packs  = [...new Set(merged.map(q => q.packId))].sort();

    console.log(`\n── Merged: ${merged.length} total questions ──`);
    console.log(`  spicy=${spicy}  medium=${medium}  light=${light}`);
    console.log(`  packs: ${packs.join(', ')}`);

    // Drop any questions with missing required fields
    const valid = merged.filter(q => q.id && q.packId && q.textAr && q.intensity && q.ageRating);
    const skipped = merged.length - valid.length;
    if (skipped > 0) console.log(`  (skipped ${skipped} questions with missing fields)`);

    console.log('\n── Writing to question_bank ──');
    await writeBatched(valid);

    console.log(`\n✅ Done. ${valid.length} questions written to question_bank.`);
    process.exit(0);
  } catch (err) {
    console.error('\n❌ Seed failed:', err);
    process.exit(1);
  }
})();

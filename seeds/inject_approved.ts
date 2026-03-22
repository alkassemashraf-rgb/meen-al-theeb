/**
 * inject_approved.ts
 *
 * Content Approval Pipeline — Mission 13.5
 *
 * Reads all review batch files from seeds/review/batch_*.json,
 * filters to approved items only, strips review-only fields,
 * and writes clean production-ready JSON files grouped by packId
 * to seeds/review/output/questions_{packId}_approved.json
 *
 * Usage:
 *   npx ts-node seeds/inject_approved.ts
 *
 * After reviewing the output files, manually append approved items
 * to the matching seeds/questions_{packId}.json and assign
 * production IDs (q_{packId}_{NNN}) before running seed_firestore.ts.
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// --- Types ---

interface ReviewItem {
  id: string;
  packId: string;
  textAr: string;
  textEn: string;
  intensity: string;
  ageRating: string;
  reviewStatus: 'draft' | 'approved' | 'rejected' | 'needs_rewrite';
  reviewNotes?: string;
  scores?: {
    specificity: number;
    socialRisk: number;
    recognitionSpeed: number;
    emotionalSting: number;
    replayValue: number;
  };
}

interface ProductionQuestion {
  id: string;
  packId: string;
  textAr: string;
  textEn: string;
  intensity: string;
  ageRating: string;
  status: 'active';
}

// --- Paths ---

const REVIEW_DIR = path.join(__dirname, 'review');
const OUTPUT_DIR = path.join(REVIEW_DIR, 'output');

// --- Helpers ---

function readReviewBatch(filePath: string): ReviewItem[] {
  const raw = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(raw) as ReviewItem[];
}

function stripReviewFields(item: ReviewItem): ProductionQuestion {
  return {
    id: item.id,       // Operator replaces with q_{packId}_{NNN} before seeding
    packId: item.packId,
    textAr: item.textAr,
    textEn: item.textEn,
    intensity: item.intensity,
    ageRating: item.ageRating,
    status: 'active',  // All injected questions default to active
  };
}

function groupByPack(items: ProductionQuestion[]): Record<string, ProductionQuestion[]> {
  return items.reduce((acc, item) => {
    if (!acc[item.packId]) acc[item.packId] = [];
    acc[item.packId].push(item);
    return acc;
  }, {} as Record<string, ProductionQuestion[]>);
}

// --- Main ---

function main(): void {
  // Collect all batch files
  const batchFiles = fs
    .readdirSync(REVIEW_DIR)
    .filter((f) => f.startsWith('batch_') && f.endsWith('.json'))
    .map((f) => path.join(REVIEW_DIR, f));

  if (batchFiles.length === 0) {
    console.log('No batch files found in seeds/review/. Nothing to process.');
    return;
  }

  // Read and flatten all items
  const allItems: ReviewItem[] = batchFiles.flatMap((f) => {
    console.log(`Reading: ${path.basename(f)}`);
    return readReviewBatch(f);
  });

  console.log(`Total items loaded: ${allItems.length}`);

  // Status breakdown
  const counts = { approved: 0, rejected: 0, needs_rewrite: 0, draft: 0 };
  for (const item of allItems) {
    counts[item.reviewStatus] = (counts[item.reviewStatus] ?? 0) + 1;
  }
  console.log(`  approved: ${counts.approved}`);
  console.log(`  needs_rewrite: ${counts.needs_rewrite}`);
  console.log(`  rejected: ${counts.rejected}`);
  console.log(`  draft: ${counts.draft}`);

  // Filter to approved only
  const approved = allItems.filter((item) => item.reviewStatus === 'approved');

  if (approved.length === 0) {
    console.log('\nNo approved items found. Nothing to inject.');
    return;
  }

  // Strip review fields
  const production = approved.map(stripReviewFields);

  // Group by packId
  const grouped = groupByPack(production);

  // Write output files
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  for (const [packId, items] of Object.entries(grouped)) {
    const outFile = path.join(OUTPUT_DIR, `questions_${packId}_approved.json`);
    fs.writeFileSync(outFile, JSON.stringify(items, null, 2), 'utf-8');
    console.log(`\nWrote ${items.length} approved item(s) → ${path.relative(process.cwd(), outFile)}`);
  }

  console.log('\nDone. Review output files, assign production IDs (q_{packId}_{NNN}), then append to seeds/questions_{packId}.json.');
}

main();

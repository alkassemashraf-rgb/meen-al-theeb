import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * resolveRound — Protected round resolution (Mission 10).
 *
 * Trigger: RTDB write to /rooms/{roomId}/currentRound/phase
 *
 * Fires on every phase change but only acts on → vote_locked.
 * The host client writes vote_locked (MVP); this function owns the rest:
 *   - duplicate guard (result already exists → skip)
 *   - vote tallying (reads currentRound/votes + eligiblePlayerIds)
 *   - tie / insufficient-votes / normal logic
 *   - atomic write of result + phase: result_ready
 *
 * Authority: System (Admin SDK bypasses RTDB rules).
 * The RTDB rule `currentRound/result: { .write: false }` blocks clients
 * from writing result directly; this function is the only writer.
 */
export const resolveRound = functions.database
  .ref('/rooms/{roomId}/currentRound/phase')
  .onWrite(async (change, context) => {
    // Only act on transitions → vote_locked
    if (change.after.val() !== 'vote_locked') return null;

    const roomId = context.params.roomId as string;
    const db = admin.database();
    const currentRoundRef = db.ref(`rooms/${roomId}/currentRound`);

    // ─── Duplicate guard ────────────────────────────────────────────────────
    // If a result already exists (concurrent trigger, Firebase retry, or
    // rapid double-write of vote_locked), skip silently.
    const resultSnap = await currentRoundRef.child('result').get();
    if (resultSnap.exists()) {
      functions.logger.info(
        `[resolveRound] room=${roomId}: result already exists — skipping (DuplicateResolutionIgnored)`
      );
      return null;
    }

    // ─── Read round state ────────────────────────────────────────────────────
    const roundSnap = await currentRoundRef.get();
    if (!roundSnap.exists()) {
      functions.logger.warn(`[resolveRound] room=${roomId}: currentRound missing — aborting`);
      return null;
    }

    const round = roundSnap.val() as Record<string, unknown>;

    const eligiblePlayerIds: string[] = Array.isArray(round['eligiblePlayerIds'])
      ? (round['eligiblePlayerIds'] as string[])
      : [];

    const rawVotes = (round['votes'] ?? {}) as Record<string, string>;
    const voteEntries = Object.entries(rawVotes);
    const totalVotes = voteEntries.length;

    functions.logger.info(
      `[resolveRound] room=${roomId}: ${totalVotes} vote(s) from ${eligiblePlayerIds.length} eligible player(s) — ResultComputationStarted`
    );

    // ─── Compute result ──────────────────────────────────────────────────────
    let result: Record<string, unknown>;

    if (totalVotes < 3) {
      // Insufficient votes rule: fewer than 3 valid votes → no winner
      result = {
        winningPlayerIds: [],
        voteCounts: {},
        resultType: 'insufficient_votes',
        totalValidVotes: totalVotes,
        computedAt: admin.database.ServerValue.TIMESTAMP,
      };
    } else {
      // Tally votes
      const counts: Record<string, number> = {};
      for (const [, targetId] of voteEntries) {
        counts[targetId] = (counts[targetId] ?? 0) + 1;
      }

      // Find max vote count
      const maxVotes = Math.max(...Object.values(counts));

      // Collect all players with that max (tie detection)
      const winners = Object.entries(counts)
        .filter(([, c]) => c === maxVotes)
        .map(([id]) => id);

      result = {
        winningPlayerIds: winners,
        voteCounts: counts,
        resultType: winners.length > 1 ? 'tie' : 'normal',
        totalValidVotes: totalVotes,
        computedAt: admin.database.ServerValue.TIMESTAMP,
      };
    }

    functions.logger.info(
      `[resolveRound] room=${roomId}: resultType=${result['resultType']} winners=${JSON.stringify(result['winningPlayerIds'])} — ResultComputed`
    );

    // ─── Write protected result ──────────────────────────────────────────────
    // Admin SDK bypasses RTDB rules. Multi-path update is atomic.
    // Writing phase: result_ready will re-trigger this function, but the
    // duplicate guard above will catch it and return immediately.
    await currentRoundRef.update({
      result,
      phase: 'result_ready',
    });

    functions.logger.info(`[resolveRound] room=${roomId}: phase → result_ready — ResultReady`);
    return null;
  });

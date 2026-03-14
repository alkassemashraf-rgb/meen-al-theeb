import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Placeholder: Verify Vote Submission (Future Missions)
export const onVoteSubmitted = functions.database.ref('/rooms/{roomId}/votes/{voterId}')
  .onCreate(async (snapshot, context) => {
    // Expected to validate that the voter exists, the target exists,
    // the game is currently in the voting phase, and lock the vote.
    const roomId = context.params.roomId;
    functions.logger.info(`Vote submitted in room ${roomId}`);
  });

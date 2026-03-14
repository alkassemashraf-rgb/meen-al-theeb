import * as admin from 'firebase-admin';

admin.initializeApp();

// Export function domains
export * from './room_validation';
export * from './round_validation';
export * from './vote_validation';
export * from './round_resolution'; // Mission 10: protected round resolution

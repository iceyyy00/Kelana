import { initializeApp } from 'firebase-admin/app';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import app from './server.js';

initializeApp();

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const googleDirectionsApiKey = defineSecret('GOOGLE_DIRECTIONS_API_KEY');

export const backend = onRequest(
  {
    region: 'asia-southeast1',
    secrets: [geminiApiKey, googleDirectionsApiKey],
    maxInstances: 10,
  },
  app,
);

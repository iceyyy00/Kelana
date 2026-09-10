import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  googlePlacesApiKey: process.env.GOOGLE_PLACES_API_KEY || process.env.GOOGLE_MAPS_API_KEY || '',
  googleDirectionsApiKey: process.env.GOOGLE_DIRECTIONS_API_KEY || process.env.GOOGLE_MAPS_API_KEY || '',
  mockMode: (process.env.MOCK_MODE || 'auto').toLowerCase(), // 'auto', 'always', 'never'
};

export function isGeminiAvailable() {
  return Boolean(config.geminiApiKey && config.geminiApiKey.trim() !== '');
}

export function isPlacesAvailable() {
  return Boolean(config.googlePlacesApiKey && config.googlePlacesApiKey.trim() !== '');
}

export function isDirectionsAvailable() {
  return Boolean(config.googleDirectionsApiKey && config.googleDirectionsApiKey.trim() !== '');
}

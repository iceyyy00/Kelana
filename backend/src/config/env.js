import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  get geminiApiKey() {
    return process.env.GEMINI_API_KEY || '';
  },
  get googlePlacesApiKey() {
    return process.env.GOOGLE_PLACES_API_KEY || process.env.GOOGLE_MAPS_API_KEY || '';
  },
  get googleDirectionsApiKey() {
    return process.env.GOOGLE_DIRECTIONS_API_KEY || process.env.GOOGLE_MAPS_API_KEY || '';
  },
  get mockMode() {
    return (process.env.MOCK_MODE || 'auto').toLowerCase();
  },
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

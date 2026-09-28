import app from './server.js';
import { config, isGeminiAvailable, isPlacesAvailable } from './config/env.js';

app.listen(config.port, () => {
  console.log('====================================================');
  console.log(`Kelana Backend Proxy is running on port ${config.port}`);
  console.log(`URL: http://localhost:${config.port}`);
  console.log(`Gemini API: ${isGeminiAvailable() ? 'Configured' : 'Missing (Smart Mock Mode enabled)'}`);
  console.log(`Places API: ${isPlacesAvailable() ? 'Configured' : 'Missing (Indonesian Datasets enabled)'}`);
  console.log('====================================================');
});

import express from 'express';
import cors from 'cors';
import { config, isGeminiAvailable, isPlacesAvailable, isDirectionsAvailable } from './config/env.js';
import apiRouter from './routes/api.js';

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[HTTP] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// Mount API routes
app.use('/api', apiRouter);

// Root informational page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Kelana Backend Proxy</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; margin: 0; }
        .card { max-width: 700px; margin: 0 auto; background: #1e293b; padding: 32px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
        h1 { color: #38bdf8; margin-top: 0; display: flex; align-items: center; gap: 12px; }
        .badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 13px; font-weight: 600; }
        .badge-green { background: #065f46; color: #34d399; }
        .badge-yellow { background: #854d0e; color: #facc15; }
        ul { line-height: 1.8; color: #94a3b8; }
        code { background: #0f172a; color: #f472b6; padding: 2px 6px; border-radius: 4px; font-family: monospace; }
        .endpoint { background: #0f172a; padding: 12px 16px; border-radius: 8px; margin-bottom: 8px; border-left: 4px solid #38bdf8; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>🧭 Kelana — AI Itinerary Backend Proxy</h1>
        <p>Backend Proxy berjalan aktif untuk melayani aplikasi Flutter Kelana.</p>
        <div style="margin: 20px 0;">
          <span class="badge ${isGeminiAvailable() ? 'badge-green' : 'badge-yellow'}">
            Gemini AI: ${isGeminiAvailable() ? 'Aktif (Live API)' : 'Mock / Heuristic Fallback'}
          </span>
          <span class="badge ${isPlacesAvailable() ? 'badge-green' : 'badge-yellow'}">
            Places API: ${isPlacesAvailable() ? 'Aktif (Live API)' : 'Curated Datasets'}
          </span>
          <span class="badge ${isDirectionsAvailable() ? 'badge-green' : 'badge-yellow'}">
            Directions API: ${isDirectionsAvailable() ? 'Aktif (Live API)' : 'Haversine Estimator'}
          </span>
        </div>
        <h3>Tersedia Endpoints:</h3>
        <div class="endpoint"><code>POST /api/parse-intent</code> - NLU intent parsing (Gemini Structured Output)</div>
        <div class="endpoint"><code>POST /api/search-places</code> - Rekomendasi tempat dari Places API / Datasets</div>
        <div class="endpoint"><code>POST /api/build-itinerary</code> - Optimasi urutan & rute perjalanan</div>
        <div class="endpoint"><code>GET /api/health</code> - Status kesehatan & konfigurasi server</div>
      </div>
    </body>
    </html>
  `);
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.originalUrl} tidak ditemukan.` });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('[Unhandled Error]', err);
  res.status(500).json({
    error: 'Terjadi kesalahan internal server.',
    message: err.message
  });
});

const PORT = config.port;
app.listen(PORT, () => {
  console.log('====================================================');
  console.log(`🧭 Kelana Backend Proxy is running on port ${PORT}`);
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log(`🔑 Gemini API: ${isGeminiAvailable() ? 'Configured ✅' : 'Missing (Smart Mock Mode enabled) ⚠️'}`);
  console.log(`🗺️ Places API: ${isPlacesAvailable() ? 'Configured ✅' : 'Missing (Indonesian Datasets enabled) ⚠️'}`);
  console.log('====================================================');
});

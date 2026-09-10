import express from 'express';
import { parseUserIntent, optimizeItinerary } from '../services/geminiService.js';
import { searchPlaces } from '../services/placesService.js';
import { calculateRouteAndTravelTimes } from '../services/directionsService.js';
import { config, isGeminiAvailable, isPlacesAvailable, isDirectionsAvailable } from '../config/env.js';

const router = express.Router();

// In-memory store for saved itineraries during runtime
const itinerariesStore = new Map();

/**
 * Health check & environment status
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    app: 'Kelana Backend API Proxy',
    version: '1.0.0',
    mode: config.mockMode,
    apiStatus: {
      geminiConfigured: isGeminiAvailable(),
      placesConfigured: isPlacesAvailable(),
      directionsConfigured: isDirectionsAvailable()
    },
    timestamp: new Date().toISOString()
  });
});

/**
 * 1. Parse user chat/query into structured travel intent
 * POST /api/parse-intent
 * Body: { query: string, preferences?: object }
 */
router.post('/parse-intent', async (req, res) => {
  try {
    const { query, preferences } = req.body;

    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return res.status(400).json({
        error: 'Parameter "query" wajib diisi dengan teks permintaan perjalanan.'
      });
    }

    console.log(`[API /parse-intent] Processing: "${query}"`);
    const parsedIntent = await parseUserIntent(query.trim(), preferences || {});

    return res.json({
      success: true,
      data: parsedIntent
    });
  } catch (error) {
    console.error('[API /parse-intent] Error:', error);
    return res.status(500).json({
      success: false,
      error: 'Gagal memproses niat perjalanan: ' + error.message
    });
  }
});

/**
 * 2. Search places matching intent criteria
 * POST /api/search-places
 * Body: { location: string, categories?: string[], budget?: number }
 */
router.post('/search-places', async (req, res) => {
  try {
    const intent = req.body || {};
    if (!intent.location) {
      intent.location = 'Semarang';
    }

    console.log(`[API /search-places] Searching places for ${intent.location}`);
    const places = await searchPlaces(intent);

    return res.json({
      success: true,
      count: places.length,
      data: places
    });
  } catch (error) {
    console.error('[API /search-places] Error:', error);
    return res.status(500).json({
      success: false,
      error: 'Gagal mencari tempat: ' + error.message
    });
  }
});

/**
 * 3. Build optimized itinerary from selected places
 * POST /api/build-itinerary
 * Body: { places: Place[], intent?: ParsedIntent }
 */
router.post('/build-itinerary', async (req, res) => {
  try {
    const { places, intent } = req.body;

    if (!places || !Array.isArray(places) || places.length === 0) {
      return res.status(400).json({
        error: 'Parameter "places" harus berupa array tempat (minimal 1 tempat).'
      });
    }

    console.log(`[API /build-itinerary] Building itinerary for ${places.length} places`);

    // Step 1: Gemini determines optimal stop ordering and activities
    const geminiOptimization = await optimizeItinerary(places, intent || {});

    // Step 2: Re-order places according to Gemini's recommendation or preserve order
    let orderedPlaces = [];
    if (geminiOptimization.stops && geminiOptimization.stops.length > 0) {
      // Map stops back to place objects
      orderedPlaces = geminiOptimization.stops.map(stop => {
        const originalPlace = places.find(p => p.placeId === stop.placeId) || places[0];
        return {
          ...originalPlace,
          order: stop.order,
          suggestedArrivalTime: stop.suggestedArrivalTime,
          suggestedDurationMinutes: stop.suggestedDurationMinutes,
          activityTip: stop.activityTip,
          visited: false
        };
      });
    } else {
      orderedPlaces = places.map((p, idx) => ({
        ...p,
        order: idx + 1,
        suggestedArrivalTime: `${9 + idx * 2}:00 WIB`,
        suggestedDurationMinutes: 60,
        activityTip: `Kunjungi dan nikmati destinasi ${p.name}.`,
        visited: false
      }));
    }

    // Step 3: Google Directions API calculates route & leg travel times
    const routeInfo = await calculateRouteAndTravelTimes(orderedPlaces);

    // Attach estimatedTravelTimeFromPrevious to places
    const enrichedPlaces = orderedPlaces.map((place, idx) => {
      let travelFromPrev = 0;
      if (idx > 0 && routeInfo.travelLegs[idx - 1]) {
        travelFromPrev = routeInfo.travelLegs[idx - 1].durationMinutes;
      }
      return {
        ...place,
        estimatedTravelTimeFromPrevious: travelFromPrev
      };
    });

    const itineraryResult = {
      id: 'itinerary_' + Date.now(),
      title: geminiOptimization.tripTitle || `Itinerary ${intent?.location || 'Kelana'}`,
      summary: geminiOptimization.summary || 'Rencana perjalanan tersusun rapi.',
      rawQuery: intent?.userNotes || '',
      location: intent?.location || enrichedPlaces[0]?.name || 'Semarang',
      totalEstimatedTravelMinutes: routeInfo.totalEstimatedTravelMinutes,
      travelLegs: routeInfo.travelLegs,
      polylinePoints: routeInfo.polylinePoints,
      places: enrichedPlaces,
      createdAt: new Date().toISOString(),
      status: 'draft'
    };

    return res.json({
      success: true,
      data: itineraryResult
    });
  } catch (error) {
    console.error('[API /build-itinerary] Error:', error);
    return res.status(500).json({
      success: false,
      error: 'Gagal menyusun itinerary: ' + error.message
    });
  }
});

/**
 * 4. CRUD Itineraries (Proxy / Local Store)
 */
router.get('/itineraries', (req, res) => {
  const items = Array.from(itinerariesStore.values());
  res.json({
    success: true,
    data: items
  });
});

router.post('/itineraries', (req, res) => {
  const itinerary = req.body;
  if (!itinerary || !itinerary.id) {
    const id = 'itin_' + Date.now();
    itinerary.id = id;
  }
  itinerary.updatedAt = new Date().toISOString();
  if (!itinerary.shareCode) {
    itinerary.shareCode = 'KLN-' + Math.random().toString(36).substring(2, 8).toUpperCase();
  }
  itinerariesStore.set(itinerary.id, itinerary);

  res.json({
    success: true,
    data: itinerary
  });
});

router.get('/itineraries/:id', (req, res) => {
  const item = itinerariesStore.get(req.params.id);
  if (!item) {
    return res.status(404).json({ error: 'Itinerary tidak ditemukan.' });
  }
  res.json({ success: true, data: item });
});

router.delete('/itineraries/:id', (req, res) => {
  const existed = itinerariesStore.delete(req.params.id);
  res.json({ success: existed });
});

router.get('/share/:shareCode', (req, res) => {
  const code = req.params.shareCode.toUpperCase();
  for (const item of itinerariesStore.values()) {
    if (item.shareCode === code) {
      return res.json({ success: true, data: item });
    }
  }
  return res.status(404).json({ error: 'Kode share tidak valid atau sudah kadaluarsa.' });
});

export default router;

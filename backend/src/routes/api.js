import express from 'express';
import { randomBytes } from 'node:crypto';
import axios from 'axios';
import { parseUserIntent, optimizeItinerary } from '../services/geminiService.js';
import { searchPlaces } from '../services/placesService.js';
import { calculateRouteAndTravelTimes } from '../services/directionsService.js';
import { config, isGeminiAvailable, isPlacesAvailable, isDirectionsAvailable } from '../config/env.js';
import { requireAuth } from '../middleware/requireAuth.js';
import {
  deleteItinerary,
  findItineraryByShareCode,
  getItinerary,
  listItineraries,
  saveItinerary,
} from '../services/itineraryStore.js';

const router = express.Router();

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
router.post('/parse-intent', requireAuth, async (req, res) => {
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
router.post('/search-places', requireAuth, async (req, res) => {
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
router.post('/build-itinerary', requireAuth, async (req, res) => {
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

router.get('/place-photos', async (req, res) => {
  const reference = req.query.reference;
  if (
    typeof reference !== 'string' ||
    reference.trim().length === 0 ||
    reference.length > 2048 ||
    /[\u0000-\u001f\u007f]/.test(reference)
  ) {
    return res.status(400).json({ success: false, error: 'Referensi foto tidak valid.' });
  }
  if (!config.googlePlacesApiKey) {
    return res.status(503).json({ success: false, error: 'Google Places API belum dikonfigurasi.' });
  }

  try {
    const response = await axios.get(
      'https://maps.googleapis.com/maps/api/place/photo',
      {
        params: {
          maxwidth: 800,
          photoreference: reference,
          key: config.googlePlacesApiKey,
        },
        responseType: 'arraybuffer',
        maxContentLength: 5 * 1024 * 1024,
        maxRedirects: 3,
        timeout: 8000,
      },
    );
    res.set('Content-Type', response.headers['content-type'] || 'image/jpeg');
    res.set('Cache-Control', 'public, max-age=86400');
    return res.status(200).send(Buffer.from(response.data));
  } catch (error) {
    console.error('[API /place-photos] Google Places photo request failed:', error.message);
    return res.status(502).json({ success: false, error: 'Gagal memuat foto tempat.' });
  }
});

/**
 * 4. CRUD Itineraries (Proxy / Local Store)
 */
router.get('/itineraries', requireAuth, async (req, res) => {
  try {
    const items = await listItineraries(req.user.uid);
    return res.json({ success: true, data: items });
  } catch (error) {
    console.error('[API /itineraries] Error loading itineraries:', error);
    return res.status(500).json({ success: false, error: 'Gagal memuat itinerary.' });
  }
});

router.post('/itineraries', requireAuth, async (req, res) => {
  try {
    if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body)) {
      return res.status(400).json({ success: false, error: 'Data itinerary tidak valid.' });
    }

    const itinerary = { ...req.body };
    if (itinerary.id != null && !/^[A-Za-z0-9_-]{1,128}$/.test(String(itinerary.id))) {
      return res.status(400).json({ success: false, error: 'ID itinerary tidak valid.' });
    }
    itinerary.id ||= 'itin_' + Date.now();
    itinerary.userId = req.user.uid;
    itinerary.updatedAt = new Date().toISOString();
    const existingItinerary = await getItinerary(req.user.uid, itinerary.id);
    itinerary.shareCode = existingItinerary?.shareCode ??
      'KLN-' + randomBytes(6).toString('hex').toUpperCase();

    await saveItinerary(req.user.uid, itinerary);
    return res.json({ success: true, data: itinerary });
  } catch (error) {
    console.error('[API /itineraries] Error saving itinerary:', error);
    return res.status(500).json({ success: false, error: 'Gagal menyimpan itinerary.' });
  }
});

router.get('/itineraries/:id', requireAuth, async (req, res) => {
  try {
    const item = (await listItineraries(req.user.uid)).find(({ id }) => id === req.params.id);
    if (!item) {
      return res.status(404).json({ success: false, error: 'Itinerary tidak ditemukan.' });
    }
    return res.json({ success: true, data: item });
  } catch (error) {
    console.error('[API /itineraries/:id] Error loading itinerary:', error);
    return res.status(500).json({ success: false, error: 'Gagal memuat itinerary.' });
  }
});

router.delete('/itineraries/:id', requireAuth, async (req, res) => {
  try {
    const deleted = await deleteItinerary(req.user.uid, req.params.id);
    return res.json({ success: deleted });
  } catch (error) {
    console.error('[API /itineraries/:id] Error deleting itinerary:', error);
    return res.status(500).json({ success: false, error: 'Gagal menghapus itinerary.' });
  }
});

router.get('/share/:shareCode', async (req, res) => {
  try {
    const item = await findItineraryByShareCode(req.params.shareCode.toUpperCase());
    if (item) {
      return res.json({ success: true, data: item });
    }
    return res.status(404).json({ error: 'Kode share tidak valid atau sudah kadaluarsa.' });
  } catch (error) {
    console.error('[API /share/:shareCode] Error finding shared itinerary:', error);
    return res.status(500).json({ success: false, error: 'Gagal memuat itinerary bersama.' });
  }
});

export default router;

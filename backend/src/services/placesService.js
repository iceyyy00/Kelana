import axios from 'axios';
import { config, isPlacesAvailable } from '../config/env.js';
import { getMockPlacesForLocation } from '../mock/destinationsData.js';

/**
 * Search places by intent criteria (location, category, budget)
 */
export async function searchPlaces(intent = {}) {
  const location = intent.location || 'Semarang';
  const categories = intent.categories || [];
  const budget = intent.budget || 0;

  if (config.mockMode === 'always' || !isPlacesAvailable()) {
    console.log(`[PlacesService] Using mock places dataset for: ${location}`);
    return getMockPlacesForLocation(location, categories, budget);
  }

  try {
    const query = `${categories.join(' ')} di ${location}`.trim();
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json`;

    const response = await axios.get(url, {
      params: {
        query,
        key: config.googlePlacesApiKey,
        language: 'id',
      },
      timeout: 8000
    });

    if (response.data.status !== 'OK' || !response.data.results || response.data.results.length === 0) {
      console.warn(`[PlacesService] Places API status: ${response.data.status}, fallback to mock data`);
      return getMockPlacesForLocation(location, categories, budget);
    }

    // Transform Google Places results to standardized format
    const transformed = response.data.results.slice(0, 10).map(p => {
      let photoUrl = "https://images.unsplash.com/photo-1596402184320-417e7178b2cd?w=600&auto=format&fit=crop&q=80";
      if (p.photos && p.photos.length > 0) {
        photoUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${p.photos[0].photo_reference}&key=${config.googlePlacesApiKey}`;
      }

      // Estimate price in IDR based on price_level
      let estimatedPrice = 20000;
      if (p.price_level === 0) estimatedPrice = 0;
      else if (p.price_level === 1) estimatedPrice = 25000;
      else if (p.price_level === 2) estimatedPrice = 75000;
      else if (p.price_level === 3) estimatedPrice = 200000;
      else if (p.price_level >= 4) estimatedPrice = 450000;

      return {
        placeId: p.place_id,
        name: p.name,
        category: (p.types && p.types[0]) ? p.types[0].replace(/_/g, ' ') : 'Destinasi Wisata',
        rating: p.rating || 4.5,
        userRatingsTotal: p.user_ratings_total || 100,
        priceLevel: p.price_level !== undefined ? p.price_level : 1,
        estimatedPrice,
        lat: p.geometry.location.lat,
        lng: p.geometry.location.lng,
        address: p.formatted_address || '',
        photoUrl,
        description: p.formatted_address || 'Destinasi populer rekomendasi Kelana.',
        openingHours: p.opening_hours && p.opening_hours.open_now ? "Sedang Buka" : "Buka setiap hari"
      };
    });

    return transformed;
  } catch (error) {
    console.error('[PlacesService] Error calling Google Places API:', error.message);
    return getMockPlacesForLocation(location, categories, budget);
  }
}

import axios from 'axios';
import { config } from '../config/env.js';
import { estimateOsmBudget, getTripBudgetContext } from './budgetService.js';
import { getMockPlacesForLocation } from '../mock/destinationsData.js';

const PHOTON_URL = 'https://photon.komoot.io/api/';
const PHOTON_REVERSE_URL = 'https://photon.komoot.io/reverse';

export function isUsablePhotonName(value) {
  const name = String(value || '').trim();
  const letters = name.match(/\p{L}/gu)?.length || 0;
  const digits = name.match(/\p{N}/gu)?.length || 0;
  const alphanumericCount = letters + digits;

  if (
    name.length < 3 ||
    name.length > 100 ||
    letters < 3 ||
    alphanumericCount === 0 ||
    letters / alphanumericCount < 0.5 ||
    /^(?:unknown|unnamed|no name|unclassified|object|node|way)\b/i.test(name)
  ) {
    return false;
  }

  return true;
}

function osmTagsForCategories(categories, budgetLevel) {
  const tags = new Set();
  for (const category of categories) {
    const value = String(category).toLowerCase();
    if (/kuliner|food|restaurant|cafe/.test(value)) {
      if (budgetLevel === 'budget') {
        tags.add('amenity:fast_food');
        tags.add('amenity:food_court');
      } else if (budgetLevel === 'luxury') {
        tags.add('amenity:restaurant');
      } else {
        tags.add('amenity:cafe');
        tags.add('amenity:restaurant');
      }
    } else if (/akomodasi|penginapan|hotel|hostel|camping|stay/.test(value)) {
      if (budgetLevel === 'budget') {
        tags.add('tourism:hostel');
        tags.add('tourism:camp_site');
        tags.add('tourism:guest_house');
      } else if (budgetLevel === 'luxury') {
        tags.add('tourism:hotel');
      } else {
        tags.add('tourism:hotel');
        tags.add('tourism:motel');
        tags.add('tourism:apartment');
      }
    }
    else if (/sejarah|historic|history/.test(value)) tags.add('historic');
    else if (/alam|nature|outdoor/.test(value)) tags.add('leisure:park');
    else if (/belanja|shopping/.test(value)) tags.add('shop');
    else if (/religi|religious|worship/.test(value)) tags.add('amenity:place_of_worship');
    else if (/keluarga|family|hiburan|entertainment/.test(value)) tags.add('tourism:attraction');
    else tags.add('tourism:attraction');
  }
  return [...(tags.size ? tags : ['tourism:attraction'])].slice(0, 6);
}

export function transformPhotonFeature(feature, peopleCount = 1, durationDays = 1) {
  const properties = feature?.properties || {};
  const coordinates = feature?.geometry?.coordinates;
  if (!Array.isArray(coordinates) || coordinates.length < 2) return null;

  const [longitude, latitude] = coordinates.map(Number);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

  const name = String(properties.name || '').trim();
  if (!isUsablePhotonName(name)) return null;
  const address = [
    [properties.housenumber, properties.street].filter(Boolean).join(' '),
    properties.city || properties.district,
    properties.state,
    properties.country,
  ].filter(Boolean).join(', ');
  const extra = properties.extra && typeof properties.extra === 'object'
    ? properties.extra
    : {};
  const cuisine = String(properties.cuisine || extra.cuisine || '');
  const stars = String(properties.stars || extra.stars || '');
  const fee = String(properties.fee || extra.fee || '');
  const budgetEstimate = estimateOsmBudget(properties, peopleCount, durationDays);
  const priceLevel = { free: 0, budget: 1, moderate: 2, luxury: 3 }[budgetEstimate.budgetTier];

  return {
    placeId: properties.osm_type && properties.osm_id
      ? `${properties.osm_type}:${properties.osm_id}`
      : `${latitude},${longitude}`,
    name,
    category: (properties.osm_value || properties.type || 'Destinasi Wisata').replace(/_/g, ' '),
    rating: 0,
    userRatingsTotal: 0,
    priceLevel,
    ...budgetEstimate,
    osmKey: properties.osm_key || '',
    osmValue: properties.osm_value || '',
    cuisine,
    stars,
    fee,
    lat: latitude,
    lng: longitude,
    address,
    photoUrl: '',
    description: address || 'Destinasi populer rekomendasi Kelana.',
    openingHours: properties.opening_hours || 'Buka setiap hari',
  };
}

/**
 * Search places by intent criteria (location, category, budget)
 */
export async function searchPlaces(intent = {}) {
  const location = String(intent.location || '').trim();
  if (!location) return [];
  const categories = intent.categories || [];
  const budget = intent.budget || 0;
  const { peopleCount, durationDays, budgetLevel } = getTripBudgetContext(intent);

  if (config.mockMode === 'always') {
    console.log(`[PlacesService] Using mock places dataset for: ${location}`);
    return getMockPlacesForLocation(location, categories, budget);
  }

  try {
    const locationResponse = await axios.get(PHOTON_URL, {
      params: {
        q: location,
        limit: 1,
        lang: 'en',
      },
      headers: { 'User-Agent': 'Kelana itinerary planner' },
      timeout: 8000,
    });
    const coordinates = locationResponse.data.features?.[0]?.geometry?.coordinates;
    if (!Array.isArray(coordinates) || coordinates.length < 2) {
      console.warn('[PlacesService] Photon could not geocode the requested location, falling back to mock data');
      return getMockPlacesForLocation(location, categories, budget);
    }

    const [longitude, latitude] = coordinates.map(Number);
    const osmTags = osmTagsForCategories(categories, budgetLevel);
    const responses = await Promise.all(osmTags.map(osmTag => axios.get(PHOTON_REVERSE_URL, {
      params: { lon: longitude, lat: latitude, radius: 10, limit: 10, lang: 'en', osm_tag: osmTag },
      headers: { 'User-Agent': 'Kelana itinerary planner' },
      timeout: 8000,
    })));

    const transformed = [];
    const seenPlaceIds = new Set();
    for (let index = 0; index < 10 && transformed.length < 10; index++) {
      for (const response of responses) {
        if (transformed.length >= 10) break;
        const feature = response.data.features?.[index];
        if (!feature) continue;

        const place = transformPhotonFeature(feature, peopleCount, durationDays);
        if (place && !seenPlaceIds.has(place.placeId)) {
          seenPlaceIds.add(place.placeId);
          transformed.push(place);
        }
      }
    }

    if (transformed.length === 0) {
      console.warn('[PlacesService] Photon returned no usable places, falling back to mock data');
      return getMockPlacesForLocation(location, categories, budget);
    }

    return transformed;
  } catch (error) {
    console.error('[PlacesService] Error calling Photon:', error.message);
    return getMockPlacesForLocation(location, categories, budget);
  }
}

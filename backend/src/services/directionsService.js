import axios from 'axios';
import { config, isDirectionsAvailable } from '../config/env.js';

/**
 * Calculate Haversine distance between two coordinates in kilometers
 */
function haversineDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Generate interpolated coordinates between waypoints for smooth map polyline rendering
 */
function generateMockRoutePolyline(points) {
  if (!points || points.length < 2) return points || [];
  const fullPath = [];

  for (let i = 0; i < points.length - 1; i++) {
    const p1 = points[i];
    const p2 = points[i + 1];
    fullPath.push({ lat: p1.lat, lng: p1.lng });

    // Insert 2 intermediate smooth steps
    const steps = 3;
    for (let s = 1; s < steps; s++) {
      const ratio = s / steps;
      fullPath.push({
        lat: p1.lat + (p2.lat - p1.lat) * ratio,
        lng: p1.lng + (p2.lng - p1.lng) * ratio,
      });
    }
  }
  fullPath.push({ lat: points[points.length - 1].lat, lng: points[points.length - 1].lng });
  return fullPath;
}

/**
 * Calculate travel times and route geometry between ordered places
 */
export async function calculateRouteAndTravelTimes(orderedPlaces) {
  if (!orderedPlaces || orderedPlaces.length <= 1) {
    return {
      travelLegs: [],
      totalEstimatedTravelMinutes: 0,
      polylinePoints: (orderedPlaces || []).map(p => ({ lat: p.lat, lng: p.lng }))
    };
  }

  // Fallback / mock route calculation
  const calculateHeuristicLegs = () => {
    const travelLegs = [];
    let totalMinutes = 0;

    for (let i = 0; i < orderedPlaces.length - 1; i++) {
      const from = orderedPlaces[i];
      const to = orderedPlaces[i + 1];
      const distKm = haversineDistanceKm(from.lat, from.lng, to.lat, to.lng);
      
      // Estimated urban speed in Indonesia: ~20 km/h + 5 mins buffer for traffic/parking
      const durationMinutes = Math.max(8, Math.round((distKm / 20) * 60) + 4);
      totalMinutes += durationMinutes;

      travelLegs.push({
        fromPlaceId: from.placeId,
        toPlaceId: to.placeId,
        fromName: from.name,
        toName: to.name,
        distanceKm: parseFloat(distKm.toFixed(1)),
        durationMinutes,
        durationText: `${durationMinutes} menit`
      });
    }

    const polylinePoints = generateMockRoutePolyline(orderedPlaces.map(p => ({ lat: p.lat, lng: p.lng })));

    return {
      travelLegs,
      totalEstimatedTravelMinutes: totalMinutes,
      polylinePoints
    };
  };

  if (config.mockMode === 'always' || !isDirectionsAvailable()) {
    return calculateHeuristicLegs();
  }

  try {
    const origin = `${orderedPlaces[0].lat},${orderedPlaces[0].lng}`;
    const destination = `${orderedPlaces[orderedPlaces.length - 1].lat},${orderedPlaces[orderedPlaces.length - 1].lng}`;
    
    let waypoints = '';
    if (orderedPlaces.length > 2) {
      waypoints = orderedPlaces.slice(1, -1).map(p => `${p.lat},${p.lng}`).join('|');
    }

    const url = `https://maps.googleapis.com/maps/api/directions/json`;
    const params = {
      origin,
      destination,
      key: config.googleDirectionsApiKey,
      mode: 'driving',
      language: 'id'
    };
    if (waypoints) {
      params.waypoints = waypoints;
    }

    const response = await axios.get(url, { params, timeout: 8000 });

    if (response.data.status !== 'OK' || !response.data.routes || response.data.routes.length === 0) {
      console.warn(`[DirectionsService] Directions API status: ${response.data.status}, using heuristic`);
      return calculateHeuristicLegs();
    }

    const route = response.data.routes[0];
    const travelLegs = [];
    let totalMinutes = 0;

    if (route.legs) {
      route.legs.forEach((leg, index) => {
        const from = orderedPlaces[index];
        const to = orderedPlaces[index + 1];
        const durationMin = Math.round((leg.duration?.value || 600) / 60);
        totalMinutes += durationMin;

        travelLegs.push({
          fromPlaceId: from.placeId,
          toPlaceId: to.placeId,
          fromName: from.name,
          toName: to.name,
          distanceKm: parseFloat(((leg.distance?.value || 2000) / 1000).toFixed(1)),
          durationMinutes: durationMin,
          durationText: leg.duration?.text || `${durationMin} menit`
        });
      });
    }

    return {
      travelLegs,
      totalEstimatedTravelMinutes: totalMinutes,
      polylinePoints: generateMockRoutePolyline(orderedPlaces.map(p => ({ lat: p.lat, lng: p.lng }))),
      overviewPolyline: route.overview_polyline?.points
    };
  } catch (error) {
    console.error('[DirectionsService] Error calling Google Directions API:', error.message);
    return calculateHeuristicLegs();
  }
}

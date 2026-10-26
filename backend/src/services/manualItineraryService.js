import { estimateOsmBudget, getTripBudgetContext } from './budgetService.js';
import { calculateRouteAndTravelTimes } from './directionsService.js';

const DEFAULT_START_MINUTES = 9 * 60;
const DEFAULT_END_MINUTES = 17 * 60;
const MAX_TRIP_DAYS = 7;

function parseClock(value) {
  const match = String(value || '').match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return null;
  const hours = Number(match[1]);
  const minutes = Number(match[2]);
  return hours <= 23 && minutes <= 59 ? hours * 60 + minutes : null;
}

function parseTimeWindow(intent) {
  const text = `${intent.dateTime || ''} ${intent.userNotes || ''}`;
  const range = text.match(
    /\b(\d{1,2}:\d{2})\s*(?:-|–|sampai|hingga|s\/d)\s*(\d{1,2}:\d{2})\b/i,
  );
  if (range) {
    const start = parseClock(range[1]);
    const end = parseClock(range[2]);
    if (start !== null && end !== null && end > start) return { start, end };
  }

  const startMatch = text.match(/\b(?:mulai|dari|jam)\s*(\d{1,2}:\d{2})\b/i);
  const start = startMatch ? parseClock(startMatch[1]) : null;
  return {
    start: start ?? DEFAULT_START_MINUTES,
    end: DEFAULT_END_MINUTES,
  };
}

function parseTripDays(intent) {
  const text = `${intent.dateTime || ''} ${intent.userNotes || ''}`;
  const match = text.match(/\b(\d+)\s*(?:hari|days?)\b/i);
  const days = match
    ? Number(match[1])
    : /\b(?:weekend|akhir pekan)\b/i.test(text) ? 2 : 1;
  return Math.min(MAX_TRIP_DAYS, Math.max(1, days));
}

function parseOpeningHours(value) {
  const text = String(value || '').trim();
  if (!text || /buka setiap hari|24\s*jam|24\/7/i.test(text)) return null;
  const match = text.match(
    /^\s*(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})(?:\s*(?:WIB|WITA|WIT))?\s*$/i,
  );
  if (!match) return null;
  const open = parseClock(match[1]);
  const close = parseClock(match[2]);
  return open !== null && close !== null && close > open
    ? { open, close }
    : null;
}

function categoryMatches(place, categories) {
  if (!categories.length) return true;
  const placeText = [
    place.category,
    place.osmKey,
    place.osmValue,
    place.cuisine,
  ].join(' ').toLowerCase().replace(/[_-]/g, ' ');
  const groups = [
    [/\b(kuliner|food|restaurant|cafe|makan)\b/i, /\b(food|restaurant|cafe|fast food|food court|coffee|bakery)\b/i],
    [/\b(sejarah|historic|history|museum)\b/i, /\b(history|historic|museum|castle|monument|archaeological)\b/i],
    [/\b(alam|nature|outdoor|pantai)\b/i, /\b(nature|park|beach|mountain|waterfall|garden|leisure)\b/i],
    [/\b(belanja|shopping|shop)\b/i, /\b(shop|market|mall|department store)\b/i],
    [/\b(akomodasi|hotel|penginapan|hostel)\b/i, /\b(hotel|hostel|guest house|camp site|motel|apartment)\b/i],
    [/\b(religi|religious|worship)\b/i, /\b(worship|church|mosque|temple)\b/i],
    [/\b(foto|estetik|hidden gem|hiburan|keluarga)\b/i, /\b(attraction|viewpoint|theme park|artwork)\b/i],
    [/\b(wisata|attraction|tourism)\b/i, /\b(attraction|tourism|historic|museum|park|beach|viewpoint)\b/i],
  ];
  return categories.some(category => {
    const normalized = String(category).toLowerCase();
    const group = groups.find(([pattern]) => pattern.test(normalized));
    return placeText.includes(normalized) || (group
      ? group[1].test(placeText)
      : false);
  });
}

function inferBudgetCategory(place) {
  if (place.budgetCategory) return place.budgetCategory;
  const placeText = `${place.category || ''} ${place.osmValue || ''}`.toLowerCase();
  if (/\b(kuliner|makan|food|restaurant|cafe|bakery)\b/.test(placeText)) {
    return 'food';
  }
  if (/\b(akomodasi|penginapan|hotel|hostel|motel|guest house)\b/.test(placeText)) {
    return 'accommodation';
  }
  return 'other';
}

function getPlaceCost(place, budgetContext) {
  const hasOsmMetadata = Boolean(place.osmKey || place.osmValue);
  if (hasOsmMetadata) {
    return {
      ...estimateOsmBudget({
        osm_key: place.osmKey,
        osm_value: place.osmValue,
        cuisine: place.cuisine,
        stars: place.stars,
        fee: place.fee,
      }, budgetContext.peopleCount, budgetContext.durationDays),
      costEstimateAvailable: true,
    };
  }

  const maxValue = place.estimatedCostMax ?? place.estimatedPrice;
  const minValue = place.estimatedCostMin ?? place.estimatedPrice ?? maxValue;
  const max = Number(maxValue);
  const min = Number(minValue);
  if (maxValue != null && Number.isFinite(max) && max >= 0 &&
      Number.isFinite(min) && min >= 0) {
    return {
      estimatedCostMin: min,
      estimatedCostMax: max,
      estimatedPrice: max,
      budgetCategory: inferBudgetCategory(place),
      budgetTier: place.budgetTier || 'moderate',
      costEstimateAvailable: true,
    };
  }

  return {
    estimatedCostMin: 0,
    estimatedCostMax: 0,
    estimatedPrice: 0,
    budgetCategory: inferBudgetCategory(place),
    budgetTier: place.budgetTier || 'unspecified',
    costEstimateAvailable: false,
  };
}

function distanceSquared(from, to) {
  const lat1 = Number(from.lat);
  const lng1 = Number(from.lng);
  const lat2 = Number(to.lat);
  const lng2 = Number(to.lng);
  if (![lat1, lng1, lat2, lng2].every(Number.isFinite)) return Infinity;
  const meanLatRadians = ((lat1 + lat2) / 2) * Math.PI / 180;
  const x = (lng2 - lng1) * Math.cos(meanLatRadians);
  const y = lat2 - lat1;
  return x * x + y * y;
}

function orderByProximity(places) {
  if (places.length < 3 || places.some(place =>
    !Number.isFinite(Number(place.lat)) || !Number.isFinite(Number(place.lng)))) {
    return [...places];
  }

  const ordered = [places[0]];
  const remaining = places.slice(1);
  while (remaining.length) {
    const previous = ordered[ordered.length - 1];
    let nearestIndex = 0;
    let nearestDistance = distanceSquared(previous, remaining[0]);
    for (let index = 1; index < remaining.length; index++) {
      const distance = distanceSquared(previous, remaining[index]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }
    ordered.push(remaining.splice(nearestIndex, 1)[0]);
  }
  return ordered;
}

function formatClock(minutes) {
  const hours = Math.floor(minutes / 60);
  const remainder = minutes % 60;
  return `${String(hours).padStart(2, '0')}:${String(remainder).padStart(2, '0')}`;
}

function visitDuration(place) {
  const requested = Number(place.suggestedDurationMinutes || place.visitDurationMinutes);
  if (Number.isFinite(requested) && requested > 0) {
    return Math.min(360, Math.max(15, Math.round(requested)));
  }
  return /\b(cafe|restaurant|fast food|food court|kuliner|bakery)\b/i.test(
    `${place.category || ''} ${place.osmValue || ''}`,
  ) ? 45 : 75;
}

function timeZoneLabel(place, intent) {
  const match = `${place.openingHours || ''} ${intent.dateTime || ''}`
    .match(/\b(WIB|WITA|WIT)\b/i);
  return match ? match[1].toUpperCase() : 'WIB';
}

function scheduleStops(places, travelLegs, intent, budgetContext) {
  const { start, end } = parseTimeWindow(intent);
  const tripDays = parseTripDays(intent);
  const categoryBudgets = {
    food: budgetContext.foodBudget,
    accommodation: budgetContext.accommodationBudget,
    other: budgetContext.otherBudget,
  };
  const totals = { food: 0, accommodation: 0, other: 0 };
  let totalCost = 0;
  let day = 1;
  let currentTime = start;
  const scheduled = [];
  let omittedForBudget = 0;
  let omittedForHours = 0;
  let omittedForUnknownCost = 0;
  let includedWithUnknownCost = 0;

  for (let index = 0; index < places.length; index++) {
    const place = places[index];
    const cost = getPlaceCost(place, budgetContext);
    const budgetCategory = Object.hasOwn(totals, cost.budgetCategory)
      ? cost.budgetCategory
      : 'other';
    if (budgetContext.budget > 0) {
      if (!cost.costEstimateAvailable) {
        omittedForUnknownCost++;
        continue;
      }
      const costCeiling = cost.estimatedCostMax;
      if (
        totalCost + costCeiling > budgetContext.budget ||
        totals[budgetCategory] + costCeiling > categoryBudgets[budgetCategory]
      ) {
        omittedForBudget++;
        continue;
      }
    }

    const duration = visitDuration(place);
    const hours = parseOpeningHours(place.openingHours);
    const previousStop = scheduled[scheduled.length - 1];
    const matchingLeg = previousStop
      ? travelLegs.find(leg =>
          leg.fromPlaceId === previousStop.placeId &&
          leg.toPlaceId === place.placeId,
        )
      : null;
    const legMinutes = Number(matchingLeg?.durationMinutes) || 0;
    const startingDay = day;
    const startingTime = currentTime;
    let placed = false;

    while (day <= tripDays) {
      const arrival = currentTime + (scheduled.length && scheduled[scheduled.length - 1].day === day
        ? legMinutes
        : 0);
      const openTime = hours ? Math.max(arrival, hours.open) : arrival;
      const closeTime = hours ? Math.min(end, hours.close) : end;
      if (openTime + duration <= closeTime) {
        const stop = {
          ...place,
          ...cost,
          order: scheduled.length + 1,
          suggestedArrivalTime: `Hari ${day} · ${formatClock(openTime)} ${timeZoneLabel(place, intent)}`,
          suggestedDurationMinutes: duration,
          estimatedTravelTimeFromPrevious:
            scheduled.length && scheduled[scheduled.length - 1].day === day
              ? legMinutes
              : 0,
          activityTip: place.activityTip ||
            `Nikmati kunjungan di ${place.name}; cek informasi setempat untuk detail terbaru.`,
          visited: false,
          day,
        };
        scheduled.push(stop);
        currentTime = openTime + duration;
        if (budgetContext.budget > 0) {
          totalCost += cost.estimatedCostMax;
          totals[budgetCategory] += cost.estimatedCostMax;
        } else if (!cost.costEstimateAvailable) {
          includedWithUnknownCost++;
        }
        placed = true;
        break;
      }
      day++;
      currentTime = start;
    }

    if (!placed) {
      day = startingDay;
      currentTime = startingTime;
      omittedForHours++;
    }
  }

  return {
    stops: scheduled.map(({ day: _day, ...stop }) => stop),
    omittedForBudget,
    omittedForHours,
    omittedForUnknownCost,
    includedWithUnknownCost,
    totalCost,
    tripDays,
    start,
    end,
  };
}

export async function buildManualItinerary(
  places,
  intent = {},
  { calculateRoute = calculateRouteAndTravelTimes } = {},
) {
  if (!Array.isArray(places) || places.length === 0) {
    return {
      title: `Itinerary ${intent.location || 'Kelana'}`,
      summary: 'Belum ada tempat yang dipilih.',
      places: [],
      totalEstimatedTravelMinutes: 0,
      travelLegs: [],
      polylinePoints: [],
    };
  }

  const budgetContext = getTripBudgetContext(intent);
  const categories = Array.isArray(intent.categories) ? intent.categories : [];
  const eligiblePlaces = places.filter(place =>
    place &&
    typeof place.placeId === 'string' && place.placeId.trim() &&
    typeof place.name === 'string' && place.name.trim() &&
    categoryMatches(place, categories),
  );
  const orderedPlaces = orderByProximity(eligiblePlaces);
  const hasCoordinates = orderedPlaces.length > 0 && orderedPlaces.every(place =>
    Number.isFinite(Number(place.lat)) && Number.isFinite(Number(place.lng)));
  const routeInfo = hasCoordinates
    ? await calculateRoute(orderedPlaces)
    : { travelLegs: [], totalEstimatedTravelMinutes: 0, polylinePoints: [] };
  const schedule = scheduleStops(
    orderedPlaces,
    routeInfo.travelLegs,
    intent,
    budgetContext,
  );
  let finalRouteInfo = routeInfo;
  let finalSchedule = schedule;
  if (hasCoordinates && schedule.stops.length > 0 &&
      schedule.stops.length < orderedPlaces.length) {
    finalRouteInfo = await calculateRoute(schedule.stops);
    finalSchedule = scheduleStops(
      schedule.stops,
      finalRouteInfo.travelLegs,
      intent,
      budgetContext,
    );
  }
  const scheduledIds = new Set(finalSchedule.stops.map(place => place.placeId));
  const enrichedPlaces = finalSchedule.stops.map(place => ({
    ...place,
    estimatedTravelTimeFromPrevious: place.estimatedTravelTimeFromPrevious || 0,
  }));
  const summaryParts = [
    `Jadwal disusun otomatis dalam rentang ${formatClock(finalSchedule.start)}–${formatClock(finalSchedule.end)} untuk maksimal ${finalSchedule.tripDays} hari.`,
    schedule.omittedForBudget
      ? `${schedule.omittedForBudget} tempat dilewati agar estimasi biaya tidak melampaui budget atau alokasi kategori.`
      : null,
    schedule.omittedForUnknownCost
      ? `${schedule.omittedForUnknownCost} tempat dilewati karena estimasi biaya tidak tersedia untuk memeriksa batas budget.`
      : null,
    schedule.omittedForHours
      ? `${schedule.omittedForHours} tempat tidak muat dalam rentang waktu atau jam buka yang tersedia.`
      : null,
    schedule.includedWithUnknownCost
      ? `Estimasi biaya tidak tersedia untuk ${schedule.includedWithUnknownCost} tempat; biaya tersebut tidak dihitung sebagai gratis.`
      : null,
    !hasCoordinates
      ? 'Data koordinat tidak lengkap; waktu perjalanan dan rute tidak dihitung.'
      : 'Waktu perjalanan merupakan estimasi dari layanan rute yang tersedia.',
    'Biaya tempat adalah estimasi, bukan harga aktual; transportasi tidak termasuk.',
  ].filter(Boolean);

  return {
    title: `Jelajah ${intent.location || 'Kota'} yang Menyenangkan`,
    summary: summaryParts.join(' '),
    places: enrichedPlaces,
    totalEstimatedTravelMinutes: finalRouteInfo.travelLegs.reduce(
      (total, leg) => total + (Number(leg.durationMinutes) || 0),
      0,
    ),
    travelLegs: finalRouteInfo.travelLegs.map((leg, index) => ({
      ...leg,
      estimated: true,
      omittedFromSchedule: !scheduledIds.has(leg.fromPlaceId) ||
        !scheduledIds.has(leg.toPlaceId),
      // Legs crossing overnight boundaries are route estimates, not time added to a stop's schedule.
      scheduleTravelMinutes: enrichedPlaces.find(place => place.placeId === leg.toPlaceId)
        ?.estimatedTravelTimeFromPrevious ?? 0,
      index,
    })),
    polylinePoints: finalRouteInfo.polylinePoints,
  };
}

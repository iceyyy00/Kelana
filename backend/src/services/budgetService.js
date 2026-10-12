const MAX_PARTY_SIZE = 50;

export function getTripBudgetContext(intent = {}) {
  const requestedBudget = Number(intent.budget);
  const budget = Number.isFinite(requestedBudget) ? Math.max(0, requestedBudget) : 0;
  const requestedPeople = Number(intent.peopleCount);
  const peopleCount = Number.isFinite(requestedPeople)
    ? Math.min(MAX_PARTY_SIZE, Math.max(1, Math.floor(requestedPeople)))
    : 1;
  const dateTime = String(intent.dateTime || '');
  const dayMatch = dateTime.match(/(\d+)\s*(?:hari|days?)/i);
  const durationDays = dayMatch
    ? Math.max(1, Number.parseInt(dayMatch[1], 10))
    : /akhir pekan|weekend/i.test(dateTime) ? 2 : 1;
  const requestedFoodPercent = Number(intent.foodBudgetPercent);
  const foodBudgetPercent = Number.isFinite(requestedFoodPercent)
    ? Math.min(100, Math.max(0, Math.round(requestedFoodPercent)))
    : 50;
  const requestedAccommodationPercent = Number(intent.accommodationBudgetPercent);
  const accommodationBudgetPercent = Math.min(
    100 - foodBudgetPercent,
    Number.isFinite(requestedAccommodationPercent)
      ? Math.max(0, Math.round(requestedAccommodationPercent))
      : 20,
  );
  const foodBudget = budget * foodBudgetPercent / 100;
  const accommodationBudget = budget * accommodationBudgetPercent / 100;
  const dailyPerPersonBudget = budget > 0
    ? budget / peopleCount / durationDays
    : 0;
  const budgetLevel = budget === 0
    ? 'unspecified'
    : dailyPerPersonBudget <= 150000
      ? 'budget'
      : dailyPerPersonBudget <= 500000 ? 'moderate' : 'luxury';

  return {
    budget,
    peopleCount,
    durationDays,
    dailyPerPersonBudget,
    budgetLevel,
    foodBudgetPercent,
    accommodationBudgetPercent,
    foodBudget,
    accommodationBudget,
    otherBudget: budget - foodBudget - accommodationBudget,
  };
}

export function estimateOsmBudget(properties = {}, partySize = 1, durationDays = 1) {
  const extra = properties.extra && typeof properties.extra === 'object'
    ? properties.extra
    : {};
  const osmKey = String(properties.osm_key || '').toLowerCase();
  const osmValue = String(properties.osm_value || '').toLowerCase();
  const cuisine = String(properties.cuisine || extra.cuisine || '').toLowerCase();
  const fee = String(properties.fee || extra.fee || '').toLowerCase();
  const stars = Number(properties.stars || extra.stars || 0);
  const people = Math.min(MAX_PARTY_SIZE, Math.max(1, Number(partySize) || 1));
  const nights = Math.max(1, Math.floor(Number(durationDays) || 1) - 1);
  let estimate;
  let perPerson = true;

  if (osmKey === 'tourism' && ['hostel', 'camp_site', 'guest_house'].includes(osmValue)) {
    estimate = { budgetCategory: 'accommodation', budgetTier: 'budget', min: 75000, max: 300000 };
    perPerson = false;
  } else if (osmKey === 'tourism' && ['hotel', 'motel', 'apartment'].includes(osmValue)) {
    estimate = stars >= 4
      ? { budgetCategory: 'accommodation', budgetTier: 'luxury', min: 1000000, max: 3500000 }
      : { budgetCategory: 'accommodation', budgetTier: 'moderate', min: 250000, max: 900000 };
    perPerson = false;
  } else if (osmKey === 'amenity' && ['fast_food', 'food_court'].includes(osmValue) || cuisine.includes('street_food')) {
    estimate = { budgetCategory: 'food', budgetTier: 'budget', min: 15000, max: 45000 };
  } else if (osmKey === 'amenity' && ['restaurant', 'cafe'].includes(osmValue)) {
    estimate = cuisine.includes('fine_dining')
      ? { budgetCategory: 'food', budgetTier: 'luxury', min: 150000, max: 400000 }
      : { budgetCategory: 'food', budgetTier: 'moderate', min: 35000, max: 125000 };
  } else if (osmKey === 'amenity' && osmValue === 'place_of_worship') {
    estimate = { budgetCategory: 'other', budgetTier: 'free', min: 0, max: 10000 };
  } else if (fee === 'no') {
    estimate = { budgetCategory: 'other', budgetTier: 'free', min: 0, max: 0 };
  } else if (fee === 'yes') {
    estimate = { budgetCategory: 'other', budgetTier: 'budget', min: 10000, max: 75000 };
  } else if (osmKey === 'historic' || ['tourism', 'leisure', 'natural'].includes(osmKey)) {
    estimate = { budgetCategory: 'other', budgetTier: 'budget', min: 0, max: 50000 };
  } else {
    estimate = { budgetCategory: 'other', budgetTier: 'moderate', min: 0, max: 100000 };
  }

  const isAccommodation = osmKey === 'tourism' &&
    ['hostel', 'camp_site', 'guest_house', 'hotel', 'motel', 'apartment'].includes(osmValue);
  const multiplier = isAccommodation ? nights : perPerson ? people : 1;
  const estimatedCostMin = estimate.min * multiplier;
  const estimatedCostMax = estimate.max * multiplier;
  return {
    budgetCategory: estimate.budgetCategory,
    budgetTier: estimate.budgetTier,
    estimatedCostMin,
    estimatedCostMax,
    estimatedPrice: estimatedCostMax,
  };
}
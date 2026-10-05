import { GoogleGenerativeAI } from '@google/generative-ai';
import { config, isGeminiAvailable } from '../config/env.js';
import { estimateOsmBudget, getTripBudgetContext } from './budgetService.js';
import { geminiIntentResponseSchema, geminiItineraryResponseSchema } from '../schemas/intentSchema.js';

function titleCase(value) {
  return value.replace(/\b\p{L}/gu, letter => letter.toUpperCase());
}

function parseNumberWord(value) {
  const numberWords = {
    satu: 1, sehari: 1, dua: 2, tiga: 3, empat: 4, lima: 5,
    enam: 6, tujuh: 7, delapan: 8, sembilan: 9, sepuluh: 10,
  };
  return Number.parseInt(value, 10) || numberWords[value.toLowerCase()] || 0;
}

async function generateWithTransientRetry(model, content) {
  try {
    return await model.generateContent(content);
  } catch (error) {
    const status = Number(error?.status || error?.response?.status);
    const transientStatus = [429, 500, 502, 503, 504].includes(status) ||
      /\[(?:429|500|502|503|504)\b/.test(error?.message || '');
    if (!transientStatus) throw error;

    await new Promise(resolve => setTimeout(resolve, 700));
    return model.generateContent(content);
  }
}

/**
 * Heuristic fallback parser for offline/demo mode
 */
export function heuristicParseIntent(rawQuery) {
  const query = String(rawQuery || '').toLowerCase();

    // Prefer known aliases, then capture a destination following an explicit travel preposition.
    let location = '';
    const knownCities = [
      ['yogyakarta', 'Yogyakarta'], ['jogja', 'Yogyakarta'],
      ['surakarta', 'Surakarta'], ['solo', 'Surakarta'],
      ['semarang', 'Semarang'], ['bandung', 'Bandung'], ['bali', 'Bali'],
      ['jakarta', 'Jakarta'], ['surabaya', 'Surabaya'], ['malang', 'Malang'],
      ['bogor', 'Bogor'], ['lombok', 'Lombok'], ['medan', 'Medan'],
    ];
    for (const [alias, canonical] of knownCities) {
      if (new RegExp(`\\b${alias}\\b`).test(query)) {
        location = canonical;
        break;
      }
    }
    if (!location) {
      const destinationMatch = query.match(
        /\b(?:ke|menuju|kunjungi|to|visit)\s+([\p{L}][\p{L}\s'-]{1,49}?)(?=\s+(?:tanggal|tgl|pada|selama|untuk|budget|biaya|dengan|suka|ingin|besok|lusa|hari ini|weekend|akhir pekan|pagi|siang|sore|malam|jam|dan|yang)\b|[,.!?]|$)/u,
      );
      if (destinationMatch) location = titleCase(destinationMatch[1].trim());
    }

  // 2. Detect budget
  let budget = 100000;
  let budgetLevel = "budget";
  const budgetKMatch = query.match(/(\d+)\s*(?:rb|ribu|k)\b/);
  const budgetFullMatch = query.match(/(?:rp|budget|biaya|uang)?\s*(\d{4,9})\b/);
  const budgetJtMatch = query.match(/(\d+)\s*(?:jt|juta)\b/);

  if (budgetKMatch) {
    budget = parseInt(budgetKMatch[1], 10) * 1000;
  } else if (budgetJtMatch) {
    budget = parseInt(budgetJtMatch[1], 10) * 1000000;
  } else if (budgetFullMatch) {
    budget = parseInt(budgetFullMatch[1], 10);
  }

  if (budget > 1000000) budgetLevel = "luxury";
  else if (budget > 300000) budgetLevel = "moderate";
  else budgetLevel = "budget";

  // 3. Detect categories
  const categories = [];
  if (query.includes("kuliner") || query.includes("makan") || query.includes("jajan") || query.includes("kopi") || query.includes("cafe")) {
    categories.push("Kuliner");
  }
  if (query.includes("sejarah") || query.includes("museum") || query.includes("candi") || query.includes("heritage")) {
    categories.push("Wisata Sejarah");
  }
  if (query.includes("alam") || query.includes("pantai") || query.includes("gunung") || query.includes("bukit") || query.includes("curug")) {
    categories.push("Wisata Alam");
  }
  if (query.includes("belanja") || query.includes("mall") || query.includes("pasar") || query.includes("oleh-oleh")) {
    categories.push("Belanja");
  }
  if (query.includes("hotel") || query.includes("penginapan") || query.includes("akomodasi") || query.includes("hostel")) {
    categories.push("Akomodasi");
  }
  if (query.includes("foto") || query.includes("estetik") || query.includes("instagrammable") || query.includes("hidden gem")) {
    categories.push("Spot Foto & Estetik");
  }
  if (categories.length === 0) {
    categories.push("Wisata Populer", "Kuliner");
  }

  // Preserve explicit dates and durations so a failed Gemini request remains useful.
  const monthNames = 'januari|februari|maret|april|mei|juni|juli|agustus|september|oktober|november|desember';
  const explicitDate = query.match(
    new RegExp(`\\b(?:tanggal|tgl\\.?|pada)\\s+(\\d{1,2}\\s+(?:${monthNames})(?:\\s+\\d{4})?|\\d{1,2}[/-]\\d{1,2}(?:[/-]\\d{2,4})?)`, 'i'),
  );
  const durationMatch = query.match(
    /\b(?:(?:selama|sekitar|for)\s+)?(\d+|sehari|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh)\s*(hari|malam|days?|nights?)\b/i,
  );
  const durationCount = durationMatch ? parseNumberWord(durationMatch[1]) : 0;
  const durationUnit = durationMatch?.[2].toLowerCase().startsWith('malam') ||
      durationMatch?.[2].toLowerCase().startsWith('night')
    ? 'malam'
    : 'hari';
  const relativeDuration = query.match(
    /\b(?:dalam|in)\s+(\d+|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh)\s+hari\s+lagi\b/i,
  );
  const relativeDate = query.match(/\b(lusa|besok|hari ini|today|tomorrow|weekend|akhir pekan)\b/i);
  const dateLabel = explicitDate
    ? titleCase(explicitDate[1])
    : relativeDuration
      ? `${parseNumberWord(relativeDuration[1])} hari lagi`
      : relativeDate
        ? titleCase(relativeDate[1] === 'weekend' ? 'akhir pekan' : relativeDate[1])
        : '';
  const timeOfDay = query.match(/\b(pagi|siang|sore|malam)\b/i)?.[1];
  const timeRange = query.match(/\bjam\s+\d{1,2}(?::\d{2})?(?:\s*[-–]\s*\d{1,2}(?::\d{2})?)?/i)?.[0];
  const dateParts = [
    dateLabel,
    timeOfDay && !dateLabel.toLowerCase().includes(timeOfDay.toLowerCase())
      ? titleCase(timeOfDay)
      : '',
    timeRange || '',
    durationCount && !relativeDuration ? `${durationCount} ${durationUnit}` : '',
  ].filter(Boolean);
  const dateTime = dateParts.length ? dateParts.join(' · ') : 'Belum ditentukan';

  // 5. Detect people count
  let peopleCount = 1;
  const peopleMatch = query.match(/(\d+)\s*(?:orang|pax|org)/);
  if (peopleMatch) {
    peopleCount = parseInt(peopleMatch[1], 10);
  } else if (query.includes("keluarga") || query.includes("family")) {
    peopleCount = 4;
  } else if (query.includes("berdua") || query.includes("pacar") || query.includes("pasangan")) {
    peopleCount = 2;
  }

  return {
    location,
    budget,
    budgetLevel,
    foodBudgetPercent: 50,
    accommodationBudgetPercent: 20,
    categories,
    dateTime,
    peopleCount,
    userNotes: location
      ? `Permintaan perjalanan ke ${location} dengan fokus ${categories.join(', ')} dan estimasi budget Rp ${budget.toLocaleString('id-ID')}.`
      : `Rencana perjalanan dengan fokus ${categories.join(', ')} dan estimasi budget Rp ${budget.toLocaleString('id-ID')}.`,
  };
}

/**
 * Parse user prompt into structured travel intent using Gemini API
 */
export async function parseUserIntent(rawQuery, userPreferences = {}) {
  // If in pure mock mode or Gemini key is missing, use intelligent heuristic parser
  if (config.mockMode === 'always' || !isGeminiAvailable()) {
    console.log('[GeminiService] Using heuristic fallback for intent parsing');
    return heuristicParseIntent(rawQuery);
  }

  try {
    const fallbackIntent = heuristicParseIntent(rawQuery);
    const model = new GoogleGenerativeAI(config.geminiApiKey).getGenerativeModel({
      model: "gemini-3.8-flash",
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.2,
      }
    });

    const systemPrompt = `
Anda adalah asisten perencana perjalanan (itinerary planner) cerdas bernama Kelana.
Tugas Anda adalah mengekstrak niat perjalanan user dari teks percakapan bebas ke dalam format JSON terstruktur.

Aturan Ekstraksi:
- "location": Nama destinasi yang benar-benar disebut user. Jangan pernah mengasumsikan Semarang atau kota lain; gunakan string kosong bila tidak ada lokasi.
- "budget": Total estimasi budget perjalanan dalam Rupiah (angka murni integer tanpa format). Jika user menyebut "100rb" maka isi 100000. Jika tidak disebutkan sama sekali, beri estimasi logis sesuai konteks.
- "budgetLevel": Salah satu dari: "budget", "moderate", "luxury", "unspecified".
- "foodBudgetPercent": Persentase budget total untuk makan, default 50.
- "accommodationBudgetPercent": Persentase budget total untuk akomodasi, default 20; gabungan kedua alokasi tidak boleh lebih dari 100.
- "categories": Array of strings berisi kategori minat (misal: ["Kuliner", "Wisata Sejarah", "Alam", "Belanja"]).
- "dateTime": Tanggal/waktu/durasi yang benar-benar disebut user. Jangan mengasumsikan "Hari ini"; gunakan "Belum ditentukan" bila tidak disebut.
- "peopleCount": Jumlah orang (integer, default 1).
- "userNotes": Ringkasan ramah dalam Bahasa Indonesia mengenai apa yang diinginkan user.

Format output HARUS selalu JSON valid yang cocok dengan skema berikut:
{
  "location": string,
  "budget": number,
  "budgetLevel": "budget" | "moderate" | "luxury" | "unspecified",
  "foodBudgetPercent": number,
  "accommodationBudgetPercent": number,
  "categories": string[],
  "dateTime": string,
  "peopleCount": number,
  "userNotes": string
}
`;

    const userMessage = `
Input User: "${rawQuery}"
${userPreferences && Object.keys(userPreferences).length > 0 ? `Preferensi Historis User: ${JSON.stringify(userPreferences)}` : ''}
    `;

    const result = await generateWithTransientRetry(model, [systemPrompt, userMessage]);
    const responseText = result.response.text();
    const parsed = JSON.parse(responseText);

    return {
      location: fallbackIntent.location || (() => {
        const parsedLocation = String(parsed.location || '').trim();
        return parsedLocation.toLowerCase() === 'semarang' && !/\bsemarang\b/i.test(rawQuery)
          ? ''
          : parsedLocation;
      })(),
      budget: Number(parsed.budget) || 100000,
      budgetLevel: parsed.budgetLevel || "budget",
      foodBudgetPercent: Number(parsed.foodBudgetPercent) || 50,
      accommodationBudgetPercent: Number(parsed.accommodationBudgetPercent) || 20,
      categories: Array.isArray(parsed.categories) ? parsed.categories : ["Wisata", "Kuliner"],
      dateTime: fallbackIntent.dateTime !== 'Belum ditentukan'
        ? fallbackIntent.dateTime
        : String(parsed.dateTime || 'Belum ditentukan').toLowerCase() === 'hari ini' &&
            !/\b(?:hari ini|today)\b/i.test(rawQuery)
          ? 'Belum ditentukan'
          : String(parsed.dateTime || 'Belum ditentukan'),
      peopleCount: Number(parsed.peopleCount) || 1,
      userNotes: parsed.userNotes || "Rencana perjalanan terstruktur oleh Kelana."
    };
  } catch (error) {
    console.error('[GeminiService] Error calling Gemini API:', error.message);
    // Fallback to heuristic parser on any API failure (e.g. rate limit, network timeout)
    return heuristicParseIntent(rawQuery);
  }
}

/**
 * Optimize itinerary sequence and schedule using Gemini API
 */
export async function optimizeItinerary(places, intent = {}) {
  if (!places || places.length === 0) {
    return {
      tripTitle: "Rencana Perjalanan",
      summary: "Belum ada tempat yang dipilih.",
      stops: []
    };
  }

  const budgetContext = getTripBudgetContext(intent);
  const budgetedPlaces = places.map(place => {
    if (!place.osmKey && !place.osmValue) return place;
    return {
      ...place,
      ...estimateOsmBudget({
        osm_key: place.osmKey,
        osm_value: place.osmValue,
        cuisine: place.cuisine,
        stars: place.stars,
        fee: place.fee,
      }, budgetContext.peopleCount, budgetContext.durationDays),
    };
  });
  const fitStopsWithinBudget = stops => {
    let estimatedTotal = 0;
    const categoryTotals = { food: 0, accommodation: 0, other: 0 };
    const categoryBudgets = {
      food: budgetContext.foodBudget,
      accommodation: budgetContext.accommodationBudget,
      other: budgetContext.otherBudget,
    };
    return stops.flatMap(stop => {
      const place = budgetedPlaces.find(candidate => candidate.placeId === stop.placeId);
      if (!place) return [];

      const costCeiling = Math.max(0, Number(
        place.estimatedCostMax ?? place.estimatedPrice ?? 0,
      ));
      const budgetCategory = categoryTotals[place.budgetCategory] === undefined
        ? 'other'
        : place.budgetCategory;
      if (
        budgetContext.budget > 0 &&
        (
          estimatedTotal + costCeiling > budgetContext.budget ||
          categoryTotals[budgetCategory] + costCeiling > categoryBudgets[budgetCategory]
        )
      ) {
        return [];
      }

      estimatedTotal += costCeiling;
      categoryTotals[budgetCategory] += costCeiling;
      return [{
        ...stop,
        placeId: place.placeId,
        name: place.name,
        budgetCategory,
        budgetTier: place.budgetTier || 'moderate',
        estimatedCostMin: Number(place.estimatedCostMin ?? place.estimatedPrice ?? costCeiling),
        estimatedCostMax: costCeiling,
        estimatedCost: costCeiling,
      }];
    });
  };

  // Heuristic itinerary builder for fallback
  const buildHeuristicItinerary = () => {
    let currentHour = 9;
    let currentMinute = 0;
    
    const stops = budgetedPlaces.map((place, idx) => {
      const timeString = `${String(currentHour).padStart(2, '0')}:${String(currentMinute).padStart(2, '0')} WIB`;
      const duration = place.category && place.category.toLowerCase().includes('kuliner') ? 45 : 75;
      
      // Advance clock for next stop: visit duration + 30 mins travel
      currentMinute += duration + 30;
      while (currentMinute >= 60) {
        currentHour += 1;
        currentMinute -= 60;
      }

      return {
        placeId: place.placeId,
        name: place.name,
        order: idx + 1,
        suggestedArrivalTime: timeString,
        suggestedDurationMinutes: duration,
        activityTip: `Nikmati suasana dan keunikan di ${place.name}.`,
        estimatedCost: place.estimatedPrice || 0
      };
    });

    const budgetGuardedStops = fitStopsWithinBudget(stops);
    return {
      tripTitle: `Jelajah ${intent.location || 'Kota'} yang Menyenangkan`,
      summary: `Itinerary terstruktur mengunjungi ${budgetGuardedStops.length} dari ${budgetedPlaces.length} destinasi di ${intent.location || 'tujuan Anda'}. Biaya memakai batas atas estimasi tier OSM dan tidak mencakup transportasi.`,
      stops: budgetGuardedStops,
    };
  };

  if (config.mockMode === 'always' || !isGeminiAvailable()) {
    console.log('[GeminiService] Using heuristic optimizer for itinerary build');
    return buildHeuristicItinerary();
  }

  try {
    const model = new GoogleGenerativeAI(config.geminiApiKey).getGenerativeModel({
      model: "gemini-3.8-flash",
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.3,
      }
    });

    const prompt = `
Anda adalah pemandu wisata ahli di Indonesia untuk aplikasi Kelana.
Tugas Anda: Susun urutan kunjungan yang paling logis, efisien rutenya, dan menyenangkan untuk daftar tempat wisata berikut.

Data Preferensi:
- Lokasi: ${intent.location || 'Semarang'}
- Budget total maksimum: Rp ${budgetContext.budget.toLocaleString('id-ID')}
- Alokasi makan: ${budgetContext.foodBudgetPercent}% (maks. Rp ${budgetContext.foodBudget.toLocaleString('id-ID')})
- Alokasi akomodasi: ${budgetContext.accommodationBudgetPercent}% (maks. Rp ${budgetContext.accommodationBudget.toLocaleString('id-ID')})
- Sisa aktivitas: Rp ${budgetContext.otherBudget.toLocaleString('id-ID')}
- Durasi: ${budgetContext.durationDays} hari; ${budgetContext.peopleCount} orang
- Tier harian per orang: ${budgetContext.budgetLevel} (sekitar Rp ${Math.floor(budgetContext.dailyPerPersonBudget).toLocaleString('id-ID')})
- Kategori: ${(intent.categories || []).join(', ')}
- Waktu: ${intent.dateTime || 'Hari ini'}
- Estimasi hanya batas tier berbasis tag OSM, bukan harga live; biaya transportasi tidak tersedia dan tidak termasuk.

Daftar Tempat yang Dipilih User:
${JSON.stringify(budgetedPlaces.map(p => ({
  placeId: p.placeId,
  name: p.name,
  category: p.category,
  lat: p.lat,
  lng: p.lng,
  osmTags: {
    key: p.osmKey,
    value: p.osmValue,
    cuisine: p.cuisine,
    stars: p.stars,
    fee: p.fee,
  },
  budgetTier: p.budgetTier || 'moderate',
  budgetCategory: p.budgetCategory || 'other',
  estimatedCostRange: {
    min: p.estimatedCostMin ?? p.estimatedPrice ?? 0,
    max: p.estimatedCostMax ?? p.estimatedPrice ?? 0,
  },
  openingHours: p.openingHours
})), null, 2)}

Petunjuk Penyusunan:
1. Mulai dari pagi sekitar pukul 08:30 atau 09:00 WIB.
2. Tempat kuliner sebaiknya ditempatkan di waktu makan siang (12:00-13:30) atau makan sore/malam.
3. Urutkan berdasarkan kedekatan koordinat geografis agar waktu di perjalanan minimal.
4. Gunakan hanya tempat dan placeId yang diberikan.
5. Jangan melampaui budget total atau alokasi kategori. Jumlahkan batas atas estimatedCostRange.max; batasi makan dan akomodasi pada alokasi masing-masing, serta semua stop pada budget total.
6. Jangan mengarang harga aktual. Isi estimatedCost dengan batas atas tier OSM yang diberikan.
7. Berikan tips aktivitas spesifik yang hemat biaya; tandai tempat gratis hanya jika tag OSM menyatakan fee=no.

Format output HARUS JSON valid:
{
  "tripTitle": string,
  "summary": string,
  "stops": [
    {
      "placeId": string,
      "name": string,
      "order": number,
      "suggestedArrivalTime": string,
      "suggestedDurationMinutes": number,
      "activityTip": string,
      "estimatedCost": number
    }
  ]
}
`;

    const result = await generateWithTransientRetry(model, prompt);
    const text = result.response.text();
    const parsed = JSON.parse(text);

    const candidateStops = Array.isArray(parsed.stops)
      ? parsed.stops
      : buildHeuristicItinerary().stops;
    const guardedStops = fitStopsWithinBudget(candidateStops);
    const omittedStops = candidateStops.length - guardedStops.length;
    return {
      tripTitle: parsed.tripTitle || `Itinerary ${intent.location || 'Kelana'}`,
      summary: [
        parsed.summary || 'Rencana perjalanan optimal dengan rute efisien.',
        omittedStops > 0
          ? `${omittedStops} tempat dikeluarkan agar batas atas estimasi biaya tetap sesuai budget.`
          : null,
        'Estimasi berbasis tier OSM; biaya transportasi tidak termasuk.',
      ].filter(Boolean).join(' '),
      stops: guardedStops,
    };
  } catch (error) {
    console.error('[GeminiService] Error optimizing itinerary with Gemini:', error.message);
    return buildHeuristicItinerary();
  }
}

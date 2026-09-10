import { GoogleGenerativeAI } from '@google/generative-ai';
import { config, isGeminiAvailable } from '../config/env.js';
import { geminiIntentResponseSchema, geminiItineraryResponseSchema } from '../schemas/intentSchema.js';

let genAI = null;
if (isGeminiAvailable()) {
  genAI = new GoogleGenerativeAI(config.geminiApiKey);
}

/**
 * Heuristic fallback parser for offline/demo mode
 */
function heuristicParseIntent(rawQuery) {
  const query = (rawQuery || '').toLowerCase();
  
  // 1. Detect location
  let location = "Semarang"; // default
  const knownCities = [
    "semarang", "yogyakarta", "jogja", "bandung", "bali", "jakarta", 
    "surabaya", "malang", "solo", "surakarta", "bogor", "lombok", "medan"
  ];
  for (const city of knownCities) {
    if (query.includes(city)) {
      if (city === 'jogja') location = 'Yogyakarta';
      else if (city === 'solo') location = 'Surakarta';
      else location = city.charAt(0).toUpperCase() + city.slice(1);
      break;
    }
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
  if (query.includes("foto") || query.includes("estetik") || query.includes("instagrammable") || query.includes("hidden gem")) {
    categories.push("Spot Foto & Estetik");
  }
  if (categories.length === 0) {
    categories.push("Wisata Populer", "Kuliner");
  }

  // 4. Detect date/time
  let dateTime = "Hari ini";
  if (query.includes("besok")) dateTime = "Besok";
  else if (query.includes("weekend") || query.includes("akhir pekan")) dateTime = "Akhir Pekan";
  else if (query.includes("2 hari") || query.includes("dua hari")) dateTime = "2 Hari";
  else if (query.includes("pagi")) dateTime = "Pagi ini";
  else if (query.includes("sore")) dateTime = "Sore ini";
  else if (query.includes("malam")) dateTime = "Malam ini";

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
    categories,
    dateTime,
    peopleCount,
    userNotes: `Permintaan perjalanan ke ${location} dengan fokus ${categories.join(', ')} dan estimasi budget Rp ${budget.toLocaleString('id-ID')}.`
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
    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.2,
      }
    });

    const systemPrompt = `
Anda adalah asisten perencana perjalanan (itinerary planner) cerdas bernama Kelana.
Tugas Anda adalah mengekstrak niat perjalanan user dari teks percakapan bebas ke dalam format JSON terstruktur.

Aturan Ekstraksi:
- "location": Nama kota/daerah destinasi utama di Indonesia (misal: "Semarang", "Yogyakarta", "Bandung", "Bali").
- "budget": Total estimasi budget perjalanan dalam Rupiah (angka murni integer tanpa format). Jika user menyebut "100rb" maka isi 100000. Jika tidak disebutkan sama sekali, beri estimasi logis sesuai konteks.
- "budgetLevel": Salah satu dari: "budget", "moderate", "luxury", "unspecified".
- "categories": Array of strings berisi kategori minat (misal: ["Kuliner", "Wisata Sejarah", "Alam", "Belanja"]).
- "dateTime": Waktu rencana kunjungan (misal: "hari ini", "1 hari", "akhir pekan", "besok").
- "peopleCount": Jumlah orang (integer, default 1).
- "userNotes": Ringkasan ramah dalam Bahasa Indonesia mengenai apa yang diinginkan user.

Format output HARUS selalu JSON valid yang cocok dengan skema berikut:
{
  "location": string,
  "budget": number,
  "budgetLevel": "budget" | "moderate" | "luxury" | "unspecified",
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

    const result = await model.generateContent([systemPrompt, userMessage]);
    const responseText = result.response.text();
    const parsed = JSON.parse(responseText);

    return {
      location: parsed.location || "Semarang",
      budget: Number(parsed.budget) || 100000,
      budgetLevel: parsed.budgetLevel || "budget",
      categories: Array.isArray(parsed.categories) ? parsed.categories : ["Wisata", "Kuliner"],
      dateTime: parsed.dateTime || "Hari ini",
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

  // Heuristic itinerary builder for fallback
  const buildHeuristicItinerary = () => {
    let currentHour = 9;
    let currentMinute = 0;
    
    const stops = places.map((place, idx) => {
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

    return {
      tripTitle: `Jelajah ${intent.location || 'Kota'} yang Menyenangkan`,
      summary: `Itinerary terstruktur mengunjungi ${places.length} destinasi pilihan di ${intent.location || 'tujuan Anda'} dengan estimasi rute optimal.`,
      stops
    };
  };

  if (config.mockMode === 'always' || !isGeminiAvailable()) {
    console.log('[GeminiService] Using heuristic optimizer for itinerary build');
    return buildHeuristicItinerary();
  }

  try {
    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
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
- Budget: Rp ${(intent.budget || 0).toLocaleString('id-ID')}
- Kategori: ${(intent.categories || []).join(', ')}
- Waktu: ${intent.dateTime || 'Hari ini'}

Daftar Tempat yang Dipilih User:
${JSON.stringify(places.map(p => ({
  placeId: p.placeId,
  name: p.name,
  category: p.category,
  lat: p.lat,
  lng: p.lng,
  estimatedPrice: p.estimatedPrice,
  openingHours: p.openingHours
})), null, 2)}

Petunjuk Penyusunan:
1. Mulai dari pagi sekitar pukul 08:30 atau 09:00 WIB.
2. Tempat kuliner sebaiknya ditempatkan di waktu makan siang (12:00-13:30) atau makan sore/malam.
3. Urutkan berdasarkan kedekatan koordinat geografis agar waktu di perjalanan minimal.
4. Berikan tips aktivitas yang spesifik dan seru untuk setiap tempat.

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

    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const parsed = JSON.parse(text);

    return {
      tripTitle: parsed.tripTitle || `Itinerary ${intent.location || 'Kelana'}`,
      summary: parsed.summary || "Rencana perjalanan optimal dengan rute efisien.",
      stops: Array.isArray(parsed.stops) ? parsed.stops : buildHeuristicItinerary().stops
    };
  } catch (error) {
    console.error('[GeminiService] Error optimizing itinerary with Gemini:', error.message);
    return buildHeuristicItinerary();
  }
}

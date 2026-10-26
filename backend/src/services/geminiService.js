import { GoogleGenerativeAI } from '@google/generative-ai';
import { config, isGeminiAvailable } from '../config/env.js';
import { geminiIntentResponseSchema } from '../schemas/intentSchema.js';

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

async function sendChatWithTransientRetry(chat, message) {
  try {
    return await chat.sendMessage(message);
  } catch (error) {
    const status = Number(error?.status || error?.response?.status);
    const transientStatus = [429, 500, 502, 503, 504].includes(status) ||
      /\[(?:429|500|502|503|504)\b/.test(error?.message || '');
    if (!transientStatus) throw error;

    await new Promise(resolve => setTimeout(resolve, 700));
    return chat.sendMessage(message);
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

  const vagueDestinations = new Set([
    'dalam negeri',
    'luar negeri',
    'mana saja',
    'mana aja',
    'tempat bagus',
    'tempat wisata',
  ]);
  if (vagueDestinations.has(location.toLowerCase())) location = '';

  // 2. Detect budget
  let budget = 0;
  let budgetLevel = "unspecified";
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

  if (budget === 0) budgetLevel = "unspecified";
  else if (budget > 1000000) budgetLevel = "luxury";
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
      ? [
          `Permintaan perjalanan ke ${location}`,
          categories.length ? `dengan fokus ${categories.join(', ')}` : '',
          budget > 0 ? `dan budget Rp ${budget.toLocaleString('id-ID')}` : '',
        ].filter(Boolean).join(' ')
      : 'Halo! Hari ini kita mau merencanakan liburan ke mana nih? Yuk, beri tahu aku kota atau destinasi tujuanmu!',
    chat_response: location
      ? `Aku menangkap tujuan perjalananmu ke ${location}.${budget > 0 ? ` Budget yang disebutkan Rp ${budget.toLocaleString('id-ID')}.` : ''} Ada detail lain yang ingin ditambahkan?`
      : 'Halo! Hari ini kita mau merencanakan liburan ke mana nih? Yuk, beri tahu aku kota atau destinasi tujuanmu!',
  };
}

export function mergeConversationIntent(rawQuery, history = []) {
  const messages = history
    .filter(message => message.role === 'user')
    .map(message => message.parts.map(part => part.text || '').join(''))
    .concat(String(rawQuery || ''));
  const merged = {
    location: '',
    budget: 0,
    budgetLevel: 'unspecified',
    foodBudgetPercent: 50,
    accommodationBudgetPercent: 20,
    categories: [],
    dateTime: 'Belum ditentukan',
    peopleCount: 1,
    userNotes: '',
  };

  for (const message of messages) {
    const parsed = heuristicParseIntent(message);
    if (parsed.location) merged.location = parsed.location;
    if (parsed.budget > 0) {
      merged.budget = parsed.budget;
      merged.budgetLevel = parsed.budgetLevel;
    }
    if (parsed.categories.length > 0) merged.categories = parsed.categories;
    if (parsed.dateTime !== 'Belum ditentukan') merged.dateTime = parsed.dateTime;
    if (parsed.peopleCount > 1) merged.peopleCount = parsed.peopleCount;
  }

  merged.userNotes = merged.location
    ? `Rencana perjalanan ke ${merged.location}.`
    : 'Halo! Hari ini kita mau merencanakan liburan ke mana nih? Yuk, beri tahu aku kota atau destinasi tujuanmu!';
  merged.chat_response = merged.location
    ? `Aku menangkap tujuan perjalananmu ke ${merged.location}.${merged.budget > 0 ? ` Budget yang disebutkan Rp ${merged.budget.toLocaleString('id-ID')}.` : ''} Ada detail lain yang ingin ditambahkan?`
    : `${merged.budget > 0 ? `Budget Rp ${merged.budget.toLocaleString('id-ID')} sudah dicatat. ` : ''}Hari ini kita mau merencanakan liburan ke kota atau destinasi mana?`;
  return merged;
}

/**
 * Parse user prompt into structured travel intent using Gemini API
 */
export async function parseUserIntent(rawQuery, userPreferences = {}, history = []) {
  const fallbackIntent = mergeConversationIntent(rawQuery, history);
  // If in pure mock mode or Gemini key is missing, use intelligent heuristic parser
  if (config.mockMode === 'always' || !isGeminiAvailable()) {
    console.log('[GeminiService] Using heuristic fallback for intent parsing');
    return fallbackIntent;
  }

  try {
    const model = new GoogleGenerativeAI(config.geminiApiKey).getGenerativeModel({
      model: "gemini-3.8-flash",
      systemInstruction: `
Anda adalah Kelana, asisten perencana itinerary liburan yang ramah dan interaktif.
Bantu pengguna menyusun rencana perjalanan bersama OpenStreetMap.

Aturan perilaku yang wajib dipatuhi:
1. Selalu isi "chat_response" dengan balasan percakapan yang ramah, termasuk sapaan,
   pertanyaan klarifikasi, atau ringkasan singkat informasi terbaru.
2. Jika pengguna hanya berbasa-basi atau belum menyebut kota/destinasi yang jelas,
   jangan membuat itinerary dan tanyakan kota/destinasi. Jangan mengarang lokasi.
3. Isi lokasi, budget, kategori, waktu, dan jumlah orang hanya dari informasi eksplisit
   dalam percakapan saat ini atau riwayatnya. Jangan mengisi budget/kategori default.
   Gunakan budget 0, tingkat "unspecified", alokasi 0, dan categories [] bila belum disebut.
4. Pertahankan informasi sebelumnya yang masih relevan. Jika pengguna mengoreksi budget
   atau preferensi, gunakan informasi terbaru yang eksplisit.
5. Keluarkan hanya JSON yang cocok dengan schema intent.

Format JSON:
{
  "chat_response": "string",
  "location": "string",
  "budget": 0,
  "budgetLevel": "budget | moderate | luxury | unspecified",
  "foodBudgetPercent": 0,
  "accommodationBudgetPercent": 0,
  "categories": [],
  "dateTime": "Belum ditentukan",
  "peopleCount": 1,
  "userNotes": "string"
}
      `,
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: geminiIntentResponseSchema,
        temperature: 0.2,
      }
    });

    const userMessage = `
Input User: "${rawQuery}"
${userPreferences && Object.keys(userPreferences).length > 0 ? `Preferensi Historis User: ${JSON.stringify(userPreferences)}` : ''}
    `;

    const chat = model.startChat({ history });
    const result = await sendChatWithTransientRetry(chat, userMessage);
    const responseText = result.response.text();
    const parsed = JSON.parse(responseText);

    return {
      ...fallbackIntent,
      userNotes: parsed.userNotes || fallbackIntent.userNotes,
      chat_response: parsed.chat_response || fallbackIntent.chat_response,
    };
  } catch (error) {
    console.error('[GeminiService] Error calling Gemini API:', error.message);
    // Fallback to heuristic parser on any API failure (e.g. rate limit, network timeout)
    return fallbackIntent;
  }
}

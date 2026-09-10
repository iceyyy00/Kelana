/**
 * Schema for Structured Output with Gemini API
 * Extracts intent from user's travel query
 */
export const geminiIntentResponseSchema = {
  type: "OBJECT",
  properties: {
    location: {
      type: "STRING",
      description: "Kota atau destinasi utama yang ingin dikunjungi (contoh: Semarang, Yogyakarta, Bandung, Bali)."
    },
    budget: {
      type: "NUMBER",
      description: "Total estimasi budget dalam mata uang Rupiah (angka murni tanpa titik/koma, contoh: 100000). Jika tidak disebutkan eksplisit, berikan estimasi yang wajar atau 0."
    },
    budgetLevel: {
      type: "STRING",
      enum: ["budget", "moderate", "luxury", "unspecified"],
      description: "Tingkatan pengeluaran: budget (hemat), moderate (menengah), luxury (mewah)."
    },
    categories: {
      type: "ARRAY",
      items: {
        type: "STRING"
      },
      description: "Daftar kategori minat perjalanan (contoh: kuliner, wisata sejarah, alam, belanja, keluarga, hidden gem, religi)."
    },
    dateTime: {
      type: "STRING",
      description: "Waktu atau durasi perjalanan yang diinginkan (contoh: 'hari ini', '1 hari', 'weekend', '2 hari 1 malam', 'besok sore')."
    },
    peopleCount: {
      type: "INTEGER",
      description: "Jumlah orang yang bepergian. Default 1 jika solo atau tidak disebutkan."
    },
    userNotes: {
      type: "STRING",
      description: "Ringkasan preferensi khusus user atau catatan tambahan dalam Bahasa Indonesia yang ramah."
    }
  },
  required: ["location", "categories", "dateTime"]
};

/**
 * Schema for Itinerary Optimization with Gemini API
 */
export const geminiItineraryResponseSchema = {
  type: "OBJECT",
  properties: {
    tripTitle: {
      type: "STRING",
      description: "Judul menarik untuk rencana perjalanan ini (contoh: 'Jelajah Kuliner & Sejarah Semarang Sehari')"
    },
    summary: {
      type: "STRING",
      description: "Deskripsi ringkas dan tips menarik untuk keseluruhan itinerary ini."
    },
    stops: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          placeId: { type: "STRING" },
          name: { type: "STRING" },
          order: { type: "INTEGER" },
          suggestedArrivalTime: { type: "STRING", description: "Contoh: '09:00 WIB'" },
          suggestedDurationMinutes: { type: "INTEGER", description: "Durasi kunjungan dalam menit, contoh: 60" },
          activityTip: { type: "STRING", description: "Saran aktivitas menarik di lokasi ini" },
          estimatedCost: { type: "NUMBER", description: "Estimasi biaya di tempat ini dalam IDR" }
        },
        required: ["placeId", "name", "order", "suggestedArrivalTime", "suggestedDurationMinutes"]
      }
    }
  },
  required: ["tripTitle", "summary", "stops"]
};

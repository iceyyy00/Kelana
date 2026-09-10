# Spesifikasi Project: Kelana — AI Itinerary Planner App

## 1. Overview

Aplikasi mobile berbasis **Flutter** yang membantu user membuat rencana perjalanan (itinerary) hanya dengan mengetik permintaan bebas, contoh:

> "hari ini mau ke Semarang, budget 100rb, suka tempat kuliner"

Aplikasi akan:
1. Memahami permintaan user menggunakan **Gemini API** (natural language understanding)
2. Mencari tempat nyata yang relevan menggunakan **Google Places API**
3. Menyusun rekomendasi menjadi **itinerary terstruktur** (urutan kunjungan, estimasi waktu tempuh, rute)
4. Menampilkan hasil dalam **peta interaktif**
5. Menyimpan itinerary sehingga bisa diakses, diedit, dan dibagikan kembali

### Pembeda dari chatbot biasa (ChatGPT/Gemini langsung)
- Data tempat **real-time dan akurat** dari Google Places (bukan halusinasi LLM)
- Output berupa **itinerary tersimpan & bisa dieksekusi** (bukan sekadar teks jawaban)
- Ada **peta visual interaktif**, bukan hanya teks
- Ada **personalisasi berbasis histori** pemakaian user
- Bisa **di-share** ke orang lain

LLM (Gemini) berperan sebagai **reasoning layer di balik layar**, bukan produk utama. Produk utamanya adalah pengalaman terstruktur: itinerary tersimpan, peta, dan rute.

---

## 2. Tech Stack

| Layer | Tools/Package |
|---|---|
| Frontend | Flutter |
| State management | Riverpod (atau Provider — pilih satu, jangan campur) |
| Auth | Firebase Authentication (Email/Password + Google Sign-In) |
| Database | Firestore (`cloud_firestore`) |
| Maps | `google_maps_flutter` |
| Networking | `dio` atau `http` |
| Local storage ringan | `shared_preferences` |
| Routing | `go_router` |
| Backend/API proxy | Firebase Cloud Functions / Node.js (Express) / Python (FastAPI) — pilih salah satu |
| AI | Gemini API (chat & structured output/function calling) |
| Places data | Google Places API |
| Rute & estimasi waktu tempuh | Google Directions API |

> **Penting:** Gemini API dan Google Places API **tidak boleh dipanggil langsung dari Flutter**. Semua request harus lewat backend proxy agar API key tidak ter-expose di client, dan agar logic tambahan (gabungan hasil Gemini + Places) bisa diproses di server.

---

## 3. Arsitektur Alur Data

```
User mengetik permintaan (chat input)
        │
        ▼
Flutter App ──► Backend (API key aman di sini)
        │
        ├──► Gemini API
        │     - Extract intent: lokasi, budget, kategori, waktu, jumlah orang
        │     - Return structured JSON (bukan free text)
        │
        ├──► Google Places API
        │     - Search tempat berdasarkan hasil ekstraksi
        │     - Filter berdasarkan rating, price_level, jarak
        │
        ├──► Gemini API (tahap 2)
        │     - Susun tempat hasil pencarian menjadi itinerary berurutan
        │     - Pertimbangkan jarak antar lokasi & jam operasional
        │
        ├──► Google Directions API
        │     - Hitung estimasi waktu tempuh & rute antar lokasi
        │
        ▼
Backend gabungkan semua hasil → response terstruktur ke Flutter
        │
        ▼
Flutter tampilkan: hasil rekomendasi, itinerary, peta interaktif
```

---

## 4. Fitur

### 4.1 Autentikasi & User Management
- [ ] Register/Login (Email + Password)
- [ ] Login dengan Google Sign-In
- [ ] Session auto-login (token tersimpan lokal)
- [ ] Profile user: nama, foto, preferensi awal (opsional saat onboarding — kategori favorit)

### 4.2 Fitur Inti (Core)

**Chat Input & Parsing**
- [ ] UI chat sederhana (bubble chat)
- [ ] Kirim input user ke backend → Gemini API
- [ ] Gemini extract terstruktur: `location`, `budget`, `category`, `date/time`, `people_count` (opsional)
- [ ] Tampilkan hasil ekstraksi ke user untuk konfirmasi/koreksi sebelum lanjut

**Pencarian Tempat**
- [ ] Query ke Google Places API berdasarkan hasil parsing
- [ ] Filter berdasarkan budget (price_level), rating, jarak
- [ ] Tampilkan list hasil: nama, foto, rating, estimasi harga, jarak

**Itinerary Builder**
- [ ] Gemini susun urutan kunjungan optimal (pertimbangkan jarak & jam operasional)
- [ ] Tampilkan itinerary berurutan dengan estimasi waktu tempuh antar lokasi
- [ ] User bisa reorder (drag & drop), hapus, atau tambah tempat manual

**Peta Interaktif**
- [ ] Tampilkan semua tempat di itinerary dalam satu peta (`google_maps_flutter`)
- [ ] Gambar rute antar lokasi di peta
- [ ] Tap marker untuk lihat detail tempat

### 4.3 Fitur Pendukung

**Save & Manage Itinerary**
- [ ] Simpan itinerary ke Firestore
- [ ] List "itinerary saya" (riwayat)
- [ ] Edit/hapus itinerary tersimpan
- [ ] Tandai tempat yang sudah dikunjungi

**Personalisasi dari Histori**
- [ ] Simpan preferensi implisit dari histori (kategori sering dipilih, budget rata-rata)
- [ ] Kirim context tambahan dari histori user ke Gemini saat request baru

**Share Itinerary**
- [ ] Generate link/kode untuk share itinerary ke orang lain
- [ ] Viewable tanpa perlu login (opsional, tergantung scope)

---

## 5. Struktur Halaman (Screens)

1. Splash / Onboarding
2. Login / Register
3. Home (chat input + shortcut ke "itinerary saya")
4. Chat/Parsing (percakapan dengan AI, konfirmasi hasil ekstraksi)
5. Hasil Rekomendasi (list tempat)
6. Itinerary Detail (list + peta + reorder)
7. Saved Itineraries (riwayat)
8. Profile / Settings

---

## 6. Skema Data (Firestore — draft awal)

```
users/{userId}
  - name
  - email
  - photoUrl
  - preferences: { favoriteCategories: [], avgBudget: number }
  - createdAt

itineraries/{itineraryId}
  - userId (owner)
  - title
  - createdAt
  - status (draft/saved/completed)
  - rawQuery (input asli user)
  - parsedIntent: { location, budget, category, date, peopleCount }
  - places: [
      {
        placeId (dari Google Places),
        name,
        category,
        estimatedPrice,
        rating,
        lat, lng,
        order (urutan kunjungan),
        visited (boolean),
        estimatedTravelTimeFromPrevious (menit)
      }
    ]
  - shareCode (opsional, untuk fitur share)

history_interactions/{interactionId}
  - userId
  - query
  - selectedCategory
  - budget
  - timestamp
```

> Skema ini masih draft awal — perlu direview ulang saat implementasi, terutama bagian relasi `places` (apakah disimpan sebagai subcollection atau array embedded, tergantung skala data).

---

## 7. Backend Endpoint (draft awal)

| Endpoint | Method | Fungsi |
|---|---|---|
| `/parse-intent` | POST | Kirim raw text user → return hasil ekstraksi terstruktur dari Gemini |
| `/search-places` | POST | Kirim hasil ekstraksi → return list tempat dari Google Places API |
| `/build-itinerary` | POST | Kirim list tempat terpilih → return urutan itinerary + estimasi waktu tempuh dari Gemini + Directions API |
| `/itineraries` | GET/POST/PUT/DELETE | CRUD itinerary tersimpan (proxy ke Firestore atau langsung dari Flutter jika pakai Firestore SDK) |

---

## 8. Urutan Pengerjaan (Suggested Roadmap)

1. **Setup dasar**: Firebase project (Auth + Firestore), struktur navigasi dasar di Flutter
2. **Backend proxy**: buat endpoint sederhana untuk Gemini API & Google Places API
3. **Core flow tanpa itinerary**: chat input → parsing → tampil hasil rekomendasi tempat
4. **Itinerary builder**: susun urutan + integrasi peta
5. **Save & manage itinerary**: simpan ke Firestore, riwayat, edit/hapus
6. **Personalisasi & share**: fitur tambahan jika waktu memungkinkan

---

## 9. Catatan untuk AI Agent (Development Notes)

- Styling/UI **belum ditentukan** — fokus dulu ke fungsionalitas dan struktur data/logic yang benar. Jangan hardcode desain visual spesifik dulu.
- Gunakan **structured output / function calling** dari Gemini API untuk parsing intent, jangan andalkan parsing manual dari free text response.
- Pastikan semua API key (Gemini, Google Places, Google Directions) disimpan di backend, **tidak pernah** di-hardcode atau expose di kode Flutter.
- State management harus konsisten — pilih satu (disarankan Riverpod) dan pakai di seluruh project, jangan campur dengan `setState` manual untuk state global.
- Untuk demo/testing, siapkan mekanisme caching/fallback data agar app tetap bisa didemokan meski koneksi ke API eksternal lambat atau rate-limited.

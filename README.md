# 🧭 Kelana — AI Itinerary Planner App

Aplikasi perencana perjalanan cerdas berbasis **Flutter** dan **Node.js Express Backend Proxy** yang mengintegrasikan **Gemini API** (Natural Language Understanding & Reasoning) dan **Google Places + Directions API**.

---

## 🌟 Fitur Utama

1. **Natural Language Understanding (Gemini API)**:
   - User cukup mengetik bebas, misal: *"hari ini mau ke Semarang, budget 100rb, suka tempat kuliner"*.
   - Backend memproses via Gemini Structured Output untuk mengekstrak: lokasi, estimasi budget, kategori, waktu/durasi, dan jumlah orang.
2. **Kartu Konfirmasi Rencana**:
   - User dapat mengoreksi atau mengubah field intent sebelum mencari tempat.
3. **Data Tempat Nyata (Google Places API)**:
   - Menghasilkan rekomendasi tempat akurat lengkap dengan rating, estimasi harga tiket/makan, jam buka, dan foto.
   - Dilengkapi fallback cerdas dataset wisata Indonesia (Semarang, Yogyakarta, Bandung, Bali) sehingga aplikasi tetap dapat didemokan secara offline/tanpa kuota API.
4. **Itinerary Builder & Reasoning (Gemini + Directions API)**:
   - Gemini menyusun urutan kunjungan terbaik dengan mempertimbangkan jam operasional dan waktu makan siang/sore.
   - Google Directions API menghitung estimasi jarak & durasi perjalanan antar tempat.
5. **Peta Interaktif**:
   - Menampilkan titik-titik kunjungan berurutan dengan nomor stop dan jalur rute.
6. **Reorder Drag & Drop**:
   - User dapat mengatur ulang urutan destinasi secara bebas (`ReorderableListView`).
7. **Simpan & Bagikan (Share)**:
   - Riwayat perjalanan tersimpan dengan progress tempat yang sudah dikunjungi.
   - Fitur generate kode share (misal: `KLN-A83F12`) untuk berbagi rencana perjalanan ke teman.

---

## 📁 Struktur Project

```
Kelana/
├── backend/                       # Backend Proxy (Node.js Express)
│   ├── src/
│   │   ├── config/                # Konfigurasi & Environment
│   │   ├── mock/                  # Dataset destinasi Indonesia (Semarang, Jogja, Bandung, Bali)
│   │   ├── routes/                # Endpoint API: /parse-intent, /search-places, /build-itinerary
│   │   ├── schemas/               # Gemini Structured Output JSON Schema
│   │   ├── services/              # Gemini Service, Places Service, Directions Service
│   │   └── server.js              # Express Entry Point
│   ├── test/
│   │   └── test-api.js            # Automated integration tests
│   ├── .env                       # File konfigurasi API Key
│   └── package.json
│
├── kelana_app/                    # Frontend Mobile App (Flutter)
│   ├── lib/
│   │   ├── core/                  # Constants, Theme, Network Dio Client, GoRouter
│   │   ├── features/
│   │   │   ├── auth/              # Login & Register Screen
│   │   │   ├── chat/              # Conversational parser & Intent Confirmation Screen
│   │   │   ├── home/              # Home Screen & Quick Prompts
│   │   │   ├── itinerary/         # Interactive Map, Reorderable List, Travel Time
│   │   │   ├── places/            # Google Places recommendation cards & selection
│   │   │   ├── profile/           # Preferences & Server URL Config
│   │   │   ├── saved/             # Saved itineraries list & Share Code importer
│   │   │   └── splash/            # Animated Splash Screen
│   │   ├── models/                # ParsedIntent, Place, Itinerary, UserProfile
│   │   ├── providers/             # Riverpod State Management
│   │   ├── widgets/               # PlaceCard, ItineraryStopCard, MapViewWidget
│   │   └── main.dart              # Flutter Entry Point
│   └── pubspec.yaml
│
└── itinerary-app-spec (1).md      # Dokumen spesifikasi asli
```

---

## 🚀 Cara Menjalankan

### 1. Menjalankan Backend Proxy

Buka terminal di folder `backend`:
```bash
cd backend
npm install
npm start
```
Server akan berjalan di: `http://localhost:5000`

> **Catatan API Key:**
> Edit file `backend/.env` untuk memasukkan `GEMINI_API_KEY` dan `GOOGLE_PLACES_API_KEY`. Jika dibiarkan kosong, backend otomatis beralih ke **Smart Mock Fallback Mode** sehingga Anda dapat langsung mencoba flow secara utuh!

Untuk menguji seluruh endpoint backend secara otomatis:
```bash
node test/test-api.js
```

### 2. Menjalankan Aplikasi Flutter

Buka terminal di folder `kelana_app`:
```bash
cd kelana_app
flutter pub get
flutter run
```

Jika dijalankan di browser (Chrome) atau emulator:
- **Web / Chrome**: `flutter run -d chrome`
- **Android Emulator**: Base URL backend otomatis mengarah ke `http://10.0.2.2:5000/api`.
- **Perangkat Fisik**: Di aplikasi buka menu **Profil > Konfigurasi Backend Proxy**, masukkan IP Wi-Fi komputer Anda (misal `http://192.168.1.10:5000/api`) lalu tekan tombol **Tes Koneksi Server**.

---

## 🔒 Keamanan API Key

Sesuai spesifikasi, seluruh API Key pihak ketiga (**Gemini**, **Google Places**, **Google Directions**) hanya tersimpan di Backend Proxy (`backend/.env`) dan tidak pernah diexpose ke client Flutter.

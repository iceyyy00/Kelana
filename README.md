# 🧭 Kelana — AI Itinerary Planner App

Aplikasi perencana perjalanan cerdas berbasis **Flutter**, **Firebase**, dan **Node.js Express Backend Proxy** yang mengintegrasikan **Gemini API**, **Photon/OpenStreetMap** untuk pencarian tempat, dan **Google Directions API** untuk rute. Backend dapat dijalankan lokal atau di-deploy sebagai **Firebase Cloud Function**.

---

## 🌟 Fitur Utama

1. **Natural Language Understanding (Gemini API)**:
   - User cukup mengetik bebas, misal: *"hari ini mau ke Semarang, budget 100rb, suka tempat kuliner"*.
   - Backend memproses via Gemini Structured Output untuk mengekstrak: lokasi, estimasi budget, kategori, waktu/durasi, dan jumlah orang.
2. **Kartu Konfirmasi Rencana**:
   - User dapat mengoreksi atau mengubah field intent sebelum mencari tempat.
3. **Pencarian Tempat (Photon/OpenStreetMap)**:
   - Menghasilkan rekomendasi tempat dari data OSM, termasuk nama, kategori, alamat, dan koordinat. Photon tidak menyediakan rating, harga, atau foto.
   - Dilengkapi fallback dataset wisata Indonesia (Semarang, Yogyakarta, Bandung, Bali) sehingga aplikasi tetap dapat didemokan tanpa koneksi Photon.
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
├── backend/                       # Backend Proxy / Firebase Cloud Function
│   ├── src/
│   │   ├── config/                # Konfigurasi & Environment
│   │   ├── mock/                  # Dataset destinasi Indonesia (Semarang, Jogja, Bandung, Bali)
│   │   ├── routes/                # Endpoint API: /parse-intent, /search-places, /build-itinerary
│   │   ├── schemas/               # Gemini Structured Output JSON Schema
│   │   ├── services/              # Gemini Service, Places Service, Directions Service
│   │   ├── server.js              # Express App
│   │   └── index.js               # Firebase Cloud Functions Entry Point
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
│   │   │   ├── places/            # Photon/OSM recommendation cards & selection
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

## Menjalankan dan Mengonfigurasi

### Firebase

1. Pilih Firebase project (repository default: `kelana-f39b1`), aktifkan Email/Password dan Anonymous di Authentication, lalu buat Cloud Firestore.
2. Install and sign in to Firebase CLI, then configure the existing Flutter app (do not run `flutter create`):
```bash
npm install --global firebase-tools
firebase login
firebase use --add
cd kelana_app
dart pub global activate flutterfire_cli
flutterfire configure --project=kelana-f39b1 --platforms=android,ios
flutter pub get
```
FlutterFire registers the native Firebase apps and generates `lib/firebase_options.dart`. The current Android/iOS startup uses the native Firebase configuration; include the web platform in `flutterfire configure` and initialize with `DefaultFirebaseOptions.currentPlatform` before enabling Firebase on web.
3. Firestore itinerary records are stored by the authenticated backend under `users/{uid}/itineraries`; deploy the included rules and function from the repository root:
```bash
firebase deploy --only firestore:rules,functions:backend
```
The backend verifies Firebase ID tokens. Its local development fallback stores itineraries in memory and is not persistent.

### Gemini, Photon, and Directions

Gemini intent parsing/itinerary ordering and Google Directions routing run through the backend. Place search uses the public Photon API backed by OpenStreetMap and requires no API key. Create a Gemini key in Google AI Studio and enable the Directions API in Google Cloud. Set backend secrets (the CLI prompts for each value; do not commit keys):
```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set GOOGLE_DIRECTIONS_API_KEY
```
For local backend development, copy `backend/.env.example` to `backend/.env` and set the server-side keys there.

### Native Maps SDK Keys

Maps SDK keys are separate from the backend Directions key. Restrict each key to its platform app and the Maps SDK; mobile keys are packaged in the app and are not secret storage.

- Android: add `googleMapsApiKey=YOUR_ANDROID_KEY` to the ignored `kelana_app/android/local.properties`. The manifest reads it through the Gradle placeholder.
- iOS: copy `kelana_app/ios/Flutter/Secrets.xcconfig.example` to `Secrets.xcconfig` in the same folder and set `GOOGLE_MAPS_API_KEY = YOUR_IOS_KEY`. That file is ignored by git and is read from `Info.plist` at startup.

### Run

The backend runs locally at `http://localhost:5000`:
```bash
npm --prefix backend install
npm --prefix backend start
```
Flutter web defaults to `http://localhost:5000`; Android emulators use `http://10.0.2.2:5000`, and iOS simulators use `http://localhost:5000`. To use a remote backend, pass its deployed function URL explicitly:
```bash
cd kelana_app
flutter run --dart-define=KELANA_API_BASE_URL=https://asia-southeast1-kelana-f39b1.cloudfunctions.net/backend
```
Verify the backend with `npm --prefix backend test` while it is running.

Firebase client configuration (project identifiers and Firebase client API key) is not a substitute for security rules. Restrict Google Maps keys by platform and API, keep Gemini/Places/Directions keys in backend secrets, and never put server keys in Flutter code.

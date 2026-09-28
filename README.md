# 🧭 Kelana — AI Itinerary Planner App

Aplikasi perencana perjalanan cerdas berbasis **Flutter**, **Firebase**, dan **Node.js Express Backend Proxy** yang mengintegrasikan **Gemini API** (Natural Language Understanding & Reasoning) dan **Google Places + Directions API**. Backend dapat dijalankan lokal atau di-deploy sebagai **Firebase Cloud Function**.

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

### 1. Menjalankan backend lokal (opsional)

```bash
npm --prefix backend install
npm --prefix backend start
```
Server berjalan di `http://localhost:5000`.

### 2. Menyiapkan Firebase, Gemini, Places, dan Firestore

1. Gunakan project Firebase `kelana-f39b1`, aktifkan **Authentication** (Email/Password dan Anonymous), dan buat database **Cloud Firestore** di region `asia-southeast1` agar sejalan dengan region Functions. Deploy Cloud Functions memerlukan paket Blaze.
2. Pada Google Cloud project yang sama, aktifkan **Places API** dan **Directions API** serta billing. Buat API key server untuk Places/Directions dan batasi key tersebut ke API yang digunakan; buat Gemini API key melalui Google AI Studio. Peta Flutter juga membutuhkan Maps SDK key terpisah yang dibatasi ke Android app dan website, lalu dipasang hanya pada konfigurasi platform.
3. Dari root repository, instal Firebase CLI, login, lalu pilih project:
```bash
npm install --global firebase-tools
firebase login
firebase use --add
```

4. Simpan API key sebagai Firebase secrets. Jangan masukkan key ke Flutter atau commit ke repository:
```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set GOOGLE_PLACES_API_KEY
firebase functions:secrets:set GOOGLE_DIRECTIONS_API_KEY
```
Places dan Directions dapat memakai key Google yang sama dengan mengatur kedua secret ke nilai yang sama.

5. Deploy Firestore rules dan fungsi backend:
```bash
npm --prefix backend install
firebase deploy --only firestore:rules,functions:backend
```
Cloud Function API base URL: `https://asia-southeast1-kelana-f39b1.cloudfunctions.net/backend`. Fungsi memverifikasi Firebase ID token dan menyimpan itinerary di `users/{uid}/itineraries`.

### 3. Menyiapkan dan menjalankan Flutter

Checkout ini belum menyertakan direktori platform Android/web. Dari `kelana_app`, buat target tersebut, lalu daftarkan app Firebase:

```bash
cd kelana_app
flutter create --platforms=android,web .
dart pub global activate flutterfire_cli
flutterfire configure --project=kelana-f39b1
flutter pub get
```

`flutterfire configure` menghasilkan `lib/firebase_options.dart`. Untuk web (dan konfigurasi lintas platform yang eksplisit), import file tersebut di `lib/main.dart` lalu inisialisasi Firebase seperti berikut:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```
Tambahkan Maps SDK key yang dibatasi ke app Android pada `<application>` di `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_SDK_KEY" />
```
Untuk web, tambahkan script Maps JavaScript API dengan website-restricted key ke `<head>` di `web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_MAPS_SDK_KEY"></script>
```
Jangan memakai API key server pada salah satu file platform.

Jalankan aplikasi terhadap Cloud Function (URL tersebut sudah menjadi default; `--dart-define` tetap dapat dipakai untuk override):
```bash
flutter run --dart-define=KELANA_API_BASE_URL=https://asia-southeast1-kelana-f39b1.cloudfunctions.net/backend
```
Untuk kerja lokal, jalankan `npm --prefix backend start` lalu override URL untuk platform target, misalnya `--dart-define=KELANA_API_BASE_URL=http://10.0.2.2:5000` pada Android emulator atau `http://localhost:5000` pada web. Backend lokal beralih ke dataset fallback bila API key tidak tersedia dan memakai identitas `local-development`; itinerary lokal disimpan in-memory. Perangkat fisik dapat menggunakan URL backend lokal melalui **Profil > Konfigurasi Backend Proxy**, misalnya `http://192.168.1.10:5000`.

Tes endpoint backend lokal dengan server berjalan:
```bash
npm --prefix backend test
```

---

## 🔒 Keamanan API Key

Seluruh API key pihak ketiga (**Gemini**, **Google Places**, **Google Directions**) hanya diakses backend. Saat deploy, simpan sebagai Firebase Functions secrets; untuk backend lokal gunakan `backend/.env` (tidak dilacak git). Jangan pernah menyimpan key tersebut di aplikasi Flutter.

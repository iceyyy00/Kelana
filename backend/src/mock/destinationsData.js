/**
 * Realistic Mock Data for Indonesian Tourist Destinations
 * Used for offline testing, demos, and graceful fallback when external API quotas are exceeded.
 */

export const mockDestinations = {
  semarang: [
    {
      placeId: "smg_lawang_sewu",
      name: "Lawang Sewu",
      category: "Wisata Sejarah",
      rating: 4.6,
      userRatingsTotal: 48200,
      priceLevel: 1,
      estimatedPrice: 20000,
      lat: -6.9840,
      lng: 110.4103,
      address: "Jl. Pemuda No.160, Sekayu, Kec. Semarang Tengah, Kota Semarang",
      photoUrl: "https://images.unsplash.com/photo-1596402184320-417e7178b2cd?w=600&auto=format&fit=crop&q=80",
      description: "Gedung bersejarah peninggalan kolonial Belanda dengan arsitektur pintu seribu yang megah dan museum kereta api.",
      openingHours: "08:00 - 20:00 WIB"
    },
    {
      placeId: "smg_sam_poo_kong",
      name: "Klenteng Sam Poo Kong",
      category: "Wisata Budaya & Religi",
      rating: 4.5,
      userRatingsTotal: 34100,
      priceLevel: 1,
      estimatedPrice: 25000,
      lat: -6.9962,
      lng: 110.3981,
      address: "Jl. Simongan No.129, Bongsari, Kec. Semarang Barat, Kota Semarang",
      photoUrl: "https://images.unsplash.com/photo-1548013146-72479768bbaa?w=600&auto=format&fit=crop&q=80",
      description: "Klenteng tertua bernuansa akulturasi budaya Tionghoa dan Jawa, bekas tempat persinggahan Laksamana Cheng Ho.",
      openingHours: "08:00 - 20:00 WIB"
    },
    {
      placeId: "smg_kota_lama",
      name: "Kawasan Kota Lama Semarang",
      category: "Wisata Sejarah & Foto",
      rating: 4.7,
      userRatingsTotal: 52000,
      priceLevel: 0,
      estimatedPrice: 0,
      lat: -6.9680,
      lng: 110.4281,
      address: "Bandarharjo, Kec. Semarang Utara, Kota Semarang",
      photoUrl: "https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=600&auto=format&fit=crop&q=80",
      description: "Little Netherland dengan bangunan Eropa kuno terawat, Gereja Blenduk, kafe estetik, dan spot foto menarik.",
      openingHours: "Buka 24 Jam"
    },
    {
      placeId: "smg_lumpia_gang_lombok",
      name: "Lumpia Gang Lombok No. 11",
      category: "Kuliner Khas",
      rating: 4.6,
      userRatingsTotal: 8900,
      priceLevel: 1,
      estimatedPrice: 22000,
      lat: -6.9742,
      lng: 110.4261,
      address: "Gang Lombok No.11, Purwodinatan, Kec. Semarang Tengah, Kota Semarang",
      photoUrl: "https://images.unsplash.com/photo-1544025162-d76694265947?w=600&auto=format&fit=crop&q=80",
      description: "Pelopor lumpia legendaris di Semarang sejak abad ke-19, menyajikan lumpia basah dan goreng dengan rebung istimewa.",
      openingHours: "08:00 - 17:00 WIB"
    },
    {
      placeId: "smg_soto_bangkong",
      name: "Soto Bangkong Asli",
      category: "Kuliner Khas",
      rating: 4.4,
      userRatingsTotal: 15400,
      priceLevel: 1,
      estimatedPrice: 25000,
      lat: -6.9936,
      lng: 110.4326,
      address: "Jl. Brigjen Katamso No.1, Peterongan, Kec. Semarang Selatan, Kota Semarang",
      photoUrl: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop&q=80",
      description: "Soto ayam berkuah cokelat bening khas Semarang dengan pelengkap sate kerang, perkedel, dan tempe renyah.",
      openingHours: "07:00 - 22:00 WIB"
    },
    {
      placeId: "smg_tahu_gimbal_pak_man",
      name: "Tahu Gimbal Pak Man",
      category: "Kuliner Khas",
      rating: 4.5,
      userRatingsTotal: 6200,
      priceLevel: 1,
      estimatedPrice: 20000,
      lat: -6.9912,
      lng: 110.4219,
      address: "Jl. Plampitan No.54, Bangunharjo, Kec. Semarang Tengah, Kota Semarang",
      photoUrl: "https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=600&auto=format&fit=crop&q=80",
      description: "Tahu gimbal porsi melimpah dengan bakwan udang renyah, lontong, tauge, dan bumbu petis kacang mantap.",
      openingHours: "10:00 - 16:00 WIB"
    }
  ],
  yogyakarta: [
    {
      placeId: "jog_prambanan",
      name: "Candi Prambanan",
      category: "Wisata Sejarah & Budaya",
      rating: 4.7,
      userRatingsTotal: 78000,
      priceLevel: 2,
      estimatedPrice: 50000,
      lat: -7.7520,
      lng: 110.4915,
      address: "Jl. Raya Solo - Yogyakarta No.16, Kranggan, Bokoharjo, Prambanan",
      photoUrl: "https://images.unsplash.com/photo-1596402184320-417e7178b2cd?w=600&auto=format&fit=crop&q=80",
      description: "Kompleks candi Hindu terbesar dan termegah di Indonesia berlatar arsitektur batu menjulang indah.",
      openingHours: "06:30 - 17:00 WIB"
    },
    {
      placeId: "jog_keraton",
      name: "Keraton Ngayogyakarta Hadiningrat",
      category: "Wisata Budaya",
      rating: 4.6,
      userRatingsTotal: 42000,
      priceLevel: 1,
      estimatedPrice: 15000,
      lat: -7.8053,
      lng: 110.3642,
      address: "Jl. Rotowijayan Blok No. 1, Panembahan, Kraton, Kota Yogyakarta",
      photoUrl: "https://images.unsplash.com/photo-1548013146-72479768bbaa?w=600&auto=format&fit=crop&q=80",
      description: "Pusat kebudayaan Jawa yang masih hidup, istana Sultan dengan museum pusaka dan pertunjukan gamelan.",
      openingHours: "08:30 - 14:00 WIB"
    },
    {
      placeId: "jog_tamansari",
      name: "Taman Sari Water Castle",
      category: "Wisata Sejarah & Foto",
      rating: 4.5,
      userRatingsTotal: 31000,
      priceLevel: 1,
      estimatedPrice: 15000,
      lat: -7.8099,
      lng: 110.3592,
      address: "Patehan, Kecamatan Kraton, Kota Yogyakarta",
      photoUrl: "https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=600&auto=format&fit=crop&q=80",
      description: "Bekas taman pemandian istana dan masjid bawah tanah dengan lorong mistis yang fotogenik.",
      openingHours: "09:00 - 15:00 WIB"
    },
    {
      placeId: "jog_gudeg_yu_djum",
      name: "Gudeg Yu Djum Wijilan 167",
      category: "Kuliner Khas",
      rating: 4.5,
      userRatingsTotal: 22000,
      priceLevel: 1,
      estimatedPrice: 35000,
      lat: -7.8041,
      lng: 110.3675,
      address: "Jl. Wijilan No.167, Panembahan, Kraton, Kota Yogyakarta",
      photoUrl: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop&q=80",
      description: "Gudeg kering legendaris dimasak dengan kayu bakar, disajikan bersama krecek pedas dan ayam kampung.",
      openingHours: "06:00 - 22:00 WIB"
    },
    {
      placeId: "jog_malioboro",
      name: "Jalan Malioboro & Teras Malioboro",
      category: "Belanja & Kuliner",
      rating: 4.7,
      userRatingsTotal: 95000,
      priceLevel: 1,
      estimatedPrice: 20000,
      lat: -7.7928,
      lng: 110.3658,
      address: "Jl. Malioboro, Sosromenduran, Gedong Tengen, Kota Yogyakarta",
      photoUrl: "https://images.unsplash.com/photo-1544025162-d76694265947?w=600&auto=format&fit=crop&q=80",
      description: "Jantung kota Jogja untuk jalan santai, belanja oleh-oleh batik, bakpia, dan menikmati suasana malam.",
      openingHours: "Buka 24 Jam"
    }
  ],
  bandung: [
    {
      placeId: "bdg_gedung_sate",
      name: "Gedung Sate & Museum",
      category: "Wisata Sejarah",
      rating: 4.6,
      userRatingsTotal: 31000,
      priceLevel: 1,
      estimatedPrice: 10000,
      lat: -6.9025,
      lng: 107.6186,
      address: "Jl. Diponegoro No.22, Citarum, Kec. Bandung Wetan, Kota Bandung",
      photoUrl: "https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=600&auto=format&fit=crop&q=80",
      description: "Ikon arsitektur khas Bandung dengan ornamen tusuk sate dan museum interaktif berteknologi tinggi.",
      openingHours: "09:30 - 16:00 WIB"
    },
    {
      placeId: "bdg_braga",
      name: "Jalan Braga Heritage Walk",
      category: "Wisata Kota & Kafe",
      rating: 4.7,
      userRatingsTotal: 58000,
      priceLevel: 1,
      estimatedPrice: 30000,
      lat: -6.9175,
      lng: 107.6096,
      address: "Jl. Braga, Sumur Bandung, Kota Bandung",
      photoUrl: "https://images.unsplash.com/photo-1548013146-72479768bbaa?w=600&auto=format&fit=crop&q=80",
      description: "Kawasan bernuansa Paris van Java dengan deretan kafe estetik, toko kue legendaris, dan lukisan jalanan.",
      openingHours: "Buka 24 Jam"
    },
    {
      placeId: "bdg_tebing_keraton",
      name: "Tebing Keraton",
      category: "Wisata Alam",
      rating: 4.6,
      userRatingsTotal: 18000,
      priceLevel: 1,
      estimatedPrice: 17000,
      lat: -6.8341,
      lng: 107.6636,
      address: "Ciburial, Kec. Cimenyan, Kabupaten Bandung Barat",
      photoUrl: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600&auto=format&fit=crop&q=80",
      description: "Pemandangan kabut pagi dan hamparan hutan pinus Taman Hutan Raya Ir. H. Djuanda dari ketinggian tebing.",
      openingHours: "05:00 - 18:00 WIB"
    },
    {
      placeId: "bdg_paskal_food_market",
      name: "Paskal Food Market",
      category: "Kuliner",
      rating: 4.5,
      userRatingsTotal: 29000,
      priceLevel: 2,
      estimatedPrice: 45000,
      lat: -6.9154,
      lng: 107.5956,
      address: "Paskal Hyper Square, Jl. Pasir Kaliki No.25-27, Kota Bandung",
      photoUrl: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop&q=80",
      description: "Pusat kuliner outdoor dengan lebih dari 100 tenant kuliner khas Nusantara dan modern.",
      openingHours: "10:00 - 23:00 WIB"
    }
  ],
  bali: [
    {
      placeId: "bali_tanah_lot",
      name: "Pura Tanah Lot",
      category: "Wisata Budaya & Alam",
      rating: 4.7,
      userRatingsTotal: 84000,
      priceLevel: 2,
      estimatedPrice: 30000,
      lat: -8.6212,
      lng: 115.0868,
      address: "Beraban, Kec. Kediri, Kabupaten Tabanan, Bali",
      photoUrl: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600&auto=format&fit=crop&q=80",
      description: "Pura sakral di atas bongkahan batu karang besar di tengah deburan ombak samudra, spektakuler saat sunset.",
      openingHours: "06:00 - 19:00 WITA"
    },
    {
      placeId: "bali_monkey_forest",
      name: "Sacred Monkey Forest Sanctuary Ubud",
      category: "Wisata Alam & Budaya",
      rating: 4.6,
      userRatingsTotal: 51000,
      priceLevel: 2,
      estimatedPrice: 80000,
      lat: -8.5194,
      lng: 115.2631,
      address: "Jl. Monkey Forest, Ubud, Kecamatan Ubud, Kabupaten Gianyar, Bali",
      photoUrl: "https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=600&auto=format&fit=crop&q=80",
      description: "Hutan lindung nan asri yang dihuni ratusan monyet ekor panjang dan candi-candi kuno mistis.",
      openingHours: "09:00 - 18:00 WITA"
    },
    {
      placeId: "bali_campuhan",
      name: "Campuhan Ridge Walk",
      category: "Wisata Alam & Trekking",
      rating: 4.6,
      userRatingsTotal: 19000,
      priceLevel: 0,
      estimatedPrice: 0,
      lat: -8.5036,
      lng: 115.2547,
      address: "Kelusa, Payangan, Jl. Raya Campuan, Sayan, Kecamatan Ubud, Bali",
      photoUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80",
      description: "Jalur jalan santai menyusuri bukit berpadang ilalang hijau dengan lembah sungai di kedua sisi.",
      openingHours: "Buka 24 Jam"
    }
  ]
};

/**
 * Helper to get places for a given location query with fallback
 */
export function getMockPlacesForLocation(location, categories = [], budget = 0) {
  const locLower = (location || '').toLowerCase().trim();

  let matchedKey = Object.keys(mockDestinations).find(key => 
    locLower.includes(key) || key.includes(locLower)
  );

  if (!matchedKey) {
    // Default fallback to Semarang or Jogja
    matchedKey = 'semarang';
  }

  let places = [...mockDestinations[matchedKey]];

  // If user specified categories, we can prioritize them
  if (categories && categories.length > 0) {
    const catKeywords = categories.map(c => c.toLowerCase());
    places.sort((a, b) => {
      const aMatches = catKeywords.some(k => a.category.toLowerCase().includes(k) || a.description.toLowerCase().includes(k));
      const bMatches = catKeywords.some(k => b.category.toLowerCase().includes(k) || b.description.toLowerCase().includes(k));
      return (bMatches ? 1 : 0) - (aMatches ? 1 : 0);
    });
  }

  // Filter or flag by budget if specified
  if (budget > 0) {
    // Keep places that can fit reasonable budget
    places = places.filter(p => p.estimatedPrice <= budget);
    if (places.length < 3) {
      // Fallback: restore full list so user gets recommendations
      places = [...mockDestinations[matchedKey]];
    }
  }

  return places;
}

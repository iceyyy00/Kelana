import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_creation_provider.dart';
import '../../providers/saved_itineraries_provider.dart';
import '../../widgets/kelana_navigation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  int _selectedFilterIndex = 0;
  final Set<String> _bookmarkedPlaces = {};

  final List<String> _quickFilterChips = [
    'Weekend trip',
    'Wisata Kuliner',
    'Hemat / Budget',
    'Alam & Budaya',
  ];

  final List<IconData> _quickFilterIcons = [
    Icons.weekend_rounded,
    Icons.restaurant_rounded,
    Icons.savings_rounded,
    Icons.forest_rounded,
  ];

  final List<String> _promptSuggestions = [
    '✨ 3 hari santai Bali < 4jt',
    '☕ Cafe hidden gem di Semarang',
    '🍜 Kulineran 24 jam Bandung',
    '🌿 Trip alam keluarga Jogja',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _submitQuery(String query) {
    if (query.trim().isEmpty) return;
    _promptController.text = query;
    final tripNotifier = ref.read(tripCreationProvider.notifier);
    context.push('/chat');
    tripNotifier.submitPrompt(query);
  }

  void _toggleBookmark(String placeId) {
    setState(() {
      if (_bookmarkedPlaces.contains(placeId)) {
        _bookmarkedPlaces.remove(placeId);
      } else {
        _bookmarkedPlaces.add(placeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final savedList = ref.watch(savedItinerariesProvider);
    final userName = auth.user?.name ?? 'Maya';

    return Scaffold(
      backgroundColor: AppColors.htmlSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCustomHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingSection(userName),
                    const SizedBox(height: 24),
                    _buildHeroPlanningCard(),
                    const SizedBox(height: 24),
                    _buildQuickPlansFilter(),
                    const SizedBox(height: 28),
                    _buildActiveItinerarySection(savedList),
                    const SizedBox(height: 28),
                    _buildExploreAroundSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const KelanaBottomNavigation(currentPath: '/home'),
    );
  }

  // Header matching HTML: fixed h-16, Logo, Kelana / Home, Notification & Avatar
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.htmlSurface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/logoonly2.png',
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.htmlPrimaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.explore, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Kelana',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.htmlPrimaryContainer,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.htmlBorder,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Home',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.htmlTextSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.htmlTextSecondary,
                  size: 22,
                ),
                splashRadius: 22,
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.htmlPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Warm Minimalist Greeting Section
  Widget _buildGreetingSection(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SENIN, 14 OKTOBER',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppColors.htmlTextTertiary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.htmlSurfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 14,
                    color: AppColors.htmlPrimaryContainer,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '29°C Cerah',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.htmlPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Selamat Pagi, $userName',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.htmlPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Mau ke mana selanjutnya?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: AppColors.htmlTextSecondary,
          ),
        ),
      ],
    );
  }

  // Utilitarian Hero Planning Card
  Widget _buildHeroPlanningCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.htmlSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.htmlBorder.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3D47).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header inside card: AI Kelana & Gemini Powered
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.htmlSurfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.htmlPrimaryContainer,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Kelana',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.htmlPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.htmlSurfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Gemini Powered',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.htmlTextTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Text Area
              TextField(
                controller: _promptController,
                maxLines: 3,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.htmlPrimary,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Mau liburan ke mana, budget berapa, atau butuh rekomendasi apa? Ketik di sini...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.htmlTextTertiary,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              // Bottom actions inside card
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.htmlBorder.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildActionIconBtn(
                          icon: Icons.add,
                          tooltip: 'Tambah lampiran atau preferensi',
                          onTap: () {},
                        ),
                        const SizedBox(width: 4),
                        _buildActionIconBtn(
                          icon: Icons.near_me_outlined,
                          tooltip: 'Gunakan lokasi saat ini',
                          onTap: () {},
                        ),
                        const SizedBox(width: 4),
                        _buildActionIconBtn(
                          icon: Icons.mic_none_outlined,
                          tooltip: 'Input suara',
                          onTap: () {},
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _submitQuery(_promptController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.htmlPrimaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rencanakan',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_upward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal Suggestion Chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _promptSuggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final suggestion = _promptSuggestions[index];
              return InkWell(
                onTap: () => _submitQuery(suggestion
                    .replaceFirst('✨ ', '')
                    .replaceFirst('☕ ', '')
                    .replaceFirst('🍜 ', '')
                    .replaceFirst('🌿 ', '')),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.htmlSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.htmlBorder.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.htmlPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: AppColors.htmlTextSecondary,
        ),
      ),
    );
  }

  // Quick Plans Filter Chips
  Widget _buildQuickPlansFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rencana Cepat',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.htmlPrimary,
              ),
            ),
            Text(
              'Berdasarkan gaya bepergian',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.htmlTextTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickFilterChips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _selectedFilterIndex == index;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.htmlPrimaryContainer
                        : AppColors.htmlSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppColors.htmlBorder.withValues(alpha: 0.6),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _quickFilterIcons[index],
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.htmlTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _quickFilterChips[index],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.htmlTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Active Itinerary / Your Trips Section
  Widget _buildActiveItinerarySection(List savedList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Perjalanan Anda',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.htmlPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.htmlSurfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${savedList.isNotEmpty ? savedList.length : 1}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.htmlPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => context.push('/trips'),
              child: const Row(
                children: [
                  Text(
                    'Semua trip',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.htmlPrimaryContainer,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.htmlPrimaryContainer,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Real Trip Card
        GestureDetector(
          onTap: () => context.push('/itinerary'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.htmlSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image with Overlays
                Stack(
                  children: [
                    SizedBox(
                      height: 176,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDpW9ftxHZo8dHg1Os3oYzbuETXrizZtVrg_safpRjN0vwIzDaejnIQrt0SULALfQOi50dfo6IC0HMja1xMlCLaLnn5ShYUvdLFDyfzXYK1VKLq20l8N6cLT6rm1lYfIgbeyD-tVDqE14bbLIxPUZzK-sXm71Q27JwNRZn4i0gAgzqi8CoMOtRVcubV4vKU5bU6KV2d488NFl-DwE2ormAi965ksbyNiqN6PozfXTc',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.htmlSurfaceContainer,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.htmlSurfaceContainer,
                          child: const Icon(Icons.image,
                              size: 40, color: AppColors.htmlTextTertiary),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.htmlPrimary.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.htmlSurface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Terkonfirmasi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.htmlPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom title & countdown
                    const Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '4 HARI LAGI',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: AppColors.htmlPrimaryFixed,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '3 Hari di Ubud & Kintamani',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Details Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTripInfoCol('Jadwal', '18 - 21 Okt'),
                          _buildTripInfoCol('Estimasi', 'Rp 3.200.000'),
                          _buildTripInfoCol('Agenda', '6 Tempat'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Footer Banner: Pemberhentian
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.htmlSurfaceContainer,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 18,
                              color: AppColors.htmlTextSecondary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pemberhentian: Campuhan Ridge Walk',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.htmlTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Detail',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.htmlPrimaryContainer,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.htmlPrimaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.htmlTextTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.htmlPrimary,
          ),
        ),
      ],
    );
  }

  // Explore Around You Section
  Widget _buildExploreAroundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jelajahi Sekitar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.htmlPrimary,
                  ),
                ),
                Text(
                  'Rekomendasi terdekat dari lokasi Anda',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.htmlTextTertiary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/recommendations'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Peta',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.htmlPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Explore Card 1: Lawang Sewu
        _buildExploreCard(
          id: 'lawang_sewu',
          category: 'WISATA SEJARAH',
          rating: '4.7',
          reviews: '(2.4k)',
          title: 'Lawang Sewu Cultural Heritage',
          desc:
              'Ikon arsitektur kolonial megah dengan lorong lengkung khas dan nilai sejarah perkeretaapian Indonesia.',
          distanceInfo: '1.8 km dari sini',
          distanceIcon: Icons.location_on_outlined,
          price: 'Rp 20.000 / org',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBqnHZCFx5YvfUsqigSvglUkGE1N6PLxPlp4kaR0uY9zGZYSjCZVYoLSYOH2CCJatn2Ym9Vtsl0KH_nCcPGsmeb4HbXhNZyPyf3UaW6Nrxms5CgRpS6EBX0MLWVVeryrisNcd8QttMPlWtSY88e7AOJlbCE75qCRVnF24uF01ltbibeWf726hXrVy9zsvdyF6mDBiXWqF-utmkNf_YMxMp4lsx67FDV_tjEHGFllUQ',
        ),
        const SizedBox(height: 14),
        // Explore Card 2: Kopi Toko Djawa
        _buildExploreCard(
          id: 'kopi_toko_djawa',
          category: 'KEDAI KOPI & SANTAI',
          rating: '4.8',
          reviews: '(980)',
          title: 'Kopi Toko Djawa',
          desc:
              'Kopi susu awan legendaris dan donat klasik dalam suasana hangat bernuansa retro kontemporer.',
          distanceInfo: '650 m • 8 mnt jalan kaki',
          distanceIcon: Icons.near_me_outlined,
          price: 'Rp 25.000 - 45.000',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBI4K2u4l6Wpv3Xd6l__VcHgux3zsCmAkhA9RUlmYIc7sq5VBCBuIaGeNcHu_6jQU85YbRO0aRUwIP5JlAeIaR88pFQL0Qc61xszx8UvXSH9ufOd5PshNF4s0vhbRTGu7inneDPIc9IzVDjZ0SE5nHRX6PYs18AhZQFL8tvLLKdTZH8WYePb3B_1DN0UR0FKQz_Yfk0CE4FqsaWikYD6YNg3Ck1mHV08txeJj8Pck8',
        ),
      ],
    );
  }

  Widget _buildExploreCard({
    required String id,
    required String category,
    required String rating,
    required String reviews,
    required String title,
    required String desc,
    required String distanceInfo,
    required IconData distanceIcon,
    required String price,
    required String imageUrl,
  }) {
    final isBookmarked = _bookmarkedPlaces.contains(id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.htmlSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with bookmark button
          Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.htmlSurfaceContainer,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.htmlSurfaceContainer,
                    child: const Icon(Icons.image,
                        size: 40, color: AppColors.htmlTextTertiary),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _toggleBookmark(id),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.htmlSurface.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                      color: isBookmarked
                          ? AppColors.htmlSecondary
                          : AppColors.htmlPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.htmlTextTertiary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.htmlPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          reviews,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.htmlTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.htmlPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.htmlTextSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          distanceIcon,
                          size: 15,
                          color: AppColors.htmlTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceInfo,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.htmlTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.htmlPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_creation_provider.dart';
import '../../providers/saved_itineraries_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  final List<String> _quickPrompts = [
    'hari ini mau ke Semarang, budget 100rb, suka tempat kuliner',
    'liburan 1 hari di Jogja, suka candi dan foto estetik',
    'akhir pekan di Bandung, budget 200rb, mau ke tempat alam dan kafe',
    'sunset di Bali, cari spot alam dan budaya',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitQuery(String query) async {
    if (query.trim().isEmpty) return;
    _searchController.text = query;

    // Trigger trip creation
    final tripNotifier = ref.read(tripCreationProvider.notifier);
    context.push('/chat');
    tripNotifier.submitPrompt(query);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final savedList = ref.watch(savedItinerariesProvider);
    final userName = auth.user?.name ?? 'Sobat Kelana';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Kelana',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Itinerary Saya',
            onPressed: () => context.push('/saved'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Banner
            Text(
              'Halo, $userName! 🎒',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mau jalan-jalan ke mana hari ini?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            // Hero Chat Input Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.amberAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Ketik Bebas Keinginan Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: hari ini ke Semarang 100rb kuliner...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.black38,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: _submitQuery,
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          onPressed: () => _submitQuery(_searchController.text),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Inspiration Chips
            const Text(
              'Inspirasi Cepat 💡',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            Column(
              children: _quickPrompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _submitQuery(prompt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              prompt,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Saved Itineraries Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itinerary Tersimpan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/saved'),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),

            if (savedList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Belum ada itinerary tersimpan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ketik rencana perjalanan di atas untuk mulai membuat!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: savedList.take(2).map((itin) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.place, color: AppColors.primary),
                      ),
                      title: Text(
                        itin.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${itin.places.length} tempat • ${itin.location}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        // Open itinerary detail
                        ref.read(tripCreationProvider.notifier).reset();
                        context.push('/itinerary');
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

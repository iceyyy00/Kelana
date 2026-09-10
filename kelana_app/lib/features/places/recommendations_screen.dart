import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_creation_provider.dart';
import '../../widgets/place_card.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  String _selectedCategoryFilter = 'Semua';

  void _handleBuildItinerary() async {
    final tripNotifier = ref.read(tripCreationProvider.notifier);
    final success = await tripNotifier.buildItinerary();
    if (success && mounted) {
      context.push('/itinerary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripCreationProvider);
    final places = tripState.recommendedPlaces;
    final selectedPlaces = tripState.selectedPlaces;
    final intent = tripState.parsedIntent;

    // Filter by category if selected
    final filteredPlaces = _selectedCategoryFilter == 'Semua'
        ? places
        : places.where((p) => p.category.toLowerCase().contains(_selectedCategoryFilter.toLowerCase())).toList();

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final totalSelectedCost =
        selectedPlaces.fold(0, (sum, p) => sum + p.estimatedPrice);

    return Scaffold(
      appBar: AppBar(
        title: Text('Destinasi di ${intent?.location ?? "Kota"}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: tripState.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    tripState.loadingMessage ?? 'Sedang memproses...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top Info & Filter Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pilih tempat yang ingin Anda kunjungi:',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${selectedPlaces.length} dipilih',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Semua',
                            'Kuliner',
                            'Wisata Sejarah',
                            'Wisata Budaya',
                            'Wisata Alam',
                          ].map((cat) {
                            final isSel = _selectedCategoryFilter == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSel,
                                selectedColor: AppColors.primary.withOpacity(0.15),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategoryFilter = cat;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.border),

                // Place cards list
                Expanded(
                  child: filteredPlaces.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada tempat pada kategori ini.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredPlaces.length,
                          itemBuilder: (context, index) {
                            final place = filteredPlaces[index];
                            final isSelected = selectedPlaces.any(
                              (p) => p.placeId == place.placeId,
                            );

                            return PlaceCard(
                              place: place,
                              isSelected: isSelected,
                              onToggleSelect: () {
                                ref
                                    .read(tripCreationProvider.notifier)
                                    .togglePlaceSelection(place);
                              },
                            );
                          },
                        ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${selectedPlaces.length} Tempat Terpilih',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Est. Tiket/Makan: ${currencyFormatter.format(totalSelectedCost)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: selectedPlaces.isEmpty
                              ? null
                              : _handleBuildItinerary,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Susun Itinerary AI'),
                              SizedBox(width: 6),
                              Icon(Icons.auto_awesome, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

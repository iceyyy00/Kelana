import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/saved_itineraries_provider.dart';
import '../../providers/trip_creation_provider.dart';
import '../../widgets/kelana_navigation.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'Akan Datang';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _statusFor(String status) {
    if (status == 'completed') return 'Selesai';
    if (status == 'draft') return 'Draf';
    return 'Akan Datang';
  }

  void _openItinerary(dynamic itinerary) {
    ref.read(tripCreationProvider.notifier).loadItinerary(itinerary);
    context.push('/itinerary');
  }

  @override
  Widget build(BuildContext context) {
    final itineraries = ref.watch(savedItinerariesProvider);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = itineraries.where((itinerary) {
      final matchesStatus = _statusFor(itinerary.status) == _selectedStatus;
      final matchesQuery = query.isEmpty ||
          itinerary.title.toLowerCase().contains(query) ||
          itinerary.location.toLowerCase().contains(query) ||
          itinerary.summary.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.htmlBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const KelanaHeader(title: 'Trips'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  const Text(
                    'Perjalanan Anda',
                    style: TextStyle(
                        fontSize: 27,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.htmlPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Daftar seluruh rencana perjalanan yang telah disusun.',
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.htmlTextSecondary),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => context.go('/chat'),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Buat Perjalanan Baru'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.htmlPrimaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Cari destinasi atau catatan perjalanan...',
                      prefixIcon: Icon(Icons.search),
                      fillColor: Color(0xFFFDF3DE),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          ['Akan Datang', 'Draf', 'Selesai'].map((status) {
                        final selected = status == _selectedStatus;
                        final count = itineraries
                            .where((i) => _statusFor(i.status) == status)
                            .length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$status ($count)'),
                            selected: selected,
                            showCheckmark: false,
                            selectedColor: AppColors.htmlPrimaryContainer,
                            backgroundColor: AppColors.htmlSurfaceContainerHigh,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.htmlTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedStatus = status),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 52),
                      child: Column(
                        children: [
                          const Icon(Icons.luggage_outlined,
                              size: 44, color: AppColors.htmlTextTertiary),
                          const SizedBox(height: 12),
                          Text(
                            itineraries.isEmpty
                                ? 'Belum ada perjalanan tersimpan'
                                : 'Tidak ada perjalanan yang cocok',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.htmlPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                              'Mulai rencanakan perjalanan untuk mengisinya.',
                              style: TextStyle(
                                  color: AppColors.htmlTextSecondary)),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((itinerary) {
                      final imageUrl = itinerary.places.isNotEmpty
                          ? itinerary.places.first.photoUrl
                          : '';
                      final currency = NumberFormat.currency(
                          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                      final status = _statusFor(itinerary.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openItinerary(itinerary),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 176,
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (imageUrl.isNotEmpty)
                                        Image.network(imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _tripPlaceholder())
                                      else
                                        _tripPlaceholder(),
                                      const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Color(0xCC00262E)
                                              ]),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: _StatusBadge(label: status),
                                      ),
                                      Positioned(
                                        left: 14,
                                        right: 14,
                                        bottom: 12,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                itinerary.location
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFFBFEAF6),
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1)),
                                            const SizedBox(height: 3),
                                            Text(itinerary.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          _TripMetric(
                                              label: 'Estimasi Anggaran',
                                              value: currency.format(itinerary
                                                  .totalEstimatedCost)),
                                          const SizedBox(width: 12),
                                          _TripMetric(
                                              label: 'Rencana Rute',
                                              value:
                                                  '${itinerary.places.length} Destinasi'),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          const Icon(Icons.near_me_outlined,
                                              size: 17,
                                              color: AppColors
                                                  .htmlPrimaryContainer),
                                          const SizedBox(width: 6),
                                          Expanded(
                                              child: Text(
                                                  'Titik awal: ${itinerary.location}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .htmlTextSecondary))),
                                          const Text('Detail  ›',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors
                                                      .htmlPrimaryContainer)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  if (itineraries.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.htmlSurfaceContainer,
                          borderRadius: BorderRadius.circular(18)),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.swap_horiz,
                              color: AppColors.htmlPrimaryContainer),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  'Panduan Penyesuaian Jadwal\nUbah destinasi atau geser jam kunjungan saat cuaca berubah atau jalur transit terhambat.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: AppColors.htmlTextSecondary))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const KelanaBottomNavigation(currentPath: '/trips'),
          ],
        ),
      ),
    );
  }

  Widget _tripPlaceholder() => Container(
        color: AppColors.htmlSurfaceContainerHigh,
        child: const Center(
            child: Icon(Icons.landscape_outlined,
                size: 42, color: AppColors.htmlTextTertiary)),
      );
}

class _TripMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TripMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: AppColors.htmlBackground,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.htmlTextTertiary)),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.htmlPrimary)),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          color: AppColors.htmlSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.htmlPrimaryContainer)),
      ),
    );
  }
}

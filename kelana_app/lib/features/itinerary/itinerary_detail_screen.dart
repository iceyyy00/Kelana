import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_creation_provider.dart';
import '../../providers/saved_itineraries_provider.dart';
import '../../widgets/map_view_widget.dart';
import '../../widgets/itinerary_stop_card.dart';

class ItineraryDetailScreen extends ConsumerStatefulWidget {
  const ItineraryDetailScreen({super.key});

  @override
  ConsumerState<ItineraryDetailScreen> createState() =>
      _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends ConsumerState<ItineraryDetailScreen> {
  bool _isSaved = false;

  void _showShareDialog(String shareCode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.share_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Bagikan Itinerary'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kirim kode ini ke teman Anda untuk melihat itinerary ini:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      shareCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy,
                          size: 20, color: AppColors.primary),
                      tooltip: 'Salin Kode',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Kode berhasil disalin!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _handleSaveItinerary() async {
    final itin = ref.read(tripCreationProvider).builtItinerary;
    if (itin == null) return;

    await ref.read(savedItinerariesProvider.notifier).saveItinerary(itin);
    setState(() {
      _isSaved = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Itinerary berhasil disimpan ke riwayat!'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () => context.push('/saved'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripCreationProvider);
    final itinerary = tripState.builtItinerary;

    if (itinerary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinerary Detail')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Belum ada itinerary yang aktif.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Buat Sekarang'),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final shareCode = itinerary.shareCode ??
        'KLN-${itinerary.id.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rencana Perjalanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan',
            onPressed: () => _showShareDialog(shareCode),
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? AppColors.primary : null,
            ),
            tooltip: 'Simpan',
            onPressed: _handleSaveItinerary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 252,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (itinerary.places.isNotEmpty &&
                      itinerary.places.first.photoUrl.isNotEmpty)
                    Image.network(
                      itinerary.places.first.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _itineraryHeroFallback(),
                    )
                  else
                    _itineraryHeroFallback(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x2200262E), Color(0xDD00262E)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(itinerary.location,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        Text(itinerary.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 23,
                                height: 1.15,
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(
                            '${itinerary.places.length} destinasi  ·  ${itinerary.parsedIntent?.dateTime ?? 'Rencana perjalanan'}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Itinerary Title & Summary Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itinerary.summary,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.htmlTextSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/chat'),
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: const Text('Sesuaikan Rencana'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.htmlPrimaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Route Stats Cards
                  Row(
                    children: [
                      // Stops Count
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Destinasi',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${itinerary.places.length} Tempat',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Est. Travel time
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Waktu Perjalanan',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${itinerary.totalEstimatedTravelMinutes} Menit',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Est. Cost
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Biaya',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter
                                    .format(itinerary.totalEstimatedCost),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Reorder hint
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  const Text(
                    'Tahan & geser untuk mengubah urutan kunjungan:',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Reorderable list of itinerary stops
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itinerary.places.length,
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(tripCreationProvider.notifier)
                    .reorderStops(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final place = itinerary.places[index];
                return ItineraryStopCard(
                  key: ValueKey(place.placeId),
                  place: place,
                  index: index,
                  isFirst: index == 0,
                  onToggleVisited: (val) {
                    ref
                        .read(tripCreationProvider.notifier)
                        .toggleVisited(place.placeId);
                  },
                  onRemove: () {
                    ref
                        .read(tripCreationProvider.notifier)
                        .removePlaceFromItinerary(place.placeId);
                  },
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: MapViewWidget(
                places: itinerary.places,
                polylinePoints: itinerary.polylinePoints,
              ),
            ),

            const SizedBox(height: 24),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Bagikan'),
                      onPressed: () => _showShareDialog(shareCode),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(_isSaved ? Icons.check : Icons.bookmark_add),
                      label: Text(_isSaved ? 'Tersimpan' : 'Simpan Rute'),
                      onPressed: _handleSaveItinerary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _itineraryHeroFallback() => Container(
        color: AppColors.htmlPrimaryContainer,
        child: const Center(
            child: Icon(Icons.landscape_outlined,
                color: Colors.white70, size: 48)),
      );
}

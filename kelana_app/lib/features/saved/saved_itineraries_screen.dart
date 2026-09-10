import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/saved_itineraries_provider.dart';
import '../../providers/trip_creation_provider.dart';

class SavedItinerariesScreen extends ConsumerStatefulWidget {
  const SavedItinerariesScreen({super.key});

  @override
  ConsumerState<SavedItinerariesScreen> createState() =>
      _SavedItinerariesScreenState();
}

class _SavedItinerariesScreenState
    extends ConsumerState<SavedItinerariesScreen> {
  final _shareCodeInputController = TextEditingController();

  @override
  void dispose() {
    _shareCodeInputController.dispose();
    super.dispose();
  }

  void _showEnterCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Buka Itinerary Teman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan Kode Share (contoh: KLN-AB12CD):',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _shareCodeInputController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'KLN-XXXXXX',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = _shareCodeInputController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(context);
                  final client = ref.read(apiClientProvider);
                  final found = await client.getSharedItinerary(code);
                  if (found != null && mounted) {
                    ref.read(savedItinerariesProvider.notifier).saveItinerary(found);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Itinerary berhasil dimuat!')),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kode tidak ditemukan atau server offline.')),
                    );
                  }
                }
              },
              child: const Text('Buka'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedList = ref.watch(savedItinerariesProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary Tersimpan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Masukkan Kode Share',
            onPressed: _showEnterCodeDialog,
          ),
        ],
      ),
      body: savedList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Itinerary Tersimpan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buat rencana perjalanan pertama Anda dari halaman Beranda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Mulai Buat Itinerary'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: savedList.length,
              itemBuilder: (context, index) {
                final itin = savedList[index];
                final visitedCount = itin.visitedCount;
                final totalCount = itin.places.length;
                final progress = totalCount > 0 ? visitedCount / totalCount : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                itin.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: progress == 1.0
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                progress == 1.0 ? 'Selesai' : 'Aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: progress == 1.0
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        Text(
                          itin.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Progress bar for visited places
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.success,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$visitedCount/$totalCount dikunjungi',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormatter.format(itin.totalEstimatedCost),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Hapus',
                                  onPressed: () {
                                    ref
                                        .read(savedItinerariesProvider.notifier)
                                        .removeItinerary(itin.id);
                                  },
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: () {
                                    // Load into tripCreation and view
                                    ref
                                        .read(tripCreationProvider.notifier)
                                        .reset();
                                    context.push('/itinerary');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text('Buka Rute'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

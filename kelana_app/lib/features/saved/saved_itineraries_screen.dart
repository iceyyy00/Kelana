import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/saved_itineraries_provider.dart';
import '../../providers/trip_creation_provider.dart';
import '../../widgets/kelana_navigation.dart';

class SavedItinerariesScreen extends ConsumerStatefulWidget {
  const SavedItinerariesScreen({super.key});

  @override
  ConsumerState<SavedItinerariesScreen> createState() =>
      _SavedItinerariesScreenState();
}

class _SavedItinerariesScreenState
    extends ConsumerState<SavedItinerariesScreen> {
  final _shareCodeInputController = TextEditingController();
  int _selectedTab = 0;

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  final messenger = ScaffoldMessenger.of(this.context);
                  final found = await client.getSharedItinerary(code);
                  if (found != null && mounted) {
                    ref
                        .read(savedItinerariesProvider.notifier)
                        .saveItinerary(found);
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Itinerary berhasil dimuat!')),
                    );
                  } else if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Kode tidak ditemukan atau server offline.')),
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
      backgroundColor: AppColors.htmlBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const KelanaHeader(title: 'Saved'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                          child: Text('Tersimpan',
                              style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.htmlPrimary))),
                      Text('${savedList.length} item',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.htmlTextSecondary)),
                      IconButton(
                        onPressed: _showEnterCodeDialog,
                        tooltip: 'Masukkan kode share',
                        icon: const Icon(Icons.add_link_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const Text(
                      'Daftar destinasi dan rencana yang ingin Anda kunjungi.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.htmlTextSecondary)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: AppColors.htmlSurfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        _savedTab('Tempat', Icons.place_outlined, 0),
                        _savedTab('Rencana', Icons.luggage_outlined, 1),
                        _savedTab('Ide', Icons.lightbulb_outline_rounded, 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? _buildSavedPlaces(savedList)
                  : _selectedTab == 2
                      ? _buildIdeasTab()
                      : savedList.isEmpty
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: savedList.length,
                              itemBuilder: (context, index) {
                                final itin = savedList[index];
                                final visitedCount = itin.visitedCount;
                                final totalCount = itin.places.length;
                                final progress = totalCount > 0
                                    ? visitedCount / totalCount
                                    : 0.0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  elevation: 1.5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title row
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: progress == 1.0
                                                    ? AppColors.success
                                                        .withValues(alpha: 0.12)
                                                    : AppColors.primary
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                progress == 1.0
                                                    ? 'Selesai'
                                                    : 'Aktif',
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
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              currencyFormatter.format(
                                                  itin.totalEstimatedCost),
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
                                                        .read(
                                                            savedItinerariesProvider
                                                                .notifier)
                                                        .removeItinerary(
                                                            itin.id);
                                                  },
                                                ),
                                                const SizedBox(width: 4),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    ref
                                                        .read(
                                                            tripCreationProvider
                                                                .notifier)
                                                        .loadItinerary(itin);
                                                    context.push('/itinerary');
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                    textStyle: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                  child:
                                                      const Text('Buka Rute'),
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
            ),
            const KelanaBottomNavigation(currentPath: '/saved'),
          ],
        ),
      ),
    );
  }

  Widget _savedTab(String label, IconData icon, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
              color: selected ? AppColors.htmlSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(11)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected
                      ? AppColors.htmlPrimaryContainer
                      : AppColors.htmlTextSecondary),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.htmlPrimaryContainer
                          : AppColors.htmlTextSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPlaces(List<dynamic> itineraries) {
    final places = <String, dynamic>{};
    for (final itinerary in itineraries) {
      for (final place in itinerary.places) {
        places[place.placeId] = place;
      }
    }
    if (places.isEmpty) {
      return const Center(
          child: Text('Belum ada tempat tersimpan.',
              style: TextStyle(color: AppColors.htmlTextSecondary)));
    }
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: AppColors.htmlSurfaceContainerLow,
              borderRadius: BorderRadius.circular(14)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.route_outlined, color: AppColors.htmlPrimaryContainer),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Rekomendasi Berdasarkan Preferensi Anda\nTempat dari perjalanan tersimpan dikumpulkan di sini.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppColors.htmlTextSecondary))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Tempat Tersimpan  ·  ${places.length}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.htmlPrimary)),
        const SizedBox(height: 10),
        ...places.values.map((place) => Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.photoUrl.isNotEmpty)
                    Image.network(place.photoUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeImagePlaceholder())
                  else
                    _placeImagePlaceholder(),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(place.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.htmlPrimary))),
                            Text('★ ${place.rating}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(place.category,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.htmlSecondary)),
                        const SizedBox(height: 5),
                        Text(place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.htmlTextSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  ref
                                      .read(tripCreationProvider.notifier)
                                      .togglePlaceSelection(place);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '${place.name} ditambahkan ke rencana')));
                                  context.go('/chat');
                                },
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 18),
                                label: const Text('Tambah ke rencana'),
                                style: FilledButton.styleFrom(
                                    backgroundColor:
                                        AppColors.htmlPrimaryContainer,
                                    foregroundColor: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                                place.estimatedPrice == 0
                                    ? 'Gratis'
                                    : currency.format(place.estimatedPrice),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.htmlPrimaryContainer)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildIdeasTab() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 44, color: AppColors.htmlTextTertiary),
              SizedBox(height: 12),
              Text('Ide perjalanan akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.htmlTextSecondary)),
            ],
          ),
        ),
      );

  Widget _placeImagePlaceholder() => Container(
        height: 150,
        color: AppColors.htmlSurfaceContainerHigh,
        child: const Center(
            child: Icon(Icons.landscape_outlined,
                size: 38, color: AppColors.htmlTextTertiary)),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_creation_provider.dart';
import '../../models/parsed_intent.dart';

class ChatParserScreen extends ConsumerStatefulWidget {
  const ChatParserScreen({super.key});

  @override
  ConsumerState<ChatParserScreen> createState() => _ChatParserScreenState();
}

class _ChatParserScreenState extends ConsumerState<ChatParserScreen> {
  final _chatInputController = TextEditingController();

  // Local editable controllers for Intent Confirmation
  late TextEditingController _locationController;
  late TextEditingController _budgetController;
  late TextEditingController _timeController;
  int _peopleCount = 1;
  List<String> _selectedCategories = [];

  final List<String> _availableCategories = [
    'Kuliner',
    'Wisata Sejarah',
    'Wisata Alam',
    'Spot Foto & Estetik',
    'Belanja',
    'Religi & Budaya',
    'Hidden Gem',
  ];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    _budgetController = TextEditingController();
    _timeController = TextEditingController();
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _syncIntentToControllers(ParsedIntent intent) {
    if (_locationController.text != intent.location) {
      _locationController.text = intent.location;
    }
    if (_budgetController.text != intent.budget.toString()) {
      _budgetController.text = intent.budget.toString();
    }
    if (_timeController.text != intent.dateTime) {
      _timeController.text = intent.dateTime;
    }
    _peopleCount = intent.peopleCount;
    _selectedCategories = [...intent.categories];
  }

  void _confirmAndProceed() async {
    final tripNotifier = ref.read(tripCreationProvider.notifier);
    final currentIntent = ref.read(tripCreationProvider).parsedIntent;

    if (currentIntent == null) return;

    final updatedIntent = currentIntent.copyWith(
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : currentIntent.location,
      budget: int.tryParse(_budgetController.text) ?? currentIntent.budget,
      dateTime: _timeController.text.trim().isNotEmpty
          ? _timeController.text.trim()
          : currentIntent.dateTime,
      peopleCount: _peopleCount,
      categories: _selectedCategories.isNotEmpty
          ? _selectedCategories
          : currentIntent.categories,
    );

    tripNotifier.updateParsedIntent(updatedIntent);
    final success = await tripNotifier.fetchPlacesForIntent();
    if (success && mounted) {
      context.push('/recommendations');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripCreationProvider);
    final intent = tripState.parsedIntent;

    if (intent != null && _locationController.text.isEmpty) {
      _syncIntentToControllers(intent);
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Kelana (AI)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. User Chat Bubble
                  if (tripState.rawQuery.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(left: 40, bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          tripState.rawQuery,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),

                  // 2. AI Loading State
                  if (tripState.isLoading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(right: 40, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tripState.loadingMessage ?? 'Gemini sedang berpikir...',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 3. AI Error State
                  if (tripState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        tripState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                      ),
                    ),

                  // 4. Gemini Structured Output Confirmation Card
                  if (intent != null && !tripState.isLoading) ...[
                    // AI message intro bubble
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(right: 40, bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Berikut rencana yang saya tangkap dari pesan Anda. Silakan periksa atau sesuaikan sebelum mencari rekomendasi tempat:',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                      ),
                    ),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'Konfirmasi Rencana Perjalanan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Destination / Location
                            const Text('📍 Kota / Destinasi:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Semarang, Jogja...',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Budget
                            const Text('💰 Estimasi Budget (IDR):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Waktu / Durasi
                            const Text('📅 Waktu / Durasi:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _timeController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Hari ini, Akhir pekan...',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Jumlah Orang
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('👥 Jumlah Orang:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: _peopleCount > 1
                                          ? () => setState(() => _peopleCount--)
                                          : null,
                                    ),
                                    Text(
                                      '$_peopleCount orang',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => setState(() => _peopleCount++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Categories
                            const Text('🏷️ Kategori Minat:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: _availableCategories.map((cat) {
                                final isSelected = _selectedCategories.contains(cat);
                                return FilterChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary.withOpacity(0.18),
                                  checkmarkColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCategories.add(cat);
                                      } else {
                                        _selectedCategories.remove(cat);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // Confirm Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: tripState.isLoading ? null : _confirmAndProceed,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Cari Rekomendasi Tempat'),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Chat Input for refinement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    decoration: const InputDecoration(
                      hintText: 'Ketik revisi (misal: ganti ke Jogja 150rb)...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        ref.read(tripCreationProvider.notifier).submitPrompt(text);
                        _chatInputController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: () {
                    final text = _chatInputController.text.trim();
                    if (text.isNotEmpty) {
                      ref.read(tripCreationProvider.notifier).submitPrompt(text);
                      _chatInputController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

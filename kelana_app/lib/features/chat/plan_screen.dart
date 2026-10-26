import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/parsed_intent.dart';
import '../../providers/trip_creation_provider.dart';
import '../../widgets/kelana_navigation.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage([String? value]) {
    final message = (value ?? _messageController.text).trim();
    if (message.isEmpty) return;
    ref.read(tripCreationProvider.notifier).submitPrompt(message);
    _messageController.clear();
  }

  Future<void> _editIntent(ParsedIntent intent) async {
    final location = TextEditingController(text: intent.location);
    final budget = TextEditingController(text: intent.budget.toString());
    final dateTime = TextEditingController(text: intent.dateTime);
    final updated = await showDialog<ParsedIntent>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.htmlSurface,
        title: const Text('Sesuaikan parameter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Destinasi')),
            const SizedBox(height: 10),
            TextField(
                controller: budget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Budget (Rp)')),
            const SizedBox(height: 10),
            TextField(
                controller: dateTime,
                decoration:
                    const InputDecoration(labelText: 'Waktu perjalanan')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              intent.copyWith(
                location: location.text.trim().isEmpty
                    ? intent.location
                    : location.text.trim(),
                budget: int.tryParse(budget.text) ?? intent.budget,
                dateTime: dateTime.text.trim().isEmpty
                    ? intent.dateTime
                    : dateTime.text.trim(),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    location.dispose();
    budget.dispose();
    dateTime.dispose();
    if (updated != null) {
      ref.read(tripCreationProvider.notifier).updateParsedIntent(updated);
    }
  }

  Future<void> _showRecommendations() async {
    final success =
        await ref.read(tripCreationProvider.notifier).fetchPlacesForIntent();
    if (success && mounted) context.push('/recommendations');
  }

  bool _hasDestination(ParsedIntent? intent) =>
      intent != null && intent.location.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripCreationProvider);
    final intent = state.parsedIntent;

    return Scaffold(
      backgroundColor: AppColors.htmlBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const KelanaHeader(title: 'Plan'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: AppColors.htmlSurface,
                  border: Border(
                      bottom: BorderSide(
                          color: AppColors.htmlBorder.withValues(alpha: 0.6)))),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        const Icon(Icons.circle,
                            size: 8, color: AppColors.htmlSecondary),
                        const Text('Draf Aktif',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.htmlPrimaryContainer)),
                        const Text('·',
                            style:
                                TextStyle(color: AppColors.htmlTextTertiary)),
                        Text(intent?.location ?? 'Rencana baru',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.htmlPrimaryContainer)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(tripCreationProvider.notifier).reset(),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Rencana Baru'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.htmlPrimaryContainer,
                      backgroundColor: AppColors.htmlSurfaceContainer,
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  if (state.rawQuery.isNotEmpty) ...[
                    Center(
                        child: _pill(
                            'Hari ini · ${TimeOfDay.now().format(context)} WIB',
                            AppColors.htmlSurfaceContainer,
                            AppColors.htmlTextTertiary)),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(
                          color: AppColors.htmlPrimaryContainer,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(4),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18)),
                        ),
                        child: Text(state.rawQuery,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text('Terkirim',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.htmlTextTertiary))),
                    const SizedBox(height: 16),
                  ],
                  if (state.isLoading)
                    _softMessage(
                      child: Row(
                        children: [
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.htmlPrimaryContainer)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  state.loadingMessage ??
                                      'Kelana sedang menyusun rencana...',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.htmlTextSecondary))),
                        ],
                      ),
                    ),
                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFEFED),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(state.errorMessage!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.error)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (intent?.chatResponse != null &&
                      !_hasDestination(intent) &&
                      !state.isLoading) ...[
                    _softMessage(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelana',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.htmlPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            intent!.chatResponse!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.htmlPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (intent != null && !state.isLoading) ...[
                    _softMessage(
                      child: const Text(
                        'Sip! Ini detail perjalanan dan minat wisata yang aku tangkap. Sudah sesuai? Kamu bisa mengubahnya di bawah ini sebelum lanjut.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.htmlPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Text('Parameter Terdeteksi',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.htmlPrimaryContainer)),
                        Spacer(),
                        Text('Otomatis terisi',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.htmlTextTertiary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _tag(Icons.location_on_outlined, intent.location),
                        _tag(Icons.schedule_rounded, intent.dateTime),
                        _tag(Icons.payments_outlined,
                            'Rp ${_formatBudget(intent.budget)}'),
                        ...intent.categories.take(2).map((category) =>
                            _tag(Icons.interests_outlined, category)),
                        IconButton.filledTonal(
                          tooltip: 'Ubah parameter',
                          onPressed: () => _editIntent(intent),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          style: IconButton.styleFrom(
                              fixedSize: const Size(30, 30),
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.htmlSurfaceContainer),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _softMessage(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _showRecommendations,
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 17),
                              label: const Text('Cari Rekomendasi Tempat'),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    AppColors.htmlSecondaryContainer,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!state.isLoading) ...[
                    const SizedBox(height: 70),
                    const Icon(Icons.auto_awesome,
                        size: 38, color: AppColors.htmlPrimaryContainer),
                    const SizedBox(height: 14),
                    const Text('Mau merencanakan perjalanan ke mana?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.htmlPrimary)),
                    const SizedBox(height: 8),
                    const Text(
                        'Ceritakan tujuan, budget, dan suasana perjalanan yang kamu inginkan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.htmlTextSecondary)),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Weekend santai di Jogja',
                        'Kuliner 2 hari Bandung',
                        'Trip hemat Semarang',
                      ]
                          .map((prompt) => ActionChip(
                              label: Text(prompt),
                              onPressed: () => _sendMessage(prompt)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                  color: AppColors.htmlSurface,
                  border: Border(
                      top: BorderSide(
                          color:
                              AppColors.htmlBorder.withValues(alpha: 0.65)))),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () {},
                    tooltip: 'Lokasi dan preferensi',
                    icon: const Icon(Icons.add_location_alt_outlined, size: 19),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.htmlSurfaceContainer,
                        foregroundColor: AppColors.htmlTextSecondary,
                        fixedSize: const Size(42, 42)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ngobrol atau ceritakan tujuan perjalanan...',
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFFDF3DE),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isLoading ? null : () => _sendMessage(),
                    tooltip: 'Kirim pesan',
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.htmlSecondaryContainer,
                        foregroundColor: Colors.white,
                        fixedSize: const Size(42, 42)),
                  ),
                ],
              ),
            ),
            const KelanaBottomNavigation(currentPath: '/chat'),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: AppColors.htmlSurfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: AppColors.htmlBorder.withValues(alpha: 0.7))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppColors.htmlTextSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.htmlPrimaryContainer))
        ]),
      );

  Widget _pill(String text, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 10, color: foreground)),
      );

  Widget _softMessage({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.htmlSurfaceContainerLow,
            border: Border.all(color: AppColors.htmlBorder),
            borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  String _formatBudget(int budget) => budget
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

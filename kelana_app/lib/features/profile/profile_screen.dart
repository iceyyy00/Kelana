import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_creation_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _urlController;
  bool _isCheckingHealth = false;
  String? _healthResult;

  final List<String> _categories = [
    'Kuliner',
    'Wisata Sejarah',
    'Wisata Alam',
    'Spot Foto & Estetik',
    'Belanja',
    'Religi & Budaya',
  ];

  final Set<String> _favoriteCategories = {'Kuliner', 'Wisata Sejarah'};
  int _avgBudget = 150000;

  @override
  void initState() {
    super.initState();
    final client = ref.read(apiClientProvider);
    _urlController = TextEditingController(text: client.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _checkBackendHealth() async {
    setState(() {
      _isCheckingHealth = true;
      _healthResult = null;
    });

    final client = ref.read(apiClientProvider);
    client.updateBaseUrl(_urlController.text.trim());
    final isHealthy = await client.checkHealth();

    setState(() {
      _isCheckingHealth = false;
      _healthResult = isHealthy
          ? 'Backend terhubung & aktif! ✅'
          : 'Gagal terhubung ke server backend ❌';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (user?.name ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Petualang Kelana',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'user@kelana.app',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Travel Preferences
            const Text(
              'Preferensi Perjalanan 🧭',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Preferensi ini membantu Gemini menyesuaikan rekomendasi untuk Anda.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _favoriteCategories.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.18),
                  checkmarkColor: AppColors.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _favoriteCategories.add(cat);
                      } else {
                        _favoriteCategories.remove(cat);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Average Budget Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rata-rata Budget Perjalanan:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  currencyFormatter.format(_avgBudget),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _avgBudget.toDouble(),
              min: 50000,
              max: 2000000,
              divisions: 39,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _avgBudget = val.toInt();
                });
              },
            ),

            const SizedBox(height: 24),

            // Backend Proxy URL Settings
            const Text(
              'Konfigurasi Backend Proxy ⚙️',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'URL Server Backend (ubah jika menggunakan IP Wi-Fi untuk device fisik):',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.link),
                hintText: 'http://localhost:5000/api',
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isCheckingHealth
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: const Text('Tes Koneksi Server'),
                    onPressed: _isCheckingHealth ? null : _checkBackendHealth,
                  ),
                ),
              ],
            ),

            if (_healthResult != null) ...[
              const SizedBox(height: 8),
              Text(
                _healthResult!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _healthResult!.contains('✅')
                      ? AppColors.success
                      : Colors.redAccent,
                ),
              ),
            ],

            const SizedBox(height: 36),

            // Logout Button
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go('/login');
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_passwordController.text.length < 8) {
      _showMessage('Kata sandi minimal 8 karakter.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Konfirmasi kata sandi belum cocok.');
      return;
    }
    if (!_acceptedTerms) {
      _showMessage('Setujui syarat dan ketentuan terlebih dahulu.');
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) context.go('/home');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final passwordLength = _passwordController.text.length;
    final strength = passwordLength == 0
        ? 0
        : passwordLength < 8
            ? 1
            : passwordLength < 10
                ? 2
                : passwordLength < 12
                    ? 3
                    : 4;
    final strengthLabel = passwordLength == 0
        ? 'Belum terisi'
        : strength == 1
            ? 'Lemah'
            : strength < 4
                ? 'Cukup'
                : 'Kuat';

    return Scaffold(
      backgroundColor: AppColors.htmlBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.htmlSurfaceContainer,
                        ),
                      ),
                      const Spacer(),
                      Image.asset(
                        'assets/icons/logoonly2.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Text(
                          'K',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.htmlPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kelana',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.htmlPrimary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.htmlSurfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Langkah Awal  •  Pendaftaran Akun',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.htmlTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mulai Perjalanan Anda',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.htmlPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buat akun Kelana untuk menyusun dan menyimpan jadwal perjalanan dengan mudah.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.htmlTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (auth.errorMessage != null) ...[
                    _ErrorBanner(message: auth.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  const _FieldLabel('Nama Lengkap'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'contoh: Maya Indah',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Email'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'contoh: maya@kelana.id',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Kata Sandi'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Masukkan kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: List.generate(4, (index) {
                      const colors = [
                        AppColors.error,
                        AppColors.warning,
                        AppColors.warning,
                        AppColors.success,
                      ];
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                          decoration: BoxDecoration(
                            color: index < strength
                                ? colors[strength - 1]
                                : AppColors.htmlBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gunakan minimal 8 karakter',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.htmlTextTertiary,
                        ),
                      ),
                      Text(
                        strengthLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.htmlTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Konfirmasi Kata Sandi'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      hintText: 'Ulangi kata sandi',
                      prefixIcon: const Icon(Icons.lock_clock_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _acceptedTerms,
                    onChanged: (value) =>
                        setState(() => _acceptedTerms = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.htmlTextSecondary,
                      ),
                    ),
                    activeColor: AppColors.htmlPrimaryContainer,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.htmlPrimaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Buat Akun',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _OrDivider(),
                  const SizedBox(height: 16),
                  _SocialButton(
                    label: 'Daftar dengan Google',
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    onPressed: () =>
                        _showMessage('Login Google belum dikonfigurasi.'),
                  ),
                  const SizedBox(height: 10),
                  _SocialButton(
                    label: 'Daftar dengan Apple',
                    icon: const Icon(Icons.apple, size: 23),
                    onPressed: () =>
                        _showMessage('Login Apple belum dikonfigurasi.'),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: AppColors.htmlTextSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: AppColors.htmlPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.htmlTextSecondary,
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.error, fontSize: 13),
        ),
      );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(child: Divider(color: AppColors.htmlBorder)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'ATAU',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.htmlTextTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.htmlBorder)),
        ],
      );
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: Text(label),
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.htmlSurface,
            foregroundColor: AppColors.htmlPrimary,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}

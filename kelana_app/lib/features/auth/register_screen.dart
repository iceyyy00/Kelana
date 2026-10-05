import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi tidak cocok'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9),
      body: Stack(
        children: [
          // 1. Atmospheric Panoramic Travel Background (Mount Bromo / Mist sunrise aesthetic)
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=1200&auto=format&fit=crop&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF134E4A),
                      Color(0xFF0F766E),
                      Color(0xFFFAFAF9),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Warm gradient scrim and backdrop blur
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99134E4A), // deep teal scrim top
                    Color(0xB3FAFAF9), // middle
                    Color(0xF5FAFAF9), // bottom solid
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. Scrollable Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Top Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => context.go('/login'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Color(0xFF134E4A),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Central Glassmorphism Register Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF134E4A).withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Section: Logo Badge & Welcome Heading
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/icons/logoonly2.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.explore_rounded,
                                      color: Color(0xFF0F766E),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE8E1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 13,
                                      color: Color(0xFFC2410C),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'AI ITINERARY PLANNER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: Color(0xFFC2410C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Buat Akun Baru',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF134E4A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Mulai susun itinerary cerdasmu dengan sentuhan rasa lokal dan kurasi AI.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Error notification if present
                        if (auth.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Field 1: Nama Lengkap / Username
                        const Text(
                          'Nama Lengkap / Username',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF134E4A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildInputField(
                          controller: _usernameController,
                          hintText: 'e.g. Raden Kelana',
                          icon: Icons.person_outline,
                        ),

                        const SizedBox(height: 14),

                        // Field 2: Alamat Email
                        const Text(
                          'Alamat Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF134E4A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildInputField(
                          controller: _emailController,
                          hintText: 'nama@email.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          showClear: true,
                        ),

                        const SizedBox(height: 14),

                        // Field 3: Kata Sandi
                        const Text(
                          'Kata Sandi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF134E4A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildInputField(
                          controller: _passwordController,
                          hintText: '•••••••••',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF94A3B8),
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Field 4: Konfirmasi Kata Sandi
                        const Text(
                          'Konfirmasi Kata Sandi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF134E4A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildInputField(
                          controller: _confirmPasswordController,
                          hintText: '•••••••••',
                          icon: Icons.lock_reset,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF94A3B8),
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Info hint
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Minimal 8 karakter kombinasi huruf & angka',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Primary Register Button
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Daftar Sekarang',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Clean Divider
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'atau daftar dengan',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0))),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Google Auth Button
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.04),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGoogleLogo(),
                              const SizedBox(width: 10),
                              const Text(
                                'Daftar dengan Google',
                                style: TextStyle(
                                  color: Color(0xFF134E4A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Terms notice
                        const Text(
                          'Dengan mendaftar, Anda menyetujui Ketentuan Layanan dan Kebijakan Privasi Kelana.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bottom Switcher Link
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Masuk',
                                style: TextStyle(
                                  color: Color(0xFFC2410C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Color(0xFFC2410C),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool showClear = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 19),
          suffixIcon: suffixIcon ??
              (showClear && controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel,
                          color: Color(0xFF94A3B8), size: 18),
                      onPressed: () {
                        setState(() {
                          controller.clear();
                        });
                      },
                    )
                  : null),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        ),
        onChanged: showClear ? (_) => setState(() {}) : null,
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 18,
          fontFamily: 'sans-serif',
        ),
      ),
    );
  }
}

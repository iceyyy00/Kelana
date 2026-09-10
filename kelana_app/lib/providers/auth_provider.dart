import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserProfile? user;
  final String? errorMessage;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkSavedSession();
  }

  Future<void> checkSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userName = prefs.getString('user_name') ?? 'Petualang Kelana';
      final userEmail = prefs.getString('user_email') ?? 'user@kelana.app';

      if (isLoggedIn) {
        state = state.copyWith(
          isAuthenticated: true,
          user: UserProfile(
            userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
            name: userName,
            email: userEmail,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.isNotEmpty && password.length >= 6) {
      final user = UserProfile(
        userId: 'usr_${email.hashCode}',
        name: email.split('@').first,
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email atau password tidak valid (min. 6 karakter).',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      final user = UserProfile(
        userId: 'usr_${email.hashCode}',
        name: name,
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lengkapi semua data dengan benar.',
      );
      return false;
    }
  }

  Future<void> loginAsGuest() async {
    final user = UserProfile(
      userId: 'guest_user',
      name: 'Tamu Kelana',
      email: 'guest@kelana.app',
      createdAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(isAuthenticated: true, user: user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

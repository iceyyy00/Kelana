import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    bool clearUser = false,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() : super(AuthState()) {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        state = state.copyWith(isAuthenticated: false, clearUser: true);
        return;
      }

      final profile = UserProfile(
        userId: user.uid,
        name: user.isAnonymous
            ? 'Tamu Kelana'
            : user.displayName ?? user.email?.split('@').first ?? 'Kelana User',
        email: user.email ??
            (user.isAnonymous ? 'guest@kelana.app' : 'user@kelana.app'),
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        isAuthenticated: true,
        user: profile,
      );
    });
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login gagal. Coba lagi.',
        );
        return false;
      }

      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Email atau password tidak valid.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan saat login.',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
      }

      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Registrasi gagal.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan saat mendaftar.',
      );
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _auth.signInAnonymously();
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal masuk sebagai tamu. Coba lagi.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: UserProfile(
          userId: firebaseUser.uid,
          name: 'Tamu Kelana',
          email: 'guest@kelana.app',
          createdAt: firebaseUser.metadata.creationTime?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Gagal masuk sebagai tamu.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan saat masuk sebagai tamu.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

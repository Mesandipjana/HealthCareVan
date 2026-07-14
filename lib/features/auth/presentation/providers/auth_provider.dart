import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import '../../../../core/services/firebase_data_service.dart';

// Auth State
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await FirebaseDataService.currentProfile();
      state = AuthState(user: user);
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await FirebaseDataService.signInWithEmail(email, password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await FirebaseDataService.signInWithGoogle();
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> signInWithDemoAccount(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user =
          await FirebaseDataService.signInWithDemoAccount(email, password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
    required String role,
    required String designation,
    required String phone,
    String? unitId,
    required String district,
    required String userState,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await FirebaseDataService.createUserWithEmail(
        name: name,
        email: email,
        password: password,
        role: role,
        designation: designation,
        phone: phone,
        unitId: unitId,
        district: district,
        state: userState,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseDataService.signOut();
    state = const AuthState();
  }

  Future<bool> updateProfile({
    required String name,
    required String designation,
    required String phone,
    String? unitId,
    required String district,
    required String userState,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await FirebaseDataService.updateCurrentProfile(
        name: name,
        designation: designation,
        phone: phone,
        unitId: unitId,
        district: district,
        state: userState,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

String _authErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Firebase took too long to respond. Check that Authentication and Firestore are enabled for this project.';
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'This sign-in method is disabled in Firebase Authentication.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'cancelled':
        return 'Google sign-in was cancelled before it finished.';
      case 'unauthorized-domain':
        return 'This web address is not authorized for Firebase Auth. Add localhost/127.0.0.1 in Firebase Authentication settings.';
      case 'email-already-in-use':
        return 'This email already exists in Firebase with a different sign-in method.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Invalid email or password.';
      default:
        return error.message ?? 'Firebase sign-in failed (${error.code}).';
    }
  }
  if (kDebugMode) {
    return 'Sign-in failed: ${error.runtimeType} - $error';
  }
  return 'Sign-in failed. Check your Firebase Authentication setup.';
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final usersProvider = FutureProvider<List<AppUser>>((ref) {
  return FirebaseDataService.getUsers();
});

final officersProvider = FutureProvider<List<AppUser>>((ref) async {
  final users = await ref.watch(usersProvider.future);
  return users.where((user) => user.isOfficer && user.isActive).toList();
});

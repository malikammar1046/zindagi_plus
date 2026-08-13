import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthState, AuthChangeEvent;
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/interfaces/auth_repository.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

/// Holds the currently authenticated [User], or `null` when logged out.
class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier({AuthRepository? authRepository})
      : _authRepo = authRepository,
        super(null) {
    _init();
  }

  final AuthRepository? _authRepo;
  StreamSubscription<AuthState>? _authSub;

  void _init() {
    restoreSession();
    _authSub = _authRepo?.authStateChanges?.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.passwordRecovery ||
          event == AuthChangeEvent.initialSession) {
        restoreSession();
      } else if (event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });
  }

  /// Restores the existing Supabase session by fetching the current user.
  Future<void> restoreSession() async {
    if (_authRepo == null) return;
    final result = await _authRepo.getCurrentUser();
    if (result is Success<User>) {
      state = result.data;
    } else {
      state = null;
    }
  }

  /// Stores [user] after a successful login / registration.
  void setUser(User user) => state = user;

  /// Signs out the user via [AuthRepository] and clears local session state.
  Future<void> logout() async {
    try {
      await _authRepo?.logout();
    } catch (e) {
      debugPrint('[AuthNotifier.logout] Error: $e');
    }
    state = null;
  }

  /// Updates the current user's profile fields and notifies listeners.
  void updateProfile(User updated) {
    state = updated;
  }

  /// Persists onboarding questionnaire answers to Supabase/backend,
  /// marks onboarding as complete, and updates the local user state.
  Future<Result<User>> completeOnboarding(User completedUser) async {
    if (_authRepo == null) {
      final user = completedUser.copyWith(isOnboardingCompleted: true);
      state = user;
      return Success(user);
    }

    final result = await _authRepo.completeOnboarding(completedUser);
    if (result is Success<User>) {
      state = result.data;
    }
    return result;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

/// Global auth state provider.
///
/// - `null`  → user is not authenticated.
/// - `User`  → user is authenticated.
///
/// GoRouter's [refreshListenable] reacts to changes on this provider.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, User?>(
  (ref) {
    final repo = ref.watch(authRepositoryProvider);
    return AuthNotifier(authRepository: repo);
  },
);

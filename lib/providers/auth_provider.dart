import 'dart:async';
import 'dart:io';
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
    debugPrint('[AUTH-01] AuthNotifier._init()');
    restoreSession();
    _authSub = _authRepo?.authStateChanges?.listen((authState) {
      final event = authState.event;
      debugPrint('[AUTH-02] AuthChangeEvent: $event');
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.passwordRecovery ||
          event == AuthChangeEvent.initialSession) {
        restoreSession();
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('[AUTH-03] User signed out, state = null');
        state = null;
      }
    });
  }

  /// Restores the existing Supabase session by fetching the current user.
  Future<void> restoreSession() async {
    if (_authRepo == null) {
      debugPrint('[AUTH-04] restoreSession: _authRepo is null');
      return;
    }
    final sw = Stopwatch()..start();
    debugPrint('[TRACE] restoreSession START');
    final result = await _authRepo.getCurrentUser();
    sw.stop();
    debugPrint('[TRACE] restoreSession END duration=${sw.elapsedMilliseconds}ms');

    if (result is Success<User>) {
      debugPrint('[AUTH-06] restoreSession: Success user=${result.data.name} onboarded=${result.data.isOnboardingCompleted}');
      state = result.data;
    } else {
      debugPrint('[AUTH-07] restoreSession: No session or failure: ${(result as Failure).message}');
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

  /// Permanently deletes the user's account via [AuthRepository] and clears local state on success.
  Future<Result<void>> deleteAccount() async {
    if (_authRepo == null) {
      state = null;
      return const Success(null);
    }

    final result = await _authRepo.deleteAccount();
    if (result is Success<void>) {
      state = null;
    }
    return result;
  }

  /// Persists updated profile to Supabase and refreshes local auth state.
  ///
  /// Returns [Success<User>] on success, or [Failure] with a user-facing
  /// message on error. The caller should display the error message to the user.
  Future<Result<User>> updateProfile(User updated) async {
    if (_authRepo == null) {
      // Fallback for mock/test: optimistic local update.
      state = updated;
      return Success(updated);
    }

    final result = await _authRepo.updateProfile(updated);
    switch (result) {
      case Success(data: final freshUser):
        state = freshUser;
        return Success(freshUser);
      case Failure(message: final msg):
        debugPrint('[AuthNotifier.updateProfile] Failed: $msg');
        return Failure(msg);
    }
  }

  /// Uploads a profile image for the authenticated user and refreshes local auth state.
  Future<Result<User>> uploadProfilePhoto(File imageFile) async {
    if (_authRepo == null) {
      if (state != null) {
        final updated = state!.copyWith(photoUrl: imageFile.path);
        state = updated;
        return Success(updated);
      }
      return const Failure('No user session.');
    }

    final result = await _authRepo.uploadProfilePhoto(imageFile);
    switch (result) {
      case Success(data: final freshUser):
        state = freshUser;
        return Success(freshUser);
      case Failure(message: final msg):
        debugPrint('[AuthNotifier.uploadProfilePhoto] Failed: $msg');
        return Failure(msg);
    }
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

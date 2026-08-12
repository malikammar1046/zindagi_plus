import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/data/models/user.dart';

/// Holds the currently authenticated [User], or `null` when logged out.
class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null);

  /// Stores [user] after a successful login / registration.
  void setUser(User user) => state = user;

  /// Clears the session — triggers redirect to `/login` via GoRouter.
  void logout() => state = null;

  /// Updates the current user's profile fields and notifies listeners.
  void updateProfile(User updated) {
    state = updated;
  }

  /// Marks onboarding as complete, updating the user profile and triggering
  /// router re-evaluation to navigate into the main app shell.
  void completeOnboarding(User completedUser) {
    state = completedUser.copyWith(isOnboardingCompleted: true);
  }
}

/// Global auth state.
///
/// - `null`  → user is not authenticated.
/// - `User`  → user is authenticated.
///
/// GoRouter's [refreshListenable] reacts to changes on this provider.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, User?>(
  (ref) => AuthNotifier(),
);

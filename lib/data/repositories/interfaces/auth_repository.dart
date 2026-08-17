import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, OtpType;
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';

/// Contract that every authentication repository must fulfil.
///
/// Swap implementations (mock ↔ API) via the Riverpod provider in
/// `lib/providers/repository_providers.dart` without touching business logic.
abstract class AuthRepository {
  /// Authenticates a user with the given [email] and [password].
  ///
  /// Returns [Success<User>] on valid credentials,
  /// or [Failure<User>] with an error message otherwise.
  Future<Result<User>> login(String email, String password);

  /// Registers a new user account.
  ///
  /// Returns [Success<User>] on success,
  /// or [Failure<User>] with an error message on failure.
  Future<Result<User>> register(String name, String email, String password);

  /// Fetches the currently authenticated user's profile.
  ///
  /// Returns [Success<User>] if a session exists,
  /// or [Failure<User>] if the user is not authenticated.
  Future<Result<User>> getCurrentUser();

  /// Signs out the currently authenticated user session.
  Future<Result<void>> logout();

  /// Sends a password recovery email to [email].
  Future<Result<void>> resetPasswordForEmail(String email);

  /// Updates the password for the current user.
  Future<Result<void>> updatePassword(String newPassword);

  /// Resends a signup verification code/email to [email].
  Future<Result<void>> resendVerificationEmail(String email);

  /// Verifies an OTP code for signup or recovery.
  Future<Result<User>> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  });

  /// Persists onboarding questionnaire answers and marks onboarding completed.
  Future<Result<User>> completeOnboarding(User user);

  /// Persists profile edits (demographics, body metrics, goals, conditions,
  /// allergies) for the authenticated user.
  ///
  /// Writes to `public.profiles`, `public.user_goals`, `public.user_conditions`,
  /// and `public.user_allergies`. Does NOT change `is_onboarding_completed`.
  /// Returns the refreshed [User] on success.
  Future<Result<User>> updateProfile(User user);

  /// Stream of Supabase auth state change events.
  Stream<AuthState>? get authStateChanges;
}

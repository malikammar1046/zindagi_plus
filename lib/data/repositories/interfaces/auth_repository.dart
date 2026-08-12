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
}

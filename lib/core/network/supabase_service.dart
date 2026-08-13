import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized service for accessing the Supabase client and auth instances.
class SupabaseService {
  SupabaseService._();

  /// Returns `true` if Supabase has been successfully initialized.
  static bool get isInitialized {
    try {
      final _ = Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gets the initialized [SupabaseClient] singleton.
  static SupabaseClient get client => Supabase.instance.client;

  /// Gets the [GoTrueClient] if initialized, otherwise returns `null`.
  static GoTrueClient? get authOrNull => isInitialized ? Supabase.instance.client.auth : null;

  /// Gets the [GoTrueClient] for authentication operations.
  static GoTrueClient get auth => Supabase.instance.client.auth;
}

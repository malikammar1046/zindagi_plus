import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns `true` if [Supabase.instance] has been initialized.
bool get isSupabaseInitialized {
  try {
    final _ = Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

/// Provides the centralized [SupabaseClient] instance for repositories and services.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the centralized [GoTrueClient] for authentication operations.
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});


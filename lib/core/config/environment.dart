import 'package:flutter/foundation.dart';

/// Defines the build flavor / environment of the app.
enum Flavor { mock, dev, prod }

/// Centralised environment configuration.
class Environment {
  Environment._();

  /// The active flavor.
  ///
  /// Change using:
  /// --dart-define=FLAVOR=dev
  static Flavor get currentFlavor {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'mock');

    switch (flavor.toLowerCase()) {
      case 'dev':
        return Flavor.dev;
      case 'prod':
        return Flavor.prod;
      case 'mock':
      default:
        return Flavor.mock;
    }
  }

  static bool get isMock => currentFlavor == Flavor.mock;

  static String get baseUrl {
    switch (currentFlavor) {
      case Flavor.mock:
        return '';

      case Flavor.dev:
        return 'http://127.0.0.1:8000/api/v1';

      case Flavor.prod:
        return 'https://api.zindagiplus.com/api/v1';
    }
  }

  /// Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nqoqhwvgkkktoenlbogb.supabase.co',
  );

  /// Supabase publishable key.
  ///
  /// This is safe to include in a Flutter application.
  /// Database security must be enforced through RLS.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_VJOioNgmO_-onnCCF0__kw_P_W3j3Z5',
    ),
  );

  /// Deep-link redirect URL used for Supabase Auth confirmation & password reset.
  ///
  /// Defaults to `io.supabase.zindagiplus://login-callback/` on mobile devices,
  /// or web origin if running in a web browser.
  static String get authCallbackUrl {
    const fromEnv = String.fromEnvironment('AUTH_CALLBACK_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'io.supabase.zindagiplus://login-callback/';
  }

  /// Whether Supabase is configured with a valid non-empty URL and key.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}

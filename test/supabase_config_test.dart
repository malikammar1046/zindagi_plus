import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zindagi_plus/core/config/environment.dart';
import 'package:zindagi_plus/core/network/supabase_service.dart';
import 'package:zindagi_plus/providers/supabase_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Environment Supabase configuration', () {
    test('Supabase URL, key, and auth callback URL are configured by default', () {
      expect(Environment.supabaseUrl, isNotEmpty);
      expect(Environment.supabasePublishableKey, isNotEmpty);
      expect(Environment.authCallbackUrl, 'io.supabase.zindagiplus://login-callback/');
      expect(Environment.isSupabaseConfigured, isTrue);
    });

    test('Supabase URL points to valid endpoint', () {
      expect(Environment.supabaseUrl, contains('.supabase.co'));
    });
  });

  group('Supabase Client Infrastructure', () {
    test('Supabase.initialize initializes client successfully', () async {
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        publishableKey: Environment.supabasePublishableKey,
      );

      expect(Supabase.instance.client, isNotNull);
      expect(SupabaseService.client, equals(Supabase.instance.client));
      expect(SupabaseService.auth, equals(Supabase.instance.client.auth));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(supabaseClientProvider);
      final auth = container.read(supabaseAuthProvider);

      expect(client, equals(Supabase.instance.client));
      expect(auth, equals(Supabase.instance.client.auth));
    });
  });
}

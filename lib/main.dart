import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zindagi_plus/core/config/environment.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/routes/app_router.dart';
import 'package:zindagi_plus/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Environment.isSupabaseConfigured) {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      publishableKey: Environment.supabasePublishableKey,
    );
  }

  // Initialize local medication notifications
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  runApp(const ProviderScope(child: ZindagiApp()));
}

/// Root widget. Consumes [goRouterProvider] and observes app lifecycle to
/// reconcile missed doses when resuming from background.
class ZindagiApp extends ConsumerStatefulWidget {
  const ZindagiApp({super.key});

  @override
  ConsumerState<ZindagiApp> createState() => _ZindagiAppState();
}

class _ZindagiAppState extends ConsumerState<ZindagiApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for notification taps to route user to the medication screen
    _notificationSub = NotificationService.instance.onNotificationTap.listen((
      medId,
    ) {
      debugPrint(
        '[ZindagiApp] Handling notification tap for medication: $medId',
      );
      final router = ref.read(goRouterProvider);
      router.push('/medications');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[ZindagiApp] App resumed — reconciling missed doses...');
      ref.read(medicationProvider.notifier).reconcileMissedDoses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Zindagi+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

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
  debugPrint('[STARTUP-01] main() entered');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[STARTUP-02] WidgetsFlutterBinding initialized');

  if (Environment.isSupabaseConfigured) {
    debugPrint('[STARTUP-03] Initializing Supabase...');
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      publishableKey: Environment.supabasePublishableKey,
    );
    debugPrint('[STARTUP-04] Supabase initialized');
  }

  debugPrint('[STARTUP-05] Calling runApp()');
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
    debugPrint('[STARTUP-APP-01] ZindagiApp initState()');
    WidgetsBinding.instance.addObserver(this);

    // Initialize local notification service safely after first frame paint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.initialize().then((_) {
        debugPrint('[STARTUP-NOTIF] NotificationService initialized post-frame');
      });
    });

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
      debugPrint('[LIFECYCLE-RESUME] App resumed — reconciling missed doses (throttled & async)...');
      Future.microtask(() {
        ref.read(medicationProvider.notifier).reconcileMissedDoses();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[STARTUP-APP-02] ZindagiApp build()');
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Zindagi+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

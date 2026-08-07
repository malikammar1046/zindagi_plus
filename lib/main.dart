import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/routes/app_router.dart';

void main() {
  runApp(
    const ProviderScope(child: ZindagiApp()),
  );
}

/// Root widget. Consumes [goRouterProvider] so that [MaterialApp.router]
/// is always synchronised with the Riverpod container.
class ZindagiApp extends ConsumerWidget {
  const ZindagiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Zindagi+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

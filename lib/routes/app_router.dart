import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/features/auth/screens/login_screen.dart';
import 'package:zindagi_plus/features/auth/screens/register_screen.dart';
import 'package:zindagi_plus/features/dashboard/screens/dashboard_screen.dart';
import 'package:zindagi_plus/features/profile/screens/profile_screen.dart';
import 'package:zindagi_plus/features/recommendations/screens/meal_screen.dart';
import 'package:zindagi_plus/features/reports/screens/report_detail_screen.dart';
import 'package:zindagi_plus/features/reports/screens/upload_screen.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/shared/widgets/app_shell.dart';

/// Listens to [authNotifierProvider] and notifies [GoRouter] to re-evaluate
/// its redirect logic whenever the authentication state changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Tie this notifier's lifetime to the goRouterProvider's lifetime.
    _ref.listen<User?>(authNotifierProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  /// Called by GoRouter on every navigation event.
  ///
  /// - Not authenticated + navigating to a protected route → `/login`
  /// - Authenticated + navigating to an auth route → `/dashboard`
  String? redirect(BuildContext context, GoRouterState routerState) {
    final isLoggedIn = _ref.read(authNotifierProvider) != null;
    final loc = routerState.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/dashboard';
    return null;
  }
}

/// Singleton GoRouter wired to Riverpod auth state.
///
/// To navigate programmatically outside of a widget, call
/// `ref.read(goRouterProvider).go('/route')`.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Unauthenticated routes ──────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),

      // ── Authenticated shell (bottom nav) ────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          // Tab 0 — Home / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1 — Upload
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/upload',
                builder: (_, _) => const UploadScreen(),
                routes: [
                  GoRoute(
                    path: 'result',
                    builder: (_, _) => const ReportDetailScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2 — Meals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meals',
                builder: (_, _) => const MealScreen(),
              ),
            ],
          ),

          // Tab 3 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/features/auth/screens/login_screen.dart';
import 'package:zindagi_plus/features/auth/screens/register_screen.dart';
import 'package:zindagi_plus/features/chat/screens/chat_screen.dart';
import 'package:zindagi_plus/features/dashboard/screens/dashboard_screen.dart';
import 'package:zindagi_plus/features/dashboard/screens/score_breakdown_screen.dart';
import 'package:zindagi_plus/features/medications/screens/medication_list_screen.dart';
import 'package:zindagi_plus/features/profile/screens/profile_edit_screen.dart';
import 'package:zindagi_plus/features/profile/screens/profile_screen.dart';
import 'package:zindagi_plus/features/recommendations/screens/activity_screen.dart';
import 'package:zindagi_plus/features/recommendations/screens/meal_detail_screen.dart';
import 'package:zindagi_plus/features/recommendations/screens/meal_screen.dart';
import 'package:zindagi_plus/features/recommendations/screens/recommendation_detail_screen.dart';
import 'package:zindagi_plus/features/reports/screens/report_detail_screen.dart';
import 'package:zindagi_plus/features/reports/screens/report_processing_screen.dart';
import 'package:zindagi_plus/features/reports/screens/upload_screen.dart';
import 'package:zindagi_plus/features/settings/screens/settings_screen.dart';
import 'package:zindagi_plus/features/timeline/screens/health_timeline_screen.dart';
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
/// Shell tabs: Home · Upload · Meals · Chat · Profile
/// Push routes (no shell): /score-breakdown, /activities, /medications,
///                         /timeline, /recommendation/:id
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Unauthenticated routes ────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),

      // ── Push routes (full-screen, no bottom nav) ──────────────────────────
      GoRoute(
        path: '/score-breakdown',
        builder: (_, _) => const ScoreBreakdownScreen(),
      ),
      GoRoute(
        path: '/activities',
        builder: (_, _) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/medications',
        builder: (_, _) => const MedicationListScreen(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (_, _) => const HealthTimelineScreen(),
      ),
      GoRoute(
        path: '/recommendation/:id',
        builder: (_, state) => RecommendationDetailScreen(
          id: state.pathParameters['id'] ?? '1',
        ),
      ),

      // ── Authenticated shell (bottom nav) ──────────────────────────────────
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

          // Tab 1 — Upload → Processing → Result
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/upload',
                builder: (_, _) => const UploadScreen(),
                routes: [
                  GoRoute(
                    path: 'processing',
                    builder: (_, state) => ReportProcessingScreen(
                      fileName: state.extra is String
                          ? state.extra as String
                          : 'lab_report.jpg',
                    ),
                  ),
                  GoRoute(
                    path: 'result',
                    builder: (_, _) => const ReportDetailScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2 — Meals + detail
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meals',
                builder: (_, _) => const MealScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => MealDetailScreen(
                      mealIndex: int.tryParse(
                            state.pathParameters['id'] ?? '0',
                          ) ??
                          0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 3 — AI Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (_, _) => const ChatScreen(),
              ),
            ],
          ),

          // Tab 4 — Profile + edit + settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, _) => const ProfileEditScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/routes/app_router.dart';

void main() {
  group('Router Authentication and Session Guards', () {
    testWidgets('Unauthenticated user is redirected to /login',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepositoryMock()),
          authNotifierProvider.overrideWith((ref) => AuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Attempt to navigate to protected dashboard route
      router.go('/dashboard');
      await tester.pumpAndSettle();

      // Should be redirected to login
      expect(router.state.matchedLocation, '/login');
    });

    testWidgets('Authenticated un-onboarded user is redirected to /onboarding/setup',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepositoryMock()),
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-u1',
              name: 'Pending Setup User',
              email: 'pending@test.com',
              isOnboardingCompleted: false,
            ));
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Attempt to navigate to dashboard
      router.go('/dashboard');
      await tester.pumpAndSettle();

      // Guard redirects to /onboarding/setup
      expect(router.state.matchedLocation, '/onboarding/setup');
    });

    testWidgets('Authenticated fully-onboarded user navigating to /login is redirected to /dashboard',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepositoryMock()),
          medicationProvider.overrideWith(
            (ref) => MedicationNotifier(ref, autoInit: false)
              ..state = const AsyncValue.data([]),
          ),
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-u2',
              name: 'Completed User',
              email: 'complete@test.com',
              isOnboardingCompleted: true,
            ));
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Attempt to navigate to login screen
      router.go('/login');
      await tester.pumpAndSettle();

      // Guard redirects to dashboard
      expect(router.state.matchedLocation, '/dashboard');
    });

    testWidgets('Unauthenticated user can access /email-verification',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepositoryMock()),
          authNotifierProvider.overrideWith((ref) => AuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/email-verification');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/email-verification');
    });

    testWidgets('Authenticated un-onboarded user on /email-verification is redirected to /onboarding/setup',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepositoryMock()),
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-u3',
              name: 'Pending User',
              email: 'pending@test.com',
              isOnboardingCompleted: false,
            ));
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/email-verification');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/onboarding/setup');
    });

    testWidgets('Authenticated fully-onboarded user on /email-verification is redirected to /dashboard',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepositoryMock()),
          medicationProvider.overrideWith(
            (ref) => MedicationNotifier(ref, autoInit: false)
              ..state = const AsyncValue.data([]),
          ),
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-u4',
              name: 'Onboarded User',
              email: 'onboarded@test.com',
              isOnboardingCompleted: true,
            ));
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/email-verification');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/dashboard');
    });

    testWidgets('Startup with restored completed session routes to /dashboard',
        (WidgetTester tester) async {
      final mockRepo = AuthRepositoryMock();
      await mockRepo.login('test@test.com', 'password'); // Fully onboarded user

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          medicationProvider.overrideWith(
            (ref) => MedicationNotifier(ref, autoInit: false)
              ..state = const AsyncValue.data([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial session restore
      await container.read(authNotifierProvider.notifier).restoreSession();

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/splash');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/dashboard');
    });

    testWidgets('Startup with restored incomplete session routes to /onboarding/setup',
        (WidgetTester tester) async {
      final mockRepo = AuthRepositoryMock();
      await mockRepo.register('New User', 'new@test.com', 'pass123'); // Un-onboarded user

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          medicationProvider.overrideWith(
            (ref) => MedicationNotifier(ref, autoInit: false)
              ..state = const AsyncValue.data([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).restoreSession();

      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/splash');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/onboarding/setup');
    });

    testWidgets('Logging out redirects immediately to /login',
        (WidgetTester tester) async {
      final mockRepo = AuthRepositoryMock();
      await mockRepo.login('test@test.com', 'password');

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          medicationProvider.overrideWith(
            (ref) => MedicationNotifier(ref, autoInit: false)
              ..state = const AsyncValue.data([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.notifier).restoreSession();
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      router.go('/dashboard');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/dashboard');

      // Trigger logout
      await container.read(authNotifierProvider.notifier).logout();
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/login');
    });
  });
}

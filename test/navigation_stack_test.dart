import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/routes/app_router.dart';
import 'package:zindagi_plus/shared/widgets/app_back_button.dart';

void main() {
  group('Navigation Stack & Back Navigation Tests', () {
    late ProviderContainer container;

    setUp(() {
      final mockAuth = AuthRepositoryMock();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-user-nav',
              name: 'Ammar Malik',
              email: 'ammar@test.com',
              isOnboardingCompleted: true,
            ));
            return notifier;
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Root tabs (Dashboard, Upload, Meals, Chat, Profile) do not show back button',
        (WidgetTester tester) async {
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // 1. Dashboard
      router.go('/dashboard');
      await tester.pump();
      expect(router.state.matchedLocation, '/dashboard');
      expect(find.byType(AppBackButton), findsNothing);

      // 2. Upload
      router.go('/upload');
      await tester.pump();
      expect(router.state.matchedLocation, '/upload');
      expect(find.byType(AppBackButton), findsNothing);

      // 3. Meals
      router.go('/meals');
      await tester.pump();
      expect(router.state.matchedLocation, '/meals');
      expect(find.byType(AppBackButton), findsNothing);

      // 4. Chat
      router.go('/chat');
      await tester.pump();
      expect(router.state.matchedLocation, '/chat');
      expect(find.byType(AppBackButton), findsNothing);

      // 5. Profile
      router.go('/profile');
      await tester.pump();
      expect(router.state.matchedLocation, '/profile');
      expect(find.byType(AppBackButton), findsNothing);

      // Advance mock repository timers
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Dashboard -> Medications -> Add Medication -> Back stack navigation',
        (WidgetTester tester) async {
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Start on Dashboard
      router.go('/dashboard');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/dashboard');

      // Navigate to Medications
      router.push('/medications');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/medications');
      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Navigate to Add Medication
      router.push('/add-medication');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/add-medication');
      expect(find.byType(AppBackButton), findsWidgets);
      expect(find.byIcon(Icons.arrow_back), findsWidgets);

      // Tap Back on Add Medication -> should return to Medications
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/medications');

      // Tap Back on Medications -> should return to Dashboard
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/dashboard');
    });

    testWidgets('Profile -> Settings -> Account -> Delete Account -> Back stack navigation',
        (WidgetTester tester) async {
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Start on Profile
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/profile');

      // Navigate to Settings
      router.push('/settings');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/settings');
      expect(find.byType(AppBackButton), findsOneWidget);

      // Navigate to Account Management
      router.push('/settings/account');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/settings/account');
      expect(find.byType(AppBackButton), findsWidgets);

      // Navigate to Delete Account
      router.push('/settings/account/delete');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/settings/account/delete');
      expect(find.byType(AppBackButton), findsWidgets);

      // Tap Back on Delete Account -> should return to Account Management
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/settings/account');

      // Tap Back on Account Management -> should return to Settings
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/settings');

      // Tap Back on Settings -> should return to Profile
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/profile');
    });

    testWidgets('Dashboard -> Activities -> Nearby Facilities -> Back stack navigation',
        (WidgetTester tester) async {
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Start on Dashboard
      router.go('/dashboard');
      await tester.pumpAndSettle();

      // Navigate to Activities
      router.push('/activities');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/activities');
      expect(find.byType(AppBackButton), findsOneWidget);

      // Navigate to Nearby Facilities
      router.push('/nearby-facilities');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/nearby-facilities');
      expect(find.byType(AppBackButton), findsWidgets);

      // Tap Back on Nearby Facilities -> returns to Activities
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/activities');

      // Tap Back on Activities -> returns to Dashboard
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/dashboard');
    });

    testWidgets('Upload -> Report Result -> AI Explanation -> Back stack navigation',
        (WidgetTester tester) async {
      final router = container.read(goRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Start on Upload tab
      router.go('/upload');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.matchedLocation, '/upload');

      // Push Report Result
      router.push('/upload/result', extra: {'reportId': 'r1', 'fileName': 'test.jpg'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.matchedLocation, '/upload/result');
      expect(find.byType(AppBackButton), findsOneWidget);

      // Push AI Explanation
      router.push('/upload/explanation', extra: {'reportId': 'r1'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.matchedLocation, '/upload/explanation');
      expect(find.byType(AppBackButton), findsWidgets);

      // Tap Back on AI Explanation -> returns to Report Result
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(router.state.matchedLocation, '/upload/result');

      // Tap Back on Report Result -> returns to Upload
      await tester.tap(find.byType(AppBackButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(router.state.matchedLocation, '/upload');

      // Advance mock timers
      await tester.pump(const Duration(seconds: 2));
    });
  });
}

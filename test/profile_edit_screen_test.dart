import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/features/profile/screens/profile_edit_screen.dart';
import 'package:zindagi_plus/features/profile/screens/profile_screen.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

void main() {
  group('ProfileEditScreen Dropdown initialization', () {
    testWidgets('Renders properly when primaryGoal is "Improve overall health"',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-user-1',
              name: 'Test User',
              email: 'test@example.com',
              isOnboardingCompleted: true,
              primaryGoal: 'Improve overall health',
              bloodType: 'B+',
              dietType: 'No specific diet',
            ));
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileEditScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Improve overall health'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders properly when primaryGoal is null and bloodType has unicode minus',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-user-2',
              name: 'Test User 2',
              email: 'test2@example.com',
              isOnboardingCompleted: true,
              primaryGoal: null,
              bloodType: 'O−',
              dietType: null,
            ));
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileEditScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen renders, scrolls smoothly, and responds to touches',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-user-scroll',
              name: 'Scroll User',
              email: 'scroll@example.com',
              isOnboardingCompleted: true,
              primaryGoal: 'Improve overall health',
              dietType: 'High Protein / Low Carb',
              weightKg: 75,
              heightCm: 180,
            ));
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Scroll User'), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      // Scroll back up
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(find.text('Health Information'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

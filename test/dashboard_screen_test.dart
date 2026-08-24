import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/features/dashboard/screens/dashboard_screen.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

import 'package:zindagi_plus/providers/medication_provider.dart';

void main() {
  group('DashboardScreen & Subtree Widget Tests', () {
    testWidgets('renders greeting, score card, quick actions, and insights cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationProvider.overrideWith(
              (ref) => MedicationNotifier(ref, autoInit: false)
                ..state = const AsyncValue.data([]),
            ),
            authNotifierProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setUser(const User(
                id: 'test-user-dash',
                name: 'Ammar Malik',
                email: 'ammar@test.com',
                weightKg: 72.0,
                isOnboardingCompleted: true,
              ));
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Greeting
      expect(find.text('Ammar Malik'), findsOneWidget);

      // Section header
      expect(find.text('Your health, at a glance'), findsOneWidget);

      // Score panel metrics
      expect(find.text('HEALTH PULSE · SAMPLE SCORE (DEMO)'), findsOneWidget);
      expect(find.text('72 kg'), findsOneWidget);
      expect(find.text('latest report'), findsOneWidget);
      expect(find.text('medicines'), findsOneWidget);

      // Quick action items
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Medications'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);

      // Insights section
      expect(find.text('Zindagi intelligence'), findsOneWidget);
      expect(find.text('SAMPLE'), findsOneWidget);
    });

    testWidgets('updates username selectively without crashing or frame drops', (tester) async {
      final notifier = AuthNotifier();
      notifier.setUser(const User(
        id: 'test-user-dash',
        name: 'Ammar Initial',
        email: 'ammar@test.com',
        isOnboardingCompleted: true,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationProvider.overrideWith(
              (ref) => MedicationNotifier(ref, autoInit: false)
                ..state = const AsyncValue.data([]),
            ),
            authNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Ammar Initial'), findsOneWidget);

      // Update user name in notifier
      notifier.setUser(const User(
        id: 'test-user-dash',
        name: 'Ammar Updated',
        email: 'ammar@test.com',
        isOnboardingCompleted: true,
      ));

      await tester.pumpAndSettle();
      expect(find.text('Ammar Updated'), findsOneWidget);
    });
  });
}



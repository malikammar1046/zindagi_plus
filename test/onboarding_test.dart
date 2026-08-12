// Widget test validating registration -> onboarding flow without lifecycle errors.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/features/onboarding/screens/onboarding_setup_screen.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

void main() {
  testWidgets('OnboardingSetupScreen initializes without modifying provider in build',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith((ref) {
          final notifier = AuthNotifier();
          notifier.setUser(const User(
            id: 'test_123',
            name: 'New Test User',
            email: 'newuser@test.com',
            isOnboardingCompleted: false,
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
          home: OnboardingSetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify step 1 renders with user's name
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Step 1 of 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

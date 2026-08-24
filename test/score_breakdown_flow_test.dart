import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/features/dashboard/screens/score_breakdown_screen.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/routes/app_router.dart';

void main() {
  testWidgets('Dashboard -> Score Breakdown -> Back navigation test', (tester) async {
    final mockUser = User(
      id: 'test-user-id',
      name: 'Ammar Malik',
      email: 'ammar@example.com',
      isOnboardingCompleted: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => _StaticAuthNotifier(mockUser)),
          medicationProvider.overrideWith((ref) => MedicationNotifier(ref, autoInit: false)),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();
    expect(find.text('Your health, at a glance'), findsOneWidget);
    expect(find.text('Ammar Malik'), findsOneWidget);

    // Tap to push /score-breakdown
    final scorePanel = find.text('Tap to see score breakdown  →');
    expect(scorePanel, findsOneWidget);
    await tester.tap(scorePanel);
    await tester.pumpAndSettle();

    // Verify Score Breakdown screen is displayed
    expect(find.byType(ScoreBreakdownScreen), findsOneWidget);
    expect(find.text('Health Score'), findsOneWidget);
    expect(find.text('Score Breakdown'), findsOneWidget);

    // Tap back button
    final backBtn = find.byType(IconButton).first;
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verify returning to Dashboard cleanly without errors
    expect(find.text('Your health, at a glance'), findsOneWidget);
    expect(find.text('Ammar Malik'), findsOneWidget);
    expect(find.byType(ScoreBreakdownScreen), findsNothing);

    // Repeat 5 times to test loop stability
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.text('Tap to see score breakdown  →'));
      await tester.pumpAndSettle();
      expect(find.byType(ScoreBreakdownScreen), findsOneWidget);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Your health, at a glance'), findsOneWidget);
    }
  });
}

class _StaticAuthNotifier extends AuthNotifier {
  _StaticAuthNotifier(User user) : super() {
    state = user;
  }
}

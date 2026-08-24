import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/features/auth/screens/login_screen.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Authentication Tests', () {
    test('AuthRepositoryMock.signInWithGoogle returns success and populates user', () async {
      final repo = AuthRepositoryMock();
      final res = await repo.signInWithGoogle();

      expect(res.isSuccess, isTrue);

      final userRes = await repo.getCurrentUser();
      expect(userRes.isSuccess, isTrue);
      expect((userRes as Success<User>).data.email, equals('google@test.com'));
      expect(userRes.data.name, equals('Google User'));
    });

    test('AuthNotifier handles signInWithGoogle state transition', () async {
      final repo = AuthRepositoryMock();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );

      // Initial state is null
      expect(container.read(authNotifierProvider), isNull);

      // Initiate Google sign in
      final res = await repo.signInWithGoogle();
      expect(res.isSuccess, isTrue);

      // Allow event loop to process AuthChangeEvent
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final currentUser = container.read(authNotifierProvider);
      expect(currentUser, isNotNull);
      expect(currentUser?.email, equals('google@test.com'));

      container.dispose();
    });

    testWidgets('LoginScreen renders Continue with Google button and handles tap', (tester) async {
      final repo = AuthRepositoryMock();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final googleButton = find.text('Continue with Google');
      // Verify "Continue with Google" button is rendered
      expect(googleButton, findsOneWidget);
      expect(find.text('OR'), findsOneWidget);

      // Ensure button is visible before tapping
      await tester.ensureVisible(googleButton);
      await tester.pumpAndSettle();

      // Tap the Google Sign-In button
      await tester.tap(googleButton);
      await tester.pump();

      // Check that loading state / action is triggered without errors
      await tester.pumpAndSettle();
    });
  });
}

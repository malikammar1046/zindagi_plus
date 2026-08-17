import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

// Helper: creates a ProviderContainer with the mock auth repo injected.
ProviderContainer makeContainer({User? initialUser}) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        (ref) => AuthNotifier(
          authRepository: AuthRepositoryMock(initialUser),
        ),
      ),
    ],
  );
}

void main() {
  group('AuthNotifier', () {
    group('initial state', () {
      test('state is null when no initial user', () {
        // Mock getCurrentUser returns Failure when no user is set.
        final container = makeContainer();
        addTearDown(container.dispose);
        // Give the async init a tick to settle.
        expect(container.read(authNotifierProvider), isNull);
      });

      test('state is the initial user when pre-seeded', () async {
        const user = User(
          id: '1',
          name: 'Ammar',
          email: 'test@test.com',
          isOnboardingCompleted: true,
        );
        final container = makeContainer(initialUser: user);
        addTearDown(container.dispose);
        // Explicitly trigger and await session restoration.
        await container.read(authNotifierProvider.notifier).restoreSession();
        final state = container.read(authNotifierProvider);
        expect(state, equals(user));
      });
    });

    group('updateProfile()', () {
      test('updates state with new user data', () async {
        const initialUser = User(
          id: '1',
          name: 'Ammar',
          email: 'test@test.com',
          isOnboardingCompleted: true,
        );
        final container = makeContainer(initialUser: initialUser);
        addTearDown(container.dispose);
        await Future.microtask(() {});

        final updated = initialUser.copyWith(name: 'Ali', weightKg: 70.0);
        final result = await container
            .read(authNotifierProvider.notifier)
            .updateProfile(updated);

        expect(result, isA<Success<User>>());
        final newState = container.read(authNotifierProvider);
        expect(newState?.name, equals('Ali'));
        expect(newState?.weightKg, equals(70.0));
      });

      test('preserves isOnboardingCompleted on updateProfile', () async {
        const initialUser = User(
          id: '1',
          name: 'Ammar',
          email: 'test@test.com',
          isOnboardingCompleted: true,
        );
        final container = makeContainer(initialUser: initialUser);
        addTearDown(container.dispose);
        await Future.microtask(() {});

        final updated = initialUser.copyWith(name: 'Changed');
        await container
            .read(authNotifierProvider.notifier)
            .updateProfile(updated);

        final state = container.read(authNotifierProvider);
        expect(state?.isOnboardingCompleted, isTrue);
      });
    });

    group('completeOnboarding()', () {
      test('sets isOnboardingCompleted = true', () async {
        const initialUser = User(
          id: '1',
          name: 'Ammar',
          email: 'test@test.com',
          isOnboardingCompleted: false,
        );
        final container = makeContainer(initialUser: initialUser);
        addTearDown(container.dispose);
        await Future.microtask(() {});

        final result = await container
            .read(authNotifierProvider.notifier)
            .completeOnboarding(initialUser);

        expect(result, isA<Success<User>>());
        final state = container.read(authNotifierProvider);
        expect(state?.isOnboardingCompleted, isTrue);
      });
    });

    group('logout()', () {
      test('clears user state', () async {
        const initialUser = User(
          id: '1',
          name: 'Ammar',
          email: 'test@test.com',
          isOnboardingCompleted: true,
        );
        final container = makeContainer(initialUser: initialUser);
        addTearDown(container.dispose);
        await Future.microtask(() {});

        await container.read(authNotifierProvider.notifier).logout();

        final state = container.read(authNotifierProvider);
        expect(state, isNull);
      });
    });
  });
}

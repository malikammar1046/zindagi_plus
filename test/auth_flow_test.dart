import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

void main() {
  group('User.fromProfile mapping', () {
    test('Correctly maps profile row and calculates age', () {
      final profile = {
        'id': 'user-123',
        'full_name': 'Test User',
        'is_onboarding_completed': true,
        'date_of_birth': '2000-01-15',
        'gender': 'Male',
        'height_cm': 180.5,
        'weight_kg': 75.0,
        'blood_type': 'O+',
        'city': 'Islamabad',
        'phone': '+923001234567',
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      final user = User.fromProfile(profile, email: 'test@example.com');

      expect(user.id, 'user-123');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.isOnboardingCompleted, isTrue);
      expect(user.gender, 'Male');
      expect(user.heightCm, 180.5);
      expect(user.weightKg, 75.0);
      expect(user.bloodType, 'O+');
      expect(user.city, 'Islamabad');
      expect(user.phone, '+923001234567');
      expect(user.photoUrl, 'https://example.com/avatar.jpg');
      expect(user.age, isNotNull);
      expect(user.age! >= 24, isTrue);
    });

    test('Handles missing / null fields gracefully', () {
      final profile = <String, dynamic>{
        'id': 'user-empty',
        'full_name': 'Anonymous',
        'is_onboarding_completed': false,
      };

      final user = User.fromProfile(profile);

      expect(user.id, 'user-empty');
      expect(user.name, 'Anonymous');
      expect(user.email, '');
      expect(user.isOnboardingCompleted, isFalse);
      expect(user.age, isNull);
      expect(user.dateOfBirth, isNull);
      expect(user.weightKg, isNull);
      expect(user.heightCm, isNull);
    });
  });

  group('AuthNotifier State Management', () {
    test('Initializes with null state and restores user upon login', () async {
      final mockRepo = AuthRepositoryMock();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      // Initially null
      expect(container.read(authNotifierProvider), isNull);

      // Set user
      const user = User(
        id: 'u-1',
        name: 'Ammar',
        email: 'ammar@test.com',
        isOnboardingCompleted: false,
      );
      notifier.setUser(user);
      expect(container.read(authNotifierProvider), equals(user));

      // Update profile
      final updated = user.copyWith(city: 'Lahore', weightKg: 70.0);
      await notifier.updateProfile(updated);
      expect(container.read(authNotifierProvider)?.city, 'Lahore');
      expect(container.read(authNotifierProvider)?.weightKg, 70.0);

      // Complete onboarding
      final completeRes = await notifier.completeOnboarding(updated);
      expect(completeRes, isA<Success<User>>());
      expect(
          container.read(authNotifierProvider)?.isOnboardingCompleted, isTrue);

      // Logout
      await notifier.logout();
      expect(container.read(authNotifierProvider), isNull);
    });

    test('Failed onboarding save does NOT mark onboarding as completed', () async {
      const user = User(
        id: 'u-fail',
        name: 'Fail User',
        email: 'fail@test.com',
        isOnboardingCompleted: false,
      );
      final failingRepo = _FailingOnboardingAuthRepo(user);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(failingRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.restoreSession();
      expect(container.read(authNotifierProvider)?.isOnboardingCompleted, isFalse);

      final res = await notifier.completeOnboarding(user);
      expect(res, isA<Failure<User>>());
      expect(container.read(authNotifierProvider)?.isOnboardingCompleted, isFalse);
    });
  });

  group('AuthRepository Lifecycle Operations', () {
    late AuthRepositoryMock repo;

    setUp(() {
      repo = AuthRepositoryMock();
    });

    test('login with valid credentials succeeds', () async {
      final res = await repo.login('test@test.com', 'password');
      expect(res, isA<Success<User>>());
      if (res is Success<User>) {
        expect(res.data.name, 'Ammar');
        expect(res.data.isOnboardingCompleted, isTrue);
      }
    });

    test('login with invalid credentials fails', () async {
      final res = await repo.login('wrong@test.com', 'wrongpassword');
      expect(res, isA<Failure<User>>());
      if (res is Failure<User>) {
        expect(res.message, contains('Invalid'));
      }
    });

    test('register returns new un-onboarded user', () async {
      final res =
          await repo.register('New User', 'new@test.com', 'secret123');
      expect(res, isA<Success<User>>());
      if (res is Success<User>) {
        expect(res.data.name, 'New User');
        expect(res.data.email, 'new@test.com');
        expect(res.data.isOnboardingCompleted, isFalse);
      }
    });

    test('completeOnboarding marks user as onboarded and persists data', () async {
      const unOnboarded = User(
        id: 'u-2',
        name: 'User 2',
        email: 'u2@test.com',
        isOnboardingCompleted: false,
      );
      final res = await repo.completeOnboarding(unOnboarded);
      expect(res, isA<Success<User>>());
      if (res is Success<User>) {
        expect(res.data.isOnboardingCompleted, isTrue);
      }

      final current = await repo.getCurrentUser();
      expect(current, isA<Success<User>>());
      if (current is Success<User>) {
        expect(current.data.isOnboardingCompleted, isTrue);
      }
    });

    test('logout clears mock session', () async {
      await repo.login('test@test.com', 'password');
      final currentRes = await repo.getCurrentUser();
      expect(currentRes, isA<Success<User>>());

      final logoutRes = await repo.logout();
      expect(logoutRes, isA<Success<void>>());

      final afterLogout = await repo.getCurrentUser();
      expect(afterLogout, isA<Failure<User>>());
    });

    test('password reset and update methods return success', () async {
      final resetRes = await repo.resetPasswordForEmail('test@test.com');
      expect(resetRes, isA<Success<void>>());

      final updateRes = await repo.updatePassword('newPassword123');
      expect(updateRes, isA<Success<void>>());

      final resendRes = await repo.resendVerificationEmail('test@test.com');
      expect(resendRes, isA<Success<void>>());
    });

    test('verifyOtp returns verified user', () async {
      final otpRes =
          await repo.verifyOtp(email: 'verify@test.com', token: '123456');
      expect(otpRes, isA<Success<User>>());
      if (otpRes is Success<User>) {
        expect(otpRes.data.email, 'verify@test.com');
      }
    });
  });
}

class _FailingOnboardingAuthRepo extends AuthRepositoryMock {
  _FailingOnboardingAuthRepo([super.initialUser]);

  @override
  Future<Result<User>> completeOnboarding(User user) async {
    return const Failure('Database connection error');
  }
}

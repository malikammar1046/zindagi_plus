import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Save & Update Regression Tests (user_goals_user_id_key Fix)', () {
    late User initialUser;
    late AuthRepositoryMock mockAuthRepo;
    late ProviderContainer container;

    setUp(() async {
      initialUser = const User(
        id: 'user_123',
        name: 'Ammar Malik',
        email: 'ammar@test.com',
        isOnboardingCompleted: true,
        age: 24,
        weightKg: 72.0,
        heightCm: 175.0,
        gender: 'Male',
        bloodType: 'B+',
        city: 'Lahore',
        primaryGoal: 'Improve overall health',
        activityLevel: 'Lightly active',
        fitnessExperience: 'Intermediate',
        workoutTimePerDay: '30 minutes',
        equipment: 'Basic home equipment',
        dietType: 'High Protein / Low Carb',
        conditions: ['Pre-diabetes'],
        allergies: ['Peanuts'],
      );

      mockAuthRepo = AuthRepositoryMock(initialUser);
      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(authRepository: mockAuthRepo),
          ),
        ],
      );

      await container.read(authNotifierProvider.notifier).restoreSession();
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Existing user changes age -> save succeeds and preserves all goals', () async {
      final user = container.read(authNotifierProvider)!;
      final updated = user.copyWith(age: 25);

      final res = await container.read(authNotifierProvider.notifier).updateProfile(updated);
      expect(res.isSuccess, isTrue);

      final current = container.read(authNotifierProvider)!;
      expect(current.age, equals(25));
      expect(current.primaryGoal, equals('Improve overall health'));
      expect(current.activityLevel, equals('Lightly active'));
      expect(current.id, equals('user_123'));
    });

    test('2. Existing user changes name -> save succeeds', () async {
      final user = container.read(authNotifierProvider)!;
      final updated = user.copyWith(name: 'Ammar Updated');

      final res = await container.read(authNotifierProvider.notifier).updateProfile(updated);
      expect(res.isSuccess, isTrue);

      final current = container.read(authNotifierProvider)!;
      expect(current.name, equals('Ammar Updated'));
    });

    test('3. Existing user changes height -> save succeeds', () async {
      final user = container.read(authNotifierProvider)!;
      final updated = user.copyWith(heightCm: 180.0);

      final res = await container.read(authNotifierProvider.notifier).updateProfile(updated);
      expect(res.isSuccess, isTrue);

      final current = container.read(authNotifierProvider)!;
      expect(current.heightCm, equals(180.0));
    });

    test('4. Existing user changes weight -> save succeeds', () async {
      final user = container.read(authNotifierProvider)!;
      final updated = user.copyWith(weightKg: 75.5);

      final res = await container.read(authNotifierProvider.notifier).updateProfile(updated);
      expect(res.isSuccess, isTrue);

      final current = container.read(authNotifierProvider)!;
      expect(current.weightKg, equals(75.5));
    });

    test('5. Existing user changes activity level -> save succeeds', () async {
      final user = container.read(authNotifierProvider)!;
      final updated = user.copyWith(activityLevel: 'Very active');

      final res = await container.read(authNotifierProvider.notifier).updateProfile(updated);
      expect(res.isSuccess, isTrue);

      final current = container.read(authNotifierProvider)!;
      expect(current.activityLevel, equals('Very active'));
    });

    test('6. Existing user changes multiple fields simultaneously -> save succeeds', () async {
      final user = container.read(authNotifierProvider)!;
      final updated = user.copyWith(
        name: 'Ammar M.',
        age: 26,
        heightCm: 178.0,
        weightKg: 74.0,
        city: 'Islamabad',
        primaryGoal: 'Lose weight sustainably',
        dietType: 'Low Glycemic Index',
      );

      final res = await container.read(authNotifierProvider.notifier).updateProfile(updated);
      expect(res.isSuccess, isTrue);

      final current = container.read(authNotifierProvider)!;
      expect(current.name, equals('Ammar M.'));
      expect(current.age, equals(26));
      expect(current.heightCm, equals(178.0));
      expect(current.weightKg, equals(74.0));
      expect(current.city, equals('Islamabad'));
      expect(current.primaryGoal, equals('Lose weight sustainably'));
      expect(current.dietType, equals('Low Glycemic Index'));
    });

    test('7. Existing user saves without changing anything -> save succeeds idempotently', () async {
      final user = container.read(authNotifierProvider)!;

      final res = await container.read(authNotifierProvider.notifier).updateProfile(user);
      expect(res.isSuccess, isTrue);

      final current = container.read(authNotifierProvider)!;
      expect(current, equals(user));
    });

    test('8. Existing user edits profile multiple consecutive times -> all saves succeed', () async {
      for (int i = 1; i <= 5; i++) {
        final current = container.read(authNotifierProvider)!;
        final updated = current.copyWith(
          age: 20 + i,
          weightKg: 70.0 + i,
        );

        final res = await container.read(authNotifierProvider.notifier).updateProfile(updated);
        expect(res.isSuccess, isTrue);
        expect(container.read(authNotifierProvider)!.age, equals(20 + i));
      }
    });

    test('9. New user completing onboarding creates profile and goals exactly once', () async {
      const newUser = User(
        id: 'new_user_456',
        name: 'New User',
        email: 'new@test.com',
        isOnboardingCompleted: false,
      );

      final newMockRepo = AuthRepositoryMock(newUser);
      final newContainer = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(authRepository: newMockRepo),
          ),
        ],
      );
      addTearDown(newContainer.dispose);

      await newContainer.read(authNotifierProvider.notifier).restoreSession();

      final onboardedUser = newUser.copyWith(
        age: 30,
        gender: 'Female',
        heightCm: 165.0,
        weightKg: 60.0,
        primaryGoal: 'Build healthier daily habits',
        activityLevel: 'Moderately active',
        isOnboardingCompleted: true,
      );

      final res = await newContainer.read(authNotifierProvider.notifier).completeOnboarding(onboardedUser);
      expect(res.isSuccess, isTrue);

      final current = newContainer.read(authNotifierProvider)!;
      expect(current.isOnboardingCompleted, isTrue);
      expect(current.primaryGoal, equals('Build healthier daily habits'));
    });
  });
}

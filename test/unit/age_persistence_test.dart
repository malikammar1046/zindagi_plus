import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

void main() {
  group('Age Persistence & Profile Field Integrity', () {
    const fullUser = User(
      id: 'usr-100',
      name: 'Ammar Malik',
      email: 'ammar@test.com',
      isOnboardingCompleted: true,
      age: 24,
      dateOfBirth: null,
      weightKg: 72.5,
      heightCm: 175.0,
      bloodType: 'B+',
      city: 'Lahore',
      gender: 'Male',
      photoUrl: 'https://example.com/avatar.png',
      phone: '+923001234567',
      primaryGoal: 'Gain lean muscle & strength',
      secondaryGoals: ['Improve cardiovascular fitness'],
      dietType: 'High Protein / Low Carb',
      foodPreferences: ['Chicken', 'Fish'],
      foodsToAvoid: ['Refined Sugar'],
      conditions: ['Vitamin D Deficiency'],
      allergies: ['Peanuts'],
    );

    test('User.copyWith(age: ...) updates age and synchronizes dateOfBirth', () {
      final updated = fullUser.copyWith(age: 30);

      expect(updated.age, 30);
      expect(updated.dateOfBirth, isNotNull);
      final expectedBirthYear = DateTime.now().year - 30;
      expect(updated.dateOfBirth!.year, expectedBirthYear);
    });

    test('User.copyWith(age: ...) retains all other profile fields without reset', () {
      final updated = fullUser.copyWith(age: 32);

      expect(updated.age, 32);
      expect(updated.id, fullUser.id);
      expect(updated.name, fullUser.name);
      expect(updated.email, fullUser.email);
      expect(updated.isOnboardingCompleted, fullUser.isOnboardingCompleted);
      expect(updated.weightKg, fullUser.weightKg);
      expect(updated.heightCm, fullUser.heightCm);
      expect(updated.bloodType, fullUser.bloodType);
      expect(updated.city, fullUser.city);
      expect(updated.gender, fullUser.gender);
      expect(updated.photoUrl, fullUser.photoUrl);
      expect(updated.phone, fullUser.phone);
      expect(updated.primaryGoal, fullUser.primaryGoal);
      expect(updated.secondaryGoals, fullUser.secondaryGoals);
      expect(updated.dietType, fullUser.dietType);
      expect(updated.foodPreferences, fullUser.foodPreferences);
      expect(updated.foodsToAvoid, fullUser.foodsToAvoid);
      expect(updated.conditions, fullUser.conditions);
      expect(updated.allergies, fullUser.allergies);
    });

    test('User.fromProfile calculates correct age from date_of_birth', () {
      final now = DateTime.now();
      final birthYear = now.year - 28;
      final dobStr = '$birthYear-01-01';

      final user = User.fromProfile({
        'id': 'usr-200',
        'full_name': 'Test User',
        'date_of_birth': dobStr,
        'weight_kg': 70.0,
        'height_cm': 170.0,
        'blood_type': 'O+',
        'city': 'Islamabad',
        'is_onboarding_completed': true,
      });

      expect(user.age, 28);
      expect(user.dateOfBirth, isNotNull);
      expect(user.dateOfBirth!.year, birthYear);
    });

    test('User.fromProfile uses age fallback when date_of_birth is omitted', () {
      final user = User.fromProfile({
        'id': 'usr-300',
        'full_name': 'Fallback User',
        'age': 25,
      });

      expect(user.age, 25);
    });

    test('AuthNotifier.updateProfile updates age in state via repository', () async {
      final mockRepo = AuthRepositoryMock();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      notifier.setUser(fullUser);

      expect(container.read(authNotifierProvider)?.age, 24);

      // Change age to 35
      final modified = fullUser.copyWith(age: 35);
      final result = await notifier.updateProfile(modified);

      expect(result, isA<Success<User>>());
      final stateUser = container.read(authNotifierProvider);
      expect(stateUser?.age, 35);
      expect(stateUser?.photoUrl, 'https://example.com/avatar.png');
      expect(stateUser?.weightKg, 72.5);
      expect(stateUser?.heightCm, 175.0);
      expect(stateUser?.bloodType, 'B+');
      expect(stateUser?.city, 'Lahore');
      expect(stateUser?.primaryGoal, 'Gain lean muscle & strength');
      expect(stateUser?.conditions, ['Vitamin D Deficiency']);
      expect(stateUser?.allergies, ['Peanuts']);
    });
  });
}

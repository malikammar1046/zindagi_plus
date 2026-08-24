import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/user.dart';

void main() {
  group('User model', () {
    const baseUser = User(
      id: 'u1',
      name: 'Ammar',
      email: 'ammar@test.com',
      isOnboardingCompleted: true,
    );

    group('copyWith', () {
      test('creates a new instance with updated fields', () {
        final updated = baseUser.copyWith(name: 'Ali', age: 25);
        expect(updated.name, equals('Ali'));
        expect(updated.age, equals(25));
        expect(updated.email, equals('ammar@test.com')); // unchanged
        expect(updated.isOnboardingCompleted, isTrue);   // unchanged
      });

      test('original remains immutable', () {
        baseUser.copyWith(name: 'Changed');
        expect(baseUser.name, equals('Ammar'));
      });

      test('can update conditions and allergies', () {
        final updated = baseUser.copyWith(
          conditions: ['Diabetes'],
          allergies: ['Peanuts'],
        );
        expect(updated.conditions, equals(['Diabetes']));
        expect(updated.allergies, equals(['Peanuts']));
      });
    });

    group('User.fromProfile', () {
      test('maps basic fields from profile row', () {
        final profileRow = {
          'id': 'u2',
          'full_name': 'Sara',
          'is_onboarding_completed': true,
          'weight_kg': 55.5,
          'height_cm': 160.0,
          'blood_type': 'A+',
          'gender': 'Female',
          'city': 'Karachi',
          'date_of_birth': '1998-05-15',
          'phone': null,
          'avatar_url': null,
        };
        final user = User.fromProfile(
          profileRow,
          email: 'sara@test.com',
          goals: null,
          conditions: [],
          allergies: [],
        );
        expect(user.id, equals('u2'));
        expect(user.name, equals('Sara'));
        expect(user.email, equals('sara@test.com'));
        expect(user.isOnboardingCompleted, isTrue);
        expect(user.weightKg, equals(55.5));
        expect(user.bloodType, equals('A+'));
        expect(user.city, equals('Karachi'));
      });

      test('maps conditions from list', () {
        final profileRow = {
          'id': 'u3',
          'full_name': 'Test',
          'is_onboarding_completed': false,
        };
        // conditions is passed as List<String> directly
        final user = User.fromProfile(
          profileRow,
          goals: null,
          conditions: ['Diabetes', 'Hypertension'],
          allergies: [],
        );
        expect(user.conditions, containsAll(['Diabetes', 'Hypertension']));
      });

      test('maps allergies from list', () {
        final profileRow = {
          'id': 'u4',
          'full_name': 'Test',
          'is_onboarding_completed': true,
        };
        final user = User.fromProfile(
          profileRow,
          goals: null,
          conditions: [],
          allergies: ['Peanuts', 'Shellfish'],
        );
        expect(user.allergies, containsAll(['Peanuts', 'Shellfish']));
      });

      test('handles null/missing optional fields', () {
        final profileRow = {
          'id': 'u5',
          'full_name': null,
          'is_onboarding_completed': false,
        };
        final user = User.fromProfile(
          profileRow,
          goals: null,
          conditions: [],
          allergies: [],
        );
        expect(user.name, equals('')); // fromProfile defaults to ''
        expect(user.weightKg, isNull);
        expect(user.conditions, isEmpty);
        expect(user.allergies, isEmpty);
      });

      test('maps goals from goals map', () {
        final profileRow = {
          'id': 'u6',
          'full_name': 'Goal User',
          'is_onboarding_completed': true,
        };
        final goalsRow = {
          'primary_goal': 'Lose weight',
          'diet_type': 'Keto',
          'activity_level': 'Moderately active',
        };
        final user = User.fromProfile(
          profileRow,
          goals: goalsRow,
          conditions: [],
          allergies: [],
        );
        expect(user.primaryGoal, equals('Lose weight'));
        expect(user.dietType, equals('Keto'));
        expect(user.activityLevel, equals('Moderately active'));
      });
    });

    group('User fields', () {
      test('default conditions and allergies are empty', () {
        const u = User(id: 'x', name: 'X', email: 'x@x.com');
        expect(u.conditions, isEmpty);
        expect(u.allergies, isEmpty);
      });

      test('isOnboardingCompleted defaults to false', () {
        const u = User(id: 'x', name: 'X', email: 'x@x.com');
        expect(u.isOnboardingCompleted, isFalse);
      });

      test('equality is based on all User fields', () {
        const u1 = User(id: 'a', name: 'X', email: 'a@b.com');
        const u2 = User(id: 'a', name: 'X', email: 'a@b.com');
        const u3 = User(id: 'a', name: 'Y', email: 'a@b.com');
        expect(u1, equals(u2));
        expect(u1, isNot(equals(u3)));
      });
    });
  });
}

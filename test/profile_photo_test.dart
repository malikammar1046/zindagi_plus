import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/features/profile/screens/profile_edit_screen.dart';
import 'package:zindagi_plus/features/profile/screens/profile_screen.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

void main() {
  group('User Model - Profile Photo serialization and persistence', () {
    test('User.fromJson and User.toJson preserve photoUrl', () {
      final user = const User(
        id: 'u123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        isOnboardingCompleted: true,
        photoUrl: 'https://xyz.supabase.co/storage/v1/object/public/avatars/u123/profile.jpg',
      );

      final json = user.toJson();
      expect(json['photoUrl'], 'https://xyz.supabase.co/storage/v1/object/public/avatars/u123/profile.jpg');

      final reconstructed = User.fromJson(json);
      expect(reconstructed.id, 'u123');
      expect(reconstructed.name, 'Jane Doe');
      expect(reconstructed.photoUrl, 'https://xyz.supabase.co/storage/v1/object/public/avatars/u123/profile.jpg');
    });

    test('User.fromProfile maps avatar_url to photoUrl', () {
      final profileMap = {
        'id': 'u456',
        'full_name': 'Ammar Malik',
        'avatar_url': 'https://xyz.supabase.co/storage/v1/object/public/avatars/u456/profile.jpg?v=123',
        'is_onboarding_completed': true,
        'weight_kg': 75.0,
      };

      final user = User.fromProfile(profileMap, email: 'ammar@example.com');
      expect(user.photoUrl, 'https://xyz.supabase.co/storage/v1/object/public/avatars/u456/profile.jpg?v=123');
      expect(user.weightKg, 75.0);
    });

    test('User.copyWith preserves photoUrl when modifying unrelated fields', () {
      final user = const User(
        id: 'u789',
        name: 'User 1',
        email: 'user1@example.com',
        photoUrl: 'https://example.com/avatar.jpg',
        weightKg: 70.0,
        city: 'Lahore',
      );

      final updated = user.copyWith(
        weightKg: 72.5,
        city: 'Islamabad',
      );

      expect(updated.photoUrl, 'https://example.com/avatar.jpg');
      expect(updated.weightKg, 72.5);
      expect(updated.city, 'Islamabad');
    });
  });

  group('AuthRepository and AuthNotifier - Profile Photo Upload', () {
    test('AuthRepositoryMock uploadProfilePhoto updates current user photoUrl', () async {
      final repo = AuthRepositoryMock();
      await repo.login('test@test.com', 'password');

      final tempFile = File('dummy_profile.jpg');
      final result = await repo.uploadProfilePhoto(tempFile);

      expect(result, isA<Success<User>>());
      final updatedUser = (result as Success<User>).data;
      expect(updatedUser.photoUrl, 'dummy_profile.jpg');

      // Subsequent updateProfile keeps the photoUrl
      final modifiedUser = updatedUser.copyWith(city: 'Karachi');
      final updateResult = await repo.updateProfile(modifiedUser);
      expect((updateResult as Success<User>).data.photoUrl, 'dummy_profile.jpg');
    });

    test('AuthNotifier uploadProfilePhoto updates state immediately', () async {
      final repo = AuthRepositoryMock();
      await repo.login('test@test.com', 'password');

      final notifier = AuthNotifier(authRepository: repo);
      await notifier.restoreSession();

      expect(notifier.state?.name, 'Ammar');
      expect(notifier.state?.photoUrl, isNull);

      final tempFile = File('new_avatar.jpg');
      final result = await notifier.uploadProfilePhoto(tempFile);

      expect(result, isA<Success<User>>());
      expect(notifier.state?.photoUrl, 'new_avatar.jpg');
    });
  });

  group('UI - ProfileScreen & ProfileEditScreen photo rendering', () {
    testWidgets('ProfileScreen renders initials when photoUrl is null', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setUser(const User(
              id: 'test-1',
              name: 'Sarah Connor',
              email: 'sarah@test.com',
              photoUrl: null,
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

      expect(find.text('S'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
    });

    testWidgets('ProfileEditScreen renders Change Photo button and preserves photoUrl on save', (tester) async {
      const initialUser = User(
        id: '1',
        name: 'Ammar',
        email: 'test@test.com',
        photoUrl: 'existing_photo.jpg',
        isOnboardingCompleted: true,
        primaryGoal: 'Improve overall health',
        dietType: 'High Protein / Low Carb',
      );
      final repo = AuthRepositoryMock(initialUser);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier(authRepository: repo);
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileEditScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Tap save and verify photoUrl is still present
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final currentUser = container.read(authNotifierProvider);
      expect(currentUser?.photoUrl, 'existing_photo.jpg');
    });
  });
}

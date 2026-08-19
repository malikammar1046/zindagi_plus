import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, OtpType;
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/interfaces/auth_repository.dart';

/// In-memory mock implementation of [AuthRepository].
///
/// Used when [Environment.isMock] is `true`. Simulates network latency with
/// artificial delays so the UI behaves exactly as it would against a real API.
///
/// Valid credentials: email=`test@test.com` / password=`password`
class AuthRepositoryMock implements AuthRepository {
  AuthRepositoryMock([this._currentUser]);

  // Simulated "session" — set after a successful login or register.
  User? _currentUser;
  final _authStateController = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState>? get authStateChanges => _authStateController.stream;

  @override
  Future<Result<User>> login(String email, String password) async {
    if (email == 'test@test.com' && password == 'password') {
      _currentUser = const User(
        id: '1',
        name: 'Ammar',
        email: 'test@test.com',
        isOnboardingCompleted: true,
        age: 24,
        weightKg: 72,
        heightCm: 175,
        bloodType: 'B+',
        conditions: ['Pre-diabetes', 'Vitamin D Deficiency'],
        allergies: ['Peanuts'],
        primaryGoal: 'Improve blood sugar & fitness',
        activityLevel: 'Lightly active',
        fitnessExperience: 'Intermediate',
        workoutTimePerDay: '30 minutes',
        equipment: 'Basic home equipment',
        dietType: 'High Protein / Low Carb',
        gender: 'Male',
        city: 'Lahore',
      );
      return Success(_currentUser!);
    }

    return const Failure('Invalid credentials');
  }

  @override
  Future<Result<User>> register(
      String name, String email, String password) async {
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      isOnboardingCompleted: false, // New users start un-onboarded
    );
    return Success(_currentUser!);
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    if (_currentUser != null) {
      return Success(_currentUser!);
    }
    return const Failure('No active session');
  }

  @override
  Future<Result<void>> logout() async {
    _currentUser = null;
    return const Success(null);
  }

  @override
  Future<Result<void>> resetPasswordForEmail(String email) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> resendVerificationEmail(String email) async {
    return const Success(null);
  }

  @override
  Future<Result<User>> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    _currentUser = User(
      id: '1',
      name: 'Ammar',
      email: email,
      isOnboardingCompleted: false,
    );
    return Success(_currentUser!);
  }

  @override
  Future<Result<User>> completeOnboarding(User user) async {
    _currentUser = user.copyWith(isOnboardingCompleted: true);
    return Success(_currentUser!);
  }

  @override
  Future<Result<User>> updateProfile(User user) async {
    // Mock: update in-memory user, preserve onboarding status.
    _currentUser = user.copyWith(
      isOnboardingCompleted: _currentUser?.isOnboardingCompleted ?? false,
    );
    return Success(_currentUser!);
  }

  @override
  Future<Result<User>> uploadProfilePhoto(File imageFile) async {
    if (_currentUser == null) {
      return const Failure('No active session');
    }
    _currentUser = _currentUser!.copyWith(
      photoUrl: imageFile.path,
    );
    return Success(_currentUser!);
  }
}


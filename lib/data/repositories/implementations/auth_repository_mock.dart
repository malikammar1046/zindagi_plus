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
  // Simulated "session" — set after a successful login or register.
  User? _currentUser;

  @override
  Future<Result<User>> login(String email, String password) async {
    // Simulate a network round-trip.
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'test@test.com' && password == 'password') {
      _currentUser = User(
        id: '1',
        name: 'Ammar',
        email: email,
        isOnboardingCompleted: true,
        age: 24,
        weightKg: 72,
        heightCm: 175,
        bloodType: 'B+',
        conditions: const ['Pre-diabetes', 'Vitamin D Deficiency'],
        allergies: const ['Peanuts'],
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

    return Failure('Invalid credentials');
  }

  @override
  Future<Result<User>> register(
      String name, String email, String password) async {
    // Simulate a network round-trip.
    await Future.delayed(const Duration(seconds: 1));

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
    // Simulate a shorter cached-response latency.
    await Future.delayed(const Duration(milliseconds: 500));

    // Return the in-memory session if login was called, otherwise a default.
    final user = _currentUser ??
        const User(
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
    return Success(user);
  }
}

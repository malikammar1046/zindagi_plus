import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

/// Holds the active state of the first-time onboarding questionnaire.
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.displayName = '',
    this.dateOfBirth,
    this.age = 24,
    this.gender = 'Male',
    this.heightCm = 175.0,
    this.weightKg = 72.0,
    this.bloodType = 'B+',
    this.conditions = const {},
    this.allergies = const {},
    this.primaryGoal = 'Improve overall health',
    this.secondaryGoals = const {},
    this.activityLevel = 'Lightly active',
    this.fitnessExperience = 'Beginner',
    this.workoutTimePerDay = '30 minutes',
    this.equipment = 'Basic home equipment',
    this.dietType = 'No specific diet',
    this.foodPreferences = const {},
    this.foodsToAvoid = const {},
    this.city = 'Lahore',
  });

  final int currentStep;
  static const int totalSteps = 8;

  // Step 1: Identity
  final String displayName;

  // Step 2: Demographics
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;

  // Step 3: Body metrics
  final double? heightCm;
  final double? weightKg;
  final String? bloodType;

  // Step 4: Health & Allergies
  final Set<String> conditions;
  final Set<String> allergies;

  // Step 5: Goals & Activity
  final String? primaryGoal;
  final Set<String> secondaryGoals;
  final String? activityLevel;

  // Step 6: Fitness routine
  final String? fitnessExperience;
  final String? workoutTimePerDay;
  final String? equipment;

  // Step 7: Nutrition & Diet
  final String? dietType;
  final Set<String> foodPreferences;
  final Set<String> foodsToAvoid;

  // Step 8: Location & Review
  final String? city;

  double get progress => (currentStep + 1) / totalSteps;

  OnboardingState copyWith({
    int? currentStep,
    String? displayName,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? bloodType,
    Set<String>? conditions,
    Set<String>? allergies,
    String? primaryGoal,
    Set<String>? secondaryGoals,
    String? activityLevel,
    String? fitnessExperience,
    String? workoutTimePerDay,
    String? equipment,
    String? dietType,
    Set<String>? foodPreferences,
    Set<String>? foodsToAvoid,
    String? city,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bloodType: bloodType ?? this.bloodType,
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      secondaryGoals: secondaryGoals ?? this.secondaryGoals,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessExperience: fitnessExperience ?? this.fitnessExperience,
      workoutTimePerDay: workoutTimePerDay ?? this.workoutTimePerDay,
      equipment: equipment ?? this.equipment,
      dietType: dietType ?? this.dietType,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      foodsToAvoid: foodsToAvoid ?? this.foodsToAvoid,
      city: city ?? this.city,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(User? initialUser)
      : super(_initialStateFromUser(initialUser));

  static OnboardingState _initialStateFromUser(User? user) {
    if (user == null) return const OnboardingState();
    return OnboardingState(
      displayName: user.name,
      age: user.age ?? 24,
      dateOfBirth: user.dateOfBirth,
      heightCm: user.heightCm ?? 175.0,
      weightKg: user.weightKg ?? 72.0,
      bloodType: user.bloodType ?? 'B+',
      conditions: user.conditions.isNotEmpty
          ? user.conditions.toSet()
          : const {},
      allergies: user.allergies.isNotEmpty
          ? user.allergies.toSet()
          : const {},
      gender: user.gender ?? 'Male',
      city: user.city ?? 'Lahore',
      primaryGoal: user.primaryGoal ?? 'Improve overall health',
      activityLevel: user.activityLevel ?? 'Lightly active',
    );
  }

  void nextStep() {
    if (state.currentStep < OnboardingState.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < OnboardingState.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  void setDisplayName(String name) => state = state.copyWith(displayName: name);

  void setDemographics({DateTime? dob, int? age, String? gender}) =>
      state = state.copyWith(
        dateOfBirth: dob ?? state.dateOfBirth,
        age: age ?? state.age,
        gender: gender ?? state.gender,
      );

  void setBodyMetrics({
    double? heightCm,
    double? weightKg,
    String? bloodType,
  }) =>
      state = state.copyWith(
        heightCm: heightCm ?? state.heightCm,
        weightKg: weightKg ?? state.weightKg,
        bloodType: bloodType ?? state.bloodType,
      );

  void toggleCondition(String condition) {
    final updated = Set<String>.from(state.conditions);
    if (condition == 'None') {
      updated.clear();
      updated.add('None');
    } else {
      updated.remove('None');
      if (updated.contains(condition)) {
        updated.remove(condition);
      } else {
        updated.add(condition);
      }
    }
    state = state.copyWith(conditions: updated);
  }

  void toggleAllergy(String allergy) {
    final updated = Set<String>.from(state.allergies);
    if (allergy == 'None') {
      updated.clear();
      updated.add('None');
    } else {
      updated.remove('None');
      if (updated.contains(allergy)) {
        updated.remove(allergy);
      } else {
        updated.add(allergy);
      }
    }
    state = state.copyWith(allergies: updated);
  }

  void setGoals({String? primaryGoal, String? activityLevel}) =>
      state = state.copyWith(
        primaryGoal: primaryGoal ?? state.primaryGoal,
        activityLevel: activityLevel ?? state.activityLevel,
      );

  void toggleSecondaryGoal(String goal) {
    final updated = Set<String>.from(state.secondaryGoals);
    if (updated.contains(goal)) {
      updated.remove(goal);
    } else {
      updated.add(goal);
    }
    state = state.copyWith(secondaryGoals: updated);
  }

  void setFitnessRoutine({
    String? experience,
    String? timePerDay,
    String? equipment,
  }) =>
      state = state.copyWith(
        fitnessExperience: experience ?? state.fitnessExperience,
        workoutTimePerDay: timePerDay ?? state.workoutTimePerDay,
        equipment: equipment ?? state.equipment,
      );

  void setNutrition({
    String? dietType,
    Set<String>? avoid,
  }) =>
      state = state.copyWith(
        dietType: dietType ?? state.dietType,
        foodsToAvoid: avoid ?? state.foodsToAvoid,
      );

  void setLocation(String city) => state = state.copyWith(city: city);

  /// Builds a final [User] model from the questionnaire data.
  User buildUser(User baseUser) {
    return baseUser.copyWith(
      name: state.displayName.trim().isNotEmpty
          ? state.displayName.trim()
          : baseUser.name,
      isOnboardingCompleted: true,
      age: state.age,
      dateOfBirth: state.dateOfBirth,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      bloodType: state.bloodType,
      conditions: state.conditions.where((c) => c != 'None').toList(),
      allergies: state.allergies.where((a) => a != 'None').toList(),
      primaryGoal: state.primaryGoal,
      secondaryGoals: state.secondaryGoals.toList(),
      activityLevel: state.activityLevel,
      fitnessExperience: state.fitnessExperience,
      workoutTimePerDay: state.workoutTimePerDay,
      equipment: state.equipment,
      dietType: state.dietType,
      foodPreferences: state.foodPreferences.toList(),
      foodsToAvoid: state.foodsToAvoid.toList(),
      gender: state.gender,
      city: state.city,
    );
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) {
    final user = ref.watch(authNotifierProvider);
    return OnboardingNotifier(user);
  },
);

import 'package:flutter/foundation.dart';

/// Represents an authenticated user of the Zindagi+ platform.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isOnboardingCompleted = false,
    // ── Temporary UI scaffold fields ──────────────────────────────────────────
    // These fields exist solely for local/mock UI rendering and onboarding state.
    // They do NOT represent the final PostgreSQL/Supabase schema.
    // They will be mapped to dedicated backend tables (profiles, goals, allergies,
    // health_metrics) during backend integration.
    this.age,
    this.dateOfBirth,
    this.weightKg,
    this.heightCm,
    this.bloodType,
    this.conditions = const [],
    this.allergies = const [],
    this.primaryGoal,
    this.secondaryGoals = const [],
    this.activityLevel,
    this.fitnessExperience,
    this.workoutTimePerDay,
    this.equipment,
    this.dietType,
    this.foodPreferences = const [],
    this.foodsToAvoid = const [],
    this.photoUrl,
    this.phone,
    this.gender,
    this.city,
  });

  final String id;
  final String name;
  final String email;
  final bool isOnboardingCompleted;

  // ── Personal & Health ───────────────────────────────────────────────────────
  final int? age;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final double? heightCm;
  final String? bloodType;
  final List<String> conditions;
  final List<String> allergies;
  final String? gender;
  final String? city;

  // ── Goals & Fitness ─────────────────────────────────────────────────────────
  final String? primaryGoal;
  final List<String> secondaryGoals;
  final String? activityLevel;
  final String? fitnessExperience;
  final String? workoutTimePerDay;
  final String? equipment;

  // ── Nutrition ───────────────────────────────────────────────────────────────
  final String? dietType;
  final List<String> foodPreferences;
  final List<String> foodsToAvoid;

  // ── Contact / Meta ──────────────────────────────────────────────────────────
  final String? photoUrl;
  final String? phone;

  /// Returns a new [User] with the given fields overridden.
  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isOnboardingCompleted,
    int? age,
    DateTime? dateOfBirth,
    double? weightKg,
    double? heightCm,
    String? bloodType,
    List<String>? conditions,
    List<String>? allergies,
    String? primaryGoal,
    List<String>? secondaryGoals,
    String? activityLevel,
    String? fitnessExperience,
    String? workoutTimePerDay,
    String? equipment,
    String? dietType,
    List<String>? foodPreferences,
    List<String>? foodsToAvoid,
    String? photoUrl,
    String? phone,
    String? gender,
    String? city,
  }) {
    DateTime? effectiveDob = dateOfBirth ?? this.dateOfBirth;
    int? effectiveAge = age ?? this.age;

    if (dateOfBirth == null && age != null && age != this.age && age > 0) {
      final now = DateTime.now();
      if (this.dateOfBirth != null) {
        final birthYear = now.year - age;
        final month = this.dateOfBirth!.month;
        final maxDay = (month == 2 && (birthYear % 4 != 0 || (birthYear % 100 == 0 && birthYear % 400 != 0))) ? 28 : this.dateOfBirth!.day;
        final day = this.dateOfBirth!.day > maxDay ? maxDay : this.dateOfBirth!.day;
        effectiveDob = DateTime(birthYear, month, day);
      } else {
        effectiveDob = DateTime(now.year - age, 1, 1);
      }
    } else if (age == null && dateOfBirth != null && dateOfBirth != this.dateOfBirth) {
      final now = DateTime.now();
      var calculatedAge = now.year - dateOfBirth.year;
      if (now.month < dateOfBirth.month ||
          (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
        calculatedAge--;
      }
      effectiveAge = calculatedAge >= 0 ? calculatedAge : null;
    }

    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      age: effectiveAge,
      dateOfBirth: effectiveDob,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
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
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      city: city ?? this.city,
    );
  }

  /// Creates a [User] from Supabase `public.profiles`, `public.user_goals`,
  /// `public.user_conditions`, and `public.user_allergies` records.
  factory User.fromProfile(
    Map<String, dynamic> map, {
    String? email,
    Map<String, dynamic>? goals,
    List<String>? conditions,
    List<String>? allergies,
  }) {
    DateTime? dob;
    if (map['date_of_birth'] != null) {
      dob = DateTime.tryParse(map['date_of_birth'].toString());
    }

    int? calculatedAge;
    if (dob != null) {
      final now = DateTime.now();
      calculatedAge = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        calculatedAge--;
      }
      if (calculatedAge < 0) calculatedAge = null;
    } else if (map['age'] != null) {
      calculatedAge = (map['age'] as num?)?.toInt();
    }

    return User(
      id: (map['id'] as String?) ?? '',
      name: (map['full_name'] as String?) ?? '',
      email: email ?? '',
      isOnboardingCompleted:
          map['is_onboarding_completed'] as bool? ?? false,
      age: calculatedAge,
      dateOfBirth: dob,
      weightKg: map['weight_kg'] != null
          ? (map['weight_kg'] as num).toDouble()
          : null,
      heightCm: map['height_cm'] != null
          ? (map['height_cm'] as num).toDouble()
          : null,
      bloodType: map['blood_type'] as String?,
      gender: map['gender'] as String?,
      city: map['city'] as String?,
      phone: map['phone'] as String?,
      photoUrl: map['avatar_url'] as String?,
      conditions: conditions ?? const [],
      allergies: allergies ?? const [],
      primaryGoal: goals?['primary_goal'] as String?,
      secondaryGoals: (goals?['secondary_goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      activityLevel: goals?['activity_level'] as String?,
      fitnessExperience: goals?['fitness_experience'] as String?,
      workoutTimePerDay: goals?['workout_time_per_day'] as String?,
      equipment: goals?['equipment'] as String?,
      dietType: goals?['diet_type'] as String?,
      foodPreferences: (goals?['food_preferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      foodsToAvoid: (goals?['foods_to_avoid'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Creates a [User] from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// Serialises the [User] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isOnboardingCompleted': isOnboardingCompleted,
        'photoUrl': photoUrl,
      };

  @override
  String toString() =>
      'User(id: $id, name: $name, email: $email, onboarded: $isOnboardingCompleted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          isOnboardingCompleted == other.isOnboardingCompleted &&
          age == other.age &&
          dateOfBirth == other.dateOfBirth &&
          weightKg == other.weightKg &&
          heightCm == other.heightCm &&
          bloodType == other.bloodType &&
          gender == other.gender &&
          city == other.city &&
          phone == other.phone &&
          photoUrl == other.photoUrl &&
          primaryGoal == other.primaryGoal &&
          activityLevel == other.activityLevel &&
          fitnessExperience == other.fitnessExperience &&
          workoutTimePerDay == other.workoutTimePerDay &&
          equipment == other.equipment &&
          dietType == other.dietType &&
          listEquals(conditions, other.conditions) &&
          listEquals(allergies, other.allergies) &&
          listEquals(secondaryGoals, other.secondaryGoals) &&
          listEquals(foodPreferences, other.foodPreferences) &&
          listEquals(foodsToAvoid, other.foodsToAvoid);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        email,
        isOnboardingCompleted,
        age,
        weightKg,
        heightCm,
        bloodType,
        gender,
        city,
        phone,
        photoUrl,
        primaryGoal,
        activityLevel,
        dietType,
      );
}

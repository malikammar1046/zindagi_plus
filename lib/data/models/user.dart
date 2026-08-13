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
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
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
    );
  }

  /// Serialises the [User] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isOnboardingCompleted': isOnboardingCompleted,
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
          email == other.email;

  @override
  int get hashCode => Object.hash(id, email);
}

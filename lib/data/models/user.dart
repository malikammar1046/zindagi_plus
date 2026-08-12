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

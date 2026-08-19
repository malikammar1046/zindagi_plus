import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:zindagi_plus/core/config/environment.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/interfaces/auth_repository.dart';

/// Real Supabase implementation of [AuthRepository].
class AuthRepositorySupabase implements AuthRepository {
  AuthRepositorySupabase(this._client);

  final supa.SupabaseClient _client;

  @override
  Stream<supa.AuthState>? get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        return const Failure('Authentication failed. No user returned.');
      }

      final user = await _fetchUserProfile(authUser);
      return Success(user);
    } catch (e, st) {
      debugPrint('[AuthRepositorySupabase.login] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }

  @override
  Future<Result<User>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: Environment.authCallbackUrl,
        data: {'full_name': name},
      );

      final authUser = response.user;
      if (authUser == null) {
        return const Failure('Registration failed. No user returned.');
      }

      // If a session was immediately established, fetch profile.
      // Otherwise construct minimal un-onboarded user.
      if (response.session != null) {
        final user = await _fetchUserProfile(authUser);
        return Success(user);
      }

      return Success(User(
        id: authUser.id,
        name: name,
        email: email,
        isOnboardingCompleted: false,
      ));
    } catch (e, st) {
      debugPrint('[AuthRepositorySupabase.register] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        return const Failure('No active session.');
      }

      final user = await _fetchUserProfile(authUser);
      return Success(user);
    } catch (e, st) {
      debugPrint('[AuthRepositorySupabase.getCurrentUser] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } catch (e, st) {
      debugPrint('[AuthRepositorySupabase.logout] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }

  @override
  Future<Result<void>> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: Environment.authCallbackUrl,
      );
      return const Success(null);
    } catch (e, st) {
      debugPrint('[AuthRepositorySupabase.resetPasswordForEmail] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );
      return const Success(null);
    } catch (e, st) {
      debugPrint('[AuthRepositorySupabase.updatePassword] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }

  @override
  Future<Result<void>> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: supa.OtpType.signup,
        email: email,
        emailRedirectTo: Environment.authCallbackUrl,
      );
      return const Success(null);
    } catch (e, st) {
      debugPrint(
          '[AuthRepositorySupabase.resendVerificationEmail] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }


  @override
  Future<Result<User>> verifyOtp({
    required String email,
    required String token,
    supa.OtpType type = supa.OtpType.signup,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );

      final authUser = response.user;
      if (authUser == null) {
        return const Failure('Verification failed. Invalid or expired token.');
      }

      final user = await _fetchUserProfile(authUser);
      return Success(user);
    } catch (e, st) {
      debugPrint('[AuthRepositorySupabase.verifyOtp] Error: $e\n$st');
      return Failure(_mapAuthError(e));
    }
  }

  @override
  Future<Result<User>> completeOnboarding(User user) async {
    final authUser = _client.auth.currentUser;
    final session = _client.auth.currentSession;
    final userId = authUser?.id ?? user.id;

    debugPrint('[AuthRepositorySupabase.completeOnboarding] START');
    debugPrint('[AuthRepositorySupabase.completeOnboarding] authUser.id: ${authUser?.id}');
    debugPrint('[AuthRepositorySupabase.completeOnboarding] session is null?: ${session == null}');
    debugPrint('[AuthRepositorySupabase.completeOnboarding] target userId: $userId');

    if (userId.isEmpty) {
      debugPrint('[AuthRepositorySupabase.completeOnboarding] ERROR: No active session or user ID');
      return const Failure('No active session to complete onboarding.');
    }

    // Calculate ISO date string for date_of_birth
    final dobString = _deriveDobString(user);

    // Normalize blood type to standard ASCII (e.g. 'A-', 'B-')
    String? bloodType = user.bloodType?.replaceAll('−', '-').trim();
    const validBloodTypes = {
      'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'
    };
    if (bloodType != null && !validBloodTypes.contains(bloodType)) {
      bloodType = null;
    }

    // 1. Update public.profiles
    try {
      final profilePayload = {
        'id': userId,
        'full_name': user.name,
        'date_of_birth': dobString,
        'gender': user.gender,
        'height_cm': user.heightCm,
        'weight_kg': user.weightKg,
        'blood_type': bloodType,
        'city': user.city,
        'is_onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 1. Saving public.profiles: $profilePayload');

      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        debugPrint('[AuthRepositorySupabase.completeOnboarding] 1. Updating existing public.profiles');
        await _client.from('profiles').update(profilePayload).eq('id', userId);
      } else {
        debugPrint('[AuthRepositorySupabase.completeOnboarding] 1. Inserting new public.profiles');
        await _client.from('profiles').insert(profilePayload);
      }
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 1. public.profiles SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.profiles save', e, st);
      return Failure(_mapAuthError(e));
    }

    // 2. Save public.user_goals
    try {
      final goalsPayload = {
        'user_id': userId,
        'primary_goal': user.primaryGoal ?? 'Improve overall health',
        'secondary_goals': user.secondaryGoals,
        'activity_level': user.activityLevel ?? 'Lightly active',
        'fitness_experience': user.fitnessExperience ?? 'Beginner',
        'workout_time_per_day': user.workoutTimePerDay ?? '30 minutes',
        'equipment': user.equipment ?? 'Basic home equipment',
        'diet_type': user.dietType ?? 'No specific diet',
        'food_preferences': user.foodPreferences,
        'foods_to_avoid': user.foodsToAvoid,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 2. Saving public.user_goals: $goalsPayload');
      await _client.from('user_goals').upsert(goalsPayload);
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 2. public.user_goals SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.user_goals save', e, st);
      return Failure(_mapAuthError(e));
    }

    // 3. Save public.user_conditions (clear and re-insert)
    try {
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 3. Saving public.user_conditions: ${user.conditions}');
      await _client.from('user_conditions').delete().eq('user_id', userId);
      final validConditions = user.conditions
          .where((c) => c != 'None' && c.trim().isNotEmpty)
          .toSet()
          .toList();
      if (validConditions.isNotEmpty) {
        final conditionsPayload = validConditions
            .map((c) => {'user_id': userId, 'condition_name': c})
            .toList();
        await _client.from('user_conditions').insert(conditionsPayload);
      }
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 3. public.user_conditions SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.user_conditions save', e, st);
      return Failure(_mapAuthError(e));
    }

    // 4. Save public.user_allergies (clear and re-insert)
    try {
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 4. Saving public.user_allergies: ${user.allergies}');
      await _client.from('user_allergies').delete().eq('user_id', userId);
      final validAllergies = user.allergies
          .where((a) => a != 'None' && a.trim().isNotEmpty)
          .toSet()
          .toList();
      if (validAllergies.isNotEmpty) {
        final allergiesPayload = validAllergies
            .map((a) => {
                  'user_id': userId,
                  'allergen_name': a,
                  'severity': 'moderate',
                })
            .toList();
        await _client.from('user_allergies').insert(allergiesPayload);
      }
      debugPrint('[AuthRepositorySupabase.completeOnboarding] 4. public.user_allergies SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.user_allergies save', e, st);
      return Failure(_mapAuthError(e));
    }

    // 5. Build and return the completed User model
    final completedUser = user.copyWith(
      id: userId,
      isOnboardingCompleted: true,
    );

    debugPrint('[AuthRepositorySupabase.completeOnboarding] ALL OPERATIONS COMPLETED SUCCESSFULLY');
    return Success(completedUser);
  }

  /// Converts [user.dateOfBirth] or [user.age] into an ISO 'YYYY-MM-DD' string for public.profiles.
  /// If age is provided, ensures the date_of_birth year matches the requested age.
  String? _deriveDobString(User user) {
    DateTime? calculatedDob = user.dateOfBirth;
    if (user.age != null && user.age! > 0) {
      final now = DateTime.now();
      if (calculatedDob == null) {
        calculatedDob = DateTime(now.year - user.age!, 1, 1);
      } else {
        var dobAge = now.year - calculatedDob.year;
        if (now.month < calculatedDob.month ||
            (now.month == calculatedDob.month && now.day < calculatedDob.day)) {
          dobAge--;
        }
        if (dobAge != user.age) {
          final birthYear = now.year - user.age!;
          final month = calculatedDob.month;
          final maxDay = (month == 2 && (birthYear % 4 != 0 || (birthYear % 100 == 0 && birthYear % 400 != 0))) ? 28 : calculatedDob.day;
          final day = calculatedDob.day > maxDay ? maxDay : calculatedDob.day;
          calculatedDob = DateTime(birthYear, month, day);
        }
      }
    }

    if (calculatedDob == null) return null;
    return '${calculatedDob.year.toString().padLeft(4, '0')}-${calculatedDob.month.toString().padLeft(2, '0')}-${calculatedDob.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<Result<User>> updateProfile(User user) async {
    final authUser = _client.auth.currentUser;
    final userId = authUser?.id ?? user.id;

    debugPrint('[AuthRepositorySupabase.updateProfile] START userId=$userId');

    if (userId.isEmpty) {
      return const Failure('No active session. Please log in again.');
    }

    // Derive date_of_birth from age / dateOfBirth.
    final dobString = _deriveDobString(user);

    // Normalise blood type to ASCII minus sign.
    String? bloodType = user.bloodType?.replaceAll('−', '-').trim();
    const validBloodTypes = {
      'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown',
    };
    if (bloodType != null && !validBloodTypes.contains(bloodType)) {
      bloodType = null;
    }

    // 1. Update public.profiles — preserve is_onboarding_completed and avatar_url.
    try {
      final profilePayload = {
        'full_name': user.name,
        'date_of_birth': dobString,
        'gender': user.gender,
        'height_cm': user.heightCm,
        'weight_kg': user.weightKg,
        'blood_type': bloodType,
        'city': user.city,
        'phone': user.phone,
        if (user.photoUrl != null) 'avatar_url': user.photoUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      debugPrint('[AuthRepositorySupabase.updateProfile] 1. Updating public.profiles: $profilePayload');
      await _client.from('profiles').update(profilePayload).eq('id', userId);
      debugPrint('[AuthRepositorySupabase.updateProfile] 1. public.profiles SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.profiles update', e, st);
      return Failure(_mapAuthError(e));
    }

    // 2. Upsert public.user_goals.
    try {
      final goalsPayload = {
        'user_id': userId,
        'primary_goal': user.primaryGoal ?? 'Improve overall health',
        'secondary_goals': user.secondaryGoals,
        'activity_level': user.activityLevel ?? 'Lightly active',
        'fitness_experience': user.fitnessExperience ?? 'Beginner',
        'workout_time_per_day': user.workoutTimePerDay ?? '30 minutes',
        'equipment': user.equipment ?? 'Basic home equipment',
        'diet_type': user.dietType ?? 'No specific diet',
        'food_preferences': user.foodPreferences,
        'foods_to_avoid': user.foodsToAvoid,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      debugPrint('[AuthRepositorySupabase.updateProfile] 2. Upserting public.user_goals');
      final existingGoal = await _client
          .from('user_goals')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (existingGoal != null) {
        await _client.from('user_goals').update(goalsPayload).eq('user_id', userId);
      } else {
        await _client.from('user_goals').insert(goalsPayload);
      }
      debugPrint('[AuthRepositorySupabase.updateProfile] 2. public.user_goals SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.user_goals upsert', e, st);
      return Failure(_mapAuthError(e));
    }

    // 3. Sync public.user_conditions (delete-and-reinsert).
    try {
      await _client.from('user_conditions').delete().eq('user_id', userId);
      final validConditions = user.conditions
          .where((c) => c != 'None' && c.trim().isNotEmpty)
          .toSet()
          .toList();
      if (validConditions.isNotEmpty) {
        await _client.from('user_conditions').insert(
          validConditions.map((c) => {'user_id': userId, 'condition_name': c}).toList(),
        );
      }
      debugPrint('[AuthRepositorySupabase.updateProfile] 3. public.user_conditions SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.user_conditions sync', e, st);
      return Failure(_mapAuthError(e));
    }

    // 4. Sync public.user_allergies (delete-and-reinsert).
    try {
      await _client.from('user_allergies').delete().eq('user_id', userId);
      final validAllergies = user.allergies
          .where((a) => a != 'None' && a.trim().isNotEmpty)
          .toSet()
          .toList();
      if (validAllergies.isNotEmpty) {
        await _client.from('user_allergies').insert(
          validAllergies.map((a) => {
            'user_id': userId,
            'allergen_name': a,
            'severity': 'moderate',
          }).toList(),
        );
      }
      debugPrint('[AuthRepositorySupabase.updateProfile] 4. public.user_allergies SUCCESS');
    } catch (e, st) {
      _logPostgrestError('public.user_allergies sync', e, st);
      return Failure(_mapAuthError(e));
    }

    // Re-fetch the fresh profile so the notifier gets server-side values.
    try {
      if (authUser != null) {
        final fresh = await _fetchUserProfile(authUser);
        debugPrint('[AuthRepositorySupabase.updateProfile] SUCCESS — returning fresh profile');
        return Success(fresh);
      }
    } catch (e) {
      debugPrint('[AuthRepositorySupabase.updateProfile] Warning: re-fetch failed, returning local copy: $e');
    }

    // Fallback: return the locally-edited user.
    return Success(user.copyWith(id: userId));
  }

  @override
  Future<Result<User>> uploadProfilePhoto(File imageFile) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      return const Failure('No active session. Please log in again.');
    }
    final userId = authUser.id;

    if (!await imageFile.exists()) {
      return const Failure('Selected image file does not exist.');
    }

    try {
      final fileBytes = await imageFile.readAsBytes();
      if (fileBytes.isEmpty) {
        return const Failure('Selected image file is empty.');
      }

      final storagePath = '$userId/profile.jpg';
      debugPrint('[AuthRepositorySupabase.uploadProfilePhoto] Uploading to avatars/$storagePath (${fileBytes.length} bytes)');

      await _client.storage.from('avatars').uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const supa.FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicUrl = '$baseUrl?v=$timestamp';

      debugPrint('[AuthRepositorySupabase.uploadProfilePhoto] Generated publicUrl: $publicUrl');
      debugPrint('[AuthRepositorySupabase.uploadProfilePhoto] Updating public.profiles.avatar_url');

      await _client.from('profiles').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);

      final updatedUser = await _fetchUserProfile(authUser);
      debugPrint('[AuthRepositorySupabase.uploadProfilePhoto] SUCCESS photoUrl=${updatedUser.photoUrl}');
      return Success(updatedUser);
    } catch (e, st) {
      _logPostgrestError('uploadProfilePhoto', e, st);
      return Failure(_mapAuthError(e));
    }
  }

  /// Fetches public.profiles row and associated health data for [authUser] and maps it to a [User].
  Future<User> _fetchUserProfile(supa.User authUser) async {
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (profile != null) {
        Map<String, dynamic>? goals;
        List<String> conditions = [];
        List<String> allergies = [];

        try {
          final goalsRes = await _client
              .from('user_goals')
              .select()
              .eq('user_id', authUser.id)
              .maybeSingle();
          goals = goalsRes;

          final condList = await _client
              .from('user_conditions')
              .select('condition_name')
              .eq('user_id', authUser.id);
          conditions = (condList as List<dynamic>)
              .map((e) => e['condition_name'].toString())
              .toList();

          final allergList = await _client
              .from('user_allergies')
              .select('allergen_name')
              .eq('user_id', authUser.id);
          allergies = (allergList as List<dynamic>)
              .map((e) => e['allergen_name'].toString())
              .toList();
        } catch (e) {
          debugPrint(
              '[AuthRepositorySupabase._fetchUserProfile] Extra profile tables warning: $e');
        }

        final rawAvatar = profile['avatar_url'] as String?;
        String? resolvedAvatarUrl = rawAvatar;
        if (rawAvatar != null &&
            rawAvatar.isNotEmpty &&
            !rawAvatar.startsWith('http://') &&
            !rawAvatar.startsWith('https://')) {
          resolvedAvatarUrl =
              _client.storage.from('avatars').getPublicUrl(rawAvatar);
        }

        final enrichedProfile = Map<String, dynamic>.from(profile);
        if (resolvedAvatarUrl != null) {
          enrichedProfile['avatar_url'] = resolvedAvatarUrl;
        }

        return User.fromProfile(
          enrichedProfile,
          email: authUser.email,
          goals: goals,
          conditions: conditions,
          allergies: allergies,
        );
      }
    } catch (e) {
      debugPrint(
          '[AuthRepositorySupabase._fetchUserProfile] Profile fetch warning: $e');
    }

    // Fallback if profile row is not yet queryable or trigger is pending
    final metaName = authUser.userMetadata?['full_name'] as String? ??
        authUser.userMetadata?['name'] as String? ??
        'User';

    return User(
      id: authUser.id,
      name: metaName,
      email: authUser.email ?? '',
      isOnboardingCompleted: false,
    );
  }

  void _logPostgrestError(String operation, Object error, StackTrace st) {
    if (error is supa.PostgrestException) {
      debugPrint('================================================================');
      debugPrint('[SUPABASE ERROR] Operation "$operation" FAILED:');
      debugPrint('  Message: ${error.message}');
      debugPrint('  Code:    ${error.code}');
      debugPrint('  Details: ${error.details}');
      debugPrint('  Hint:    ${error.hint}');
      debugPrint('================================================================');
    } else if (error is supa.AuthException) {
      debugPrint('================================================================');
      debugPrint('[SUPABASE AUTH ERROR] Operation "$operation" FAILED:');
      debugPrint('  Message:    ${error.message}');
      debugPrint('  StatusCode: ${error.statusCode}');
      debugPrint('================================================================');
    } else {
      debugPrint('================================================================');
      debugPrint('[ERROR] Operation "$operation" FAILED: $error\n$st');
      debugPrint('================================================================');
    }
  }

  /// Maps Supabase and network exceptions to clear, user-friendly messages.
  String _mapAuthError(Object error) {
    if (error is supa.PostgrestException) {
      debugPrint('[AuthRepositorySupabase._mapAuthError] PostgrestException: code=${error.code}, message=${error.message}, details=${error.details}, hint=${error.hint}');
      final hint = error.hint != null && error.hint!.isNotEmpty ? ' (${error.hint})' : '';
      final details = error.details != null && error.details.toString().isNotEmpty ? ' Details: ${error.details}' : '';
      return '${error.message}$hint$details';
    }

    if (error is supa.AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials') ||
          msg.contains('invalid username or password')) {
        return 'Invalid email or password. Please check your credentials.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('email already in use') ||
          msg.contains('user with this email already exists')) {
        return 'An account with this email already exists.';
      }
      if (msg.contains('email not confirmed') ||
          msg.contains('email_not_confirmed')) {
        return 'Please verify your email address before signing in.';
      }
      if (msg.contains('password should be at least') ||
          msg.contains('weak password') ||
          msg.contains('password is too weak')) {
        return 'Password is too weak. Please choose a stronger password.';
      }
      if (msg.contains('rate limit') ||
          msg.contains('too many requests') ||
          msg.contains('over_email_send_rate_limit')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (msg.contains('invalid email') ||
          msg.contains('format is invalid') ||
          msg.contains('unable to validate email')) {
        return 'Please enter a valid email address.';
      }
      if (msg.contains('otp expired') ||
          msg.contains('token has expired') ||
          msg.contains('invalid token')) {
        return 'The verification code is invalid or has expired.';
      }
      return error.message;
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('clientexception')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    return 'An unexpected authentication error occurred. Please try again.';
  }
}

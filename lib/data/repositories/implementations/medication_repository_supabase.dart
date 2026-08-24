import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/data/repositories/interfaces/medication_repository.dart';

/// Real Supabase implementation of [MedicationRepository].
///
/// All database operations require an active, valid Supabase authentication session.
/// Queries are strictly scoped to `auth.uid()` both via Postgres Row Level Security (RLS)
/// and explicit `.eq('user_id', authenticatedUserId)` query filters.
///
/// [getMedications] is strictly read-only and derives today's UI status using the
/// 30-minute grace period rule.
///
/// Missed-dose database records are created exclusively inside [reconcileMissedDoses].
class MedicationRepositorySupabase implements MedicationRepository {
  MedicationRepositorySupabase(this._client);

  final supa.SupabaseClient _client;

  // ── Authentication & Diagnostic Validation ──────────────────────────────────

  Result<String> _validateAuth(
    String operation,
    String table,
  ) {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;

    debugPrint('[MedicationRepo.$operation] table=$table userId=${user?.id} hasSession=${session != null}');

    if (session == null || user == null || user.id.isEmpty) {
      debugPrint(
        '[MedicationRepositorySupabase.$operation] BLOCKED: No active Supabase session or user ID is null.',
      );
      return const Failure('Not authenticated. Please log in.');
    }

    if (session.isExpired) {
      debugPrint(
        '[MedicationRepositorySupabase.$operation] BLOCKED: Supabase session is expired.',
      );
      return const Failure('Session expired. Please log in again.');
    }

    return Success(user.id);
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Medication>>> getMedications() async {
    final authCheck = _validateAuth('getMedications', 'medications');
    if (authCheck is Failure<String>) {
      return Failure(authCheck.message);
    }
    final authenticatedUserId = (authCheck as Success<String>).data;

    try {
      // 1. Fetch all medications for this user (both active and inactive).
      final rows = await _client
          .from('medications')
          .select()
          .eq('user_id', authenticatedUserId)
          .order('created_at', ascending: true);

      // 2. Fetch today's dose logs in local date window.
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day)
          .toUtc()
          .toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day + 1)
          .toUtc()
          .toIso8601String();

      final todayLogs = await _client
          .from('medication_dose_logs')
          .select('medication_id, status, logged_at')
          .eq('user_id', authenticatedUserId)
          .gte('logged_at', todayStart)
          .lt('logged_at', todayEnd)
          .order('logged_at', ascending: false);

      // Build map of medicationId -> logged status
      final Map<String, MedStatus> loggedStatusMap = {};
      for (final log in (todayLogs as List<dynamic>)) {
        final medId = log['medication_id'] as String?;
        if (medId != null && !loggedStatusMap.containsKey(medId)) {
          final raw = log['status'] as String? ?? 'missed';
          loggedStatusMap[medId] =
              raw == 'taken' ? MedStatus.taken : MedStatus.missed;
        }
      }

      // 3. Derive status using pure helper (30-minute grace period rule)
      final medications = (rows as List<dynamic>).map((row) {
        final map = row as Map<String, dynamic>;
        final medId = map['id'] as String? ?? '';
        final loggedStatus = loggedStatusMap[medId];

        // Parse scheduled time
        final rawTimeOfDay = map['scheduled_time_of_day'] as String?;
        final timeStr = (map['schedule_time'] as String?) ?? '';
        final timeOfDay = (rawTimeOfDay != null && rawTimeOfDay.isNotEmpty)
            ? Medication.parseTimeString(rawTimeOfDay)
            : Medication.parseTimeOfDay(timeStr);

        final derivedStatus = Medication.deriveStatus(
          scheduledTime: timeOfDay,
          loggedStatus: loggedStatus,
          now: now,
        );

        return Medication.fromSupabase(map, todayStatus: derivedStatus);
      }).toList();

      return Success(medications);
    } catch (e, st) {
      _logError('getMedications', e, st);
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<List<DoseLog>>> getDoseHistory() async {
    final authCheck = _validateAuth('getDoseHistory', 'medication_dose_logs');
    if (authCheck is Failure<String>) {
      return Failure(authCheck.message);
    }
    final authenticatedUserId = (authCheck as Success<String>).data;

    try {
      // Join with medications to get name + dose + scheduled_time for display.
      final rows = await _client
          .from('medication_dose_logs')
          .select('*, medications(name, dose, schedule_time)')
          .eq('user_id', authenticatedUserId)
          .order('logged_at', ascending: false)
          .limit(200);

      final logs = (rows as List<dynamic>)
          .map((row) => DoseLog.fromSupabase(row as Map<String, dynamic>))
          .toList();

      return Success(logs);
    } catch (e, st) {
      _logError('getDoseHistory', e, st);
      return Failure(_mapError(e));
    }
  }

  // ── Write ────────────────────────────────────────────────────────────────────

  @override
  Future<Result<Medication>> addMedication(Medication medication) async {
    final authCheck = _validateAuth('addMedication', 'medications');
    if (authCheck is Failure<String>) {
      return Failure(authCheck.message);
    }
    final authenticatedUserId = (authCheck as Success<String>).data;

    try {
      final payload = medication.toSupabase(authenticatedUserId);
      debugPrint(
        '[MedicationRepositorySupabase.addMedication] Inserting medication for user_id=$authenticatedUserId',
      );

      final row = await _client
          .from('medications')
          .insert(payload)
          .select()
          .single();

      final saved = Medication.fromSupabase(
        row,
        todayStatus: MedStatus.pending,
      );
      debugPrint('[MedicationRepositorySupabase.addMedication] Successfully added: ${saved.id}');
      return Success(saved);
    } catch (e, st) {
      _logError('addMedication', e, st);
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> deleteMedication(String id) async {
    final authCheck = _validateAuth('deleteMedication', 'medications');
    if (authCheck is Failure<String>) {
      return Failure(authCheck.message);
    }
    final authenticatedUserId = (authCheck as Success<String>).data;

    try {
      // Soft-delete: set is_active = false. Preserves record for history.
      await _client
          .from('medications')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', authenticatedUserId);
      debugPrint('[MedicationRepositorySupabase.deleteMedication] Soft-deleted: $id');
      return const Success(null);
    } catch (e, st) {
      _logError('deleteMedication', e, st);
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<DoseLog>> logDose(String medicationId, MedStatus status) async {
    final authCheck = _validateAuth('logDose', 'medication_dose_logs');
    if (authCheck is Failure<String>) {
      return Failure(authCheck.message);
    }
    final authenticatedUserId = (authCheck as Success<String>).data;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();

    try {
      // 1. Fetch medication details
      final medRow = await _client
          .from('medications')
          .select('name, dose, schedule_time')
          .eq('id', medicationId)
          .eq('user_id', authenticatedUserId)
          .maybeSingle();

      final medName = (medRow?['name'] as String?) ?? 'Unknown';
      final medDose = (medRow?['dose'] as String?) ?? '';
      final medScheduleTime = medRow?['schedule_time'] as String?;

      // 2. Remove existing dose log for today to ensure idempotent state
      await _client
          .from('medication_dose_logs')
          .delete()
          .eq('medication_id', medicationId)
          .eq('user_id', authenticatedUserId)
          .gte('logged_at', todayStart)
          .lt('logged_at', todayEnd);

      if (status == MedStatus.pending) {
        return Success(DoseLog(
          medicationId: medicationId,
          medicationName: medName,
          dose: medDose,
          scheduledTime: medScheduleTime,
          status: MedStatus.pending,
          loggedAt: now,
        ));
      }

      // 3. Insert new log for taken or missed
      final statusStr = status == MedStatus.taken ? 'taken' : 'missed';
      final payload = {
        'medication_id': medicationId,
        'user_id': authenticatedUserId,
        'status': statusStr,
        'logged_at': now.toUtc().toIso8601String(),
      };
      await _client.from('medication_dose_logs').insert(payload);

      final log = DoseLog(
        medicationId: medicationId,
        medicationName: medName,
        dose: medDose,
        scheduledTime: medScheduleTime,
        status: status,
        loggedAt: now,
      );
      return Success(log);
    } catch (e, st) {
      _logError('logDose', e, st);
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<int>> reconcileMissedDoses() async {
    final authCheck = _validateAuth('reconcileMissedDoses', 'medication_dose_logs');
    if (authCheck is Failure<String>) {
      return Failure(authCheck.message);
    }
    final authenticatedUserId = (authCheck as Success<String>).data;

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day)
          .toUtc()
          .toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day + 1)
          .toUtc()
          .toIso8601String();

      // 1. Fetch active medications only
      final activeMedRows = await _client
          .from('medications')
          .select()
          .eq('user_id', authenticatedUserId)
          .eq('is_active', true);

      // 2. Fetch all of today's dose logs to check for existing entries
      final todayLogs = await _client
          .from('medication_dose_logs')
          .select('medication_id')
          .eq('user_id', authenticatedUserId)
          .gte('logged_at', todayStart)
          .lt('logged_at', todayEnd);

      final existingLoggedMedIds = (todayLogs as List<dynamic>)
          .map((l) => l['medication_id'] as String?)
          .whereType<String>()
          .toSet();

      int newlyPersistedMissedCount = 0;

      for (final row in (activeMedRows as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final medId = map['id'] as String?;
        if (medId == null || existingLoggedMedIds.contains(medId)) {
          // Already has a taken or missed record for today
          continue;
        }

        // Parse scheduled time
        final rawTimeOfDay = map['scheduled_time_of_day'] as String?;
        final timeStr = (map['schedule_time'] as String?) ?? '';
        final timeOfDay = (rawTimeOfDay != null && rawTimeOfDay.isNotEmpty)
            ? Medication.parseTimeString(rawTimeOfDay)
            : Medication.parseTimeOfDay(timeStr);

        if (timeOfDay == null) continue;

        final scheduledToday = DateTime(
          now.year,
          now.month,
          now.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        final gracePeriodEnd = scheduledToday.add(const Duration(minutes: 30));

        // If current time is strictly after the 30-minute grace period and no record exists:
        if (now.isAfter(gracePeriodEnd)) {
          final payload = {
            'medication_id': medId,
            'user_id': authenticatedUserId,
            'status': 'missed',
            'logged_at': gracePeriodEnd.toUtc().toIso8601String(),
          };

          await _client.from('medication_dose_logs').insert(payload);
          existingLoggedMedIds.add(medId);
          newlyPersistedMissedCount++;
          debugPrint(
            '[MedicationRepositorySupabase.reconcileMissedDoses] Recorded missed dose for medId=$medId (grace period expired at $gracePeriodEnd)',
          );
        }
      }

      debugPrint(
        '[MedicationRepositorySupabase.reconcileMissedDoses] Reconciled. New missed doses: $newlyPersistedMissedCount',
      );
      return Success(newlyPersistedMissedCount);
    } catch (e, st) {
      _logError('reconcileMissedDoses', e, st);
      return Failure(_mapError(e));
    }
  }

  // ── Error Handling & Logging ──────────────────────────────────────────────────

  void _logError(String operation, Object error, StackTrace st) {
    if (error is supa.PostgrestException) {
      debugPrint('[MedicationRepositorySupabase.$operation] PostgrestException:');
      debugPrint('  - Code: ${error.code}');
      debugPrint('  - Message: ${error.message}');
      debugPrint('  - Details: ${error.details}');
      debugPrint('  - Hint: ${error.hint}');
    } else {
      debugPrint('[MedicationRepositorySupabase.$operation] Error: $error\n$st');
    }
  }

  String _mapError(Object error) {
    if (error is supa.PostgrestException) {
      return 'Database error: ${error.message}';
    }
    final s = error.toString().toLowerCase();
    if (s.contains('socket') || s.contains('connection') || s.contains('network')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

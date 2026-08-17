import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';

/// Contract for the medication data layer.
///
/// Swap implementations (mock ↔ API) via the Riverpod provider in
/// `lib/providers/repository_providers.dart` without touching business logic.
abstract class MedicationRepository {
  /// Returns the user's full medication list (both active and inactive).
  ///
  /// This method is strictly read-only: it derives the UI status for today's doses
  /// based on existing dose logs and the 30-minute grace period without writing to the database.
  Future<Result<List<Medication>>> getMedications();

  /// Adds a new [medication] to the user's schedule.
  Future<Result<Medication>> addMedication(Medication medication);

  /// Soft-deletes a medication by setting `is_active = false`.
  ///
  /// Preserves the record (and its dose logs) for history and analytics.
  Future<Result<void>> deleteMedication(String id);

  /// Logs a dose action (taken/missed) for [medicationId] with the given [status].
  Future<Result<DoseLog>> logDose(String medicationId, MedStatus status);

  /// Returns the full dose history log, newest first.
  Future<Result<List<DoseLog>>> getDoseHistory();

  /// Reconciles today's active scheduled medications against the current local time.
  ///
  /// For any active medication where:
  /// 1. Current local time is >= (scheduled time + 30-minute grace period), AND
  /// 2. No dose log (taken or missed) has been recorded yet for today,
  ///
  /// this method persists a `missed` dose log in `public.medication_dose_logs`.
  /// Returns the number of newly created missed dose logs.
  Future<Result<int>> reconcileMissedDoses();
}

import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';

/// Contract for the medication data layer.
///
/// Swap implementations (mock ↔ API) via the Riverpod provider in
/// `lib/providers/repository_providers.dart` without touching business logic.
abstract class MedicationRepository {
  /// Returns the user's full medication schedule.
  Future<Result<List<Medication>>> getMedications();

  /// Adds a new [medication] to the user's schedule.
  Future<Result<Medication>> addMedication(Medication medication);

  /// Logs a dose action (taken/missed) for [medicationId] with the given [status].
  Future<Result<DoseLog>> logDose(String medicationId, MedStatus status);

  /// Returns the full dose history log, newest first.
  Future<Result<List<DoseLog>>> getDoseHistory();
}

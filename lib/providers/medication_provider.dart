import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

// ── Medication state notifier ─────────────────────────────────────────────────

/// Manages the in-memory medication list.
///
/// All mutations go through [MedicationRepository] so swapping mock → real API
/// requires zero changes to the notifier logic.
class MedicationNotifier extends StateNotifier<List<Medication>> {
  MedicationNotifier(this._ref) : super([]) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final result =
        await _ref.read(medicationRepositoryProvider).getMedications();
    switch (result) {
      case Success(data: final meds):
        state = List.from(meds);
      case Failure():
        break;
    }
  }

  /// Cycles the status of the medication at [index]:
  /// pending → taken → missed → pending
  void toggleStatus(int index) {
    final updated = List<Medication>.from(state);
    final m = updated[index];
    final nextStatus = switch (m.status) {
      MedStatus.pending => MedStatus.taken,
      MedStatus.taken => MedStatus.missed,
      MedStatus.missed => MedStatus.pending,
    };
    updated[index] = m.copyWith(status: nextStatus);
    state = updated;

    // Fire-and-forget log (no UI update needed from response).
    _ref.read(medicationRepositoryProvider).logDose(m.id, nextStatus);
  }

  /// Adds a new medication both locally and via the repository.
  Future<void> addMedication(Medication medication) async {
    final result = await _ref
        .read(medicationRepositoryProvider)
        .addMedication(medication);
    switch (result) {
      case Success(data: final med):
        state = [...state, med];
      case Failure():
        break;
    }
  }

  int get takenCount =>
      state.where((m) => m.status == MedStatus.taken).length;
  int get totalCount => state.length;

  double get adherence =>
      totalCount == 0 ? 0 : takenCount / totalCount;
}

/// Provides the live medication list.
final medicationProvider =
    StateNotifierProvider<MedicationNotifier, List<Medication>>(
  (ref) => MedicationNotifier(ref),
);

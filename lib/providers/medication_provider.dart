import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/services/notification_service.dart';

// ── Medication state notifier ─────────────────────────────────────────────────

/// Manages the in-memory medication list, reminders, and missed-dose reconciliation.
///
/// All mutations go through [MedicationRepository] so swapping mock ↔ real API
/// requires zero changes to the notifier logic.
///
/// The list contains ALL medications (active + inactive) as returned by the
/// repository. The UI filters on [Medication.isActive] where needed.
class MedicationNotifier extends StateNotifier<AsyncValue<List<Medication>>> {
  MedicationNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  void _init() {
    // Listen to authentication state changes so we load medications as soon
    // as the session is established, and clear when logged out.
    _ref.listen<User?>(authNotifierProvider, (previous, next) {
      if (next != null) {
        _load();
      } else {
        state = const AsyncValue.data([]);
      }
    });

    final currentUser = _ref.read(authNotifierProvider);
    if (currentUser != null) {
      _load();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _load() async {
    final currentUser = _ref.read(authNotifierProvider);
    if (currentUser == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    // 1. Reconcile any past-due doses whose 30-min grace period expired
    try {
      await _ref.read(medicationRepositoryProvider).reconcileMissedDoses();
    } catch (e) {
      debugPrint('[MedicationNotifier] reconcileMissedDoses error: $e');
    }

    // 2. Read refreshed medication list (read-only)
    final result =
        await _ref.read(medicationRepositoryProvider).getMedications();
    switch (result) {
      case Success(data: final meds):
        state = AsyncValue.data(List.from(meds));
        // 3. Sync local notifications for active medications
        final active = meds.where((m) => m.isActive).toList();
        NotificationService.instance.rescheduleAll(active);
      case Failure(message: final msg):
        state = AsyncValue.error(msg, StackTrace.current);
    }
  }

  /// Reloads medication data from the repository and checks for missed doses.
  Future<void> refresh() => _load();

  /// Reconciles missed doses without full reload spinner, updating state seamlessly.
  Future<void> reconcileMissedDoses() async {
    final currentUser = _ref.read(authNotifierProvider);
    if (currentUser == null) return;

    final reconcileRes =
        await _ref.read(medicationRepositoryProvider).reconcileMissedDoses();
    if (reconcileRes is Success<int> && reconcileRes.data > 0) {
      // Refresh list to update status badges if new missed doses were recorded
      final result =
          await _ref.read(medicationRepositoryProvider).getMedications();
      if (result is Success<List<Medication>>) {
        state = AsyncValue.data(List.from(result.data));
      }
    }
  }

  // ── Derived helpers (operate on current data if available) ───────────────────

  List<Medication> get _meds =>
      state.whenData((m) => m).value ?? const [];

  /// Active medications only.
  List<Medication> get activeMedications =>
      _meds.where((m) => m.isActive).toList();

  int get takenCount =>
      activeMedications.where((m) => m.status == MedStatus.taken).length;

  int get totalCount => activeMedications.length;

  double get adherence => totalCount == 0 ? 0 : takenCount / totalCount;

  // ── Mutations ────────────────────────────────────────────────────────────────

  /// Cycles the status of the medication at [index] in the ACTIVE list:
  /// pending → taken → missed → pending.
  ///
  /// If the new status is not [MedStatus.pending], it is persisted via
  /// [MedicationRepository.logDose].
  void toggleStatus(int index) {
    final active = activeMedications;
    if (index < 0 || index >= active.length) return;
    final m = active[index];
    final nextStatus = switch (m.status) {
      MedStatus.pending => MedStatus.taken,
      MedStatus.taken => MedStatus.missed,
      MedStatus.missed => MedStatus.pending,
    };

    // Optimistic local update.
    final allMeds = List<Medication>.from(_meds);
    final globalIndex = allMeds.indexWhere((med) => med.id == m.id);
    if (globalIndex != -1) {
      allMeds[globalIndex] = m.copyWith(status: nextStatus);
      state = AsyncValue.data(allMeds);
    }

    // Persist non-pending statuses to the dose log.
    if (nextStatus != MedStatus.pending) {
      _ref
          .read(medicationRepositoryProvider)
          .logDose(m.id, nextStatus);
    }
  }

  /// Adds a new medication both locally, in the repository, and schedules its reminder.
  Future<Result<void>> addMedication(Medication medication) async {
    final result = await _ref
        .read(medicationRepositoryProvider)
        .addMedication(medication);
    switch (result) {
      case Success(data: final saved):
        final updated = List<Medication>.from(_meds)..add(saved);
        state = AsyncValue.data(updated);
        // Schedule local reminder for the new medication
        await NotificationService.instance.scheduleMedicationReminder(saved);
        return const Success(null);
      case Failure(message: final msg):
        return Failure(msg);
    }
  }

  /// Soft-deletes [medicationId] via the repository, cancels its reminder, and updates local state.
  Future<Result<void>> deleteMedication(String medicationId) async {
    final result = await _ref
        .read(medicationRepositoryProvider)
        .deleteMedication(medicationId);
    switch (result) {
      case Success():
        final updated = _meds
            .map((m) => m.id == medicationId ? m.copyWith(isActive: false) : m)
            .toList();
        state = AsyncValue.data(updated);
        // Cancel reminder for the deleted medication
        await NotificationService.instance.cancelMedicationReminder(medicationId);
        return const Success(null);
      case Failure(message: final msg):
        return Failure(msg);
    }
  }
}

/// Provides the live medication list as [AsyncValue].
final medicationProvider =
    StateNotifierProvider<MedicationNotifier, AsyncValue<List<Medication>>>(
  (ref) => MedicationNotifier(ref),
);

import 'dart:async';
import 'package:flutter/widgets.dart';
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
  MedicationNotifier(this._ref, {bool autoInit = true})
      : super(const AsyncValue.loading()) {
    _ref.onDispose(_stopTicker);
    if (autoInit) {
      _init();
    }
  }

  final Ref _ref;
  Timer? _boundaryTimer;
  Future<void>? _loadFuture;
  bool _isReconciling = false;
  bool _isReschedulingNotifications = false;
  DateTime? _lastReconcileTime;
  static const Duration _reconcileThrottle = Duration(minutes: 15);

  void _init() {
    debugPrint('[MEDICATION-01] MedicationNotifier._init()');
    // Listen to authentication state changes so we load medications as soon
    // as the session is established, and clear when logged out.
    _ref.listen<User?>(authNotifierProvider, (previous, next) {
      debugPrint('[MEDICATION-02] authNotifierProvider changed: previous=${previous?.name}, next=${next?.name}');
      if (next != null) {
        _load();
      } else {
        _stopTicker();
        state = const AsyncValue.data([]);
      }
    });

    final currentUser = _ref.read(authNotifierProvider);
    if (currentUser != null) {
      debugPrint('[MEDICATION-03] currentUser is present, calling _load()');
      _load();
    } else {
      debugPrint('[MEDICATION-03] currentUser is null, state = []');
      state = const AsyncValue.data([]);
    }
  }

  /// Calculates the exact moment when the nearest pending medication's 30-minute
  /// grace period will expire today, and schedules a single-shot timer for that moment.
  void _scheduleNextBoundaryTimer() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;

    final list = _meds;
    if (list.isEmpty) return;

    final now = DateTime.now();
    DateTime? earliestExpiration;

    for (final med in list) {
      if (med.isActive && med.status == MedStatus.pending) {
        final time = med.parsedTimeOfDay;
        if (time != null) {
          final scheduledToday = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );
          final gracePeriodEnd = scheduledToday.add(const Duration(minutes: 30));
          if (gracePeriodEnd.isAfter(now)) {
            if (earliestExpiration == null || gracePeriodEnd.isBefore(earliestExpiration)) {
              earliestExpiration = gracePeriodEnd;
            }
          }
        }
      }
    }

    if (earliestExpiration != null) {
      final delay = earliestExpiration.difference(now) + const Duration(seconds: 1);
      debugPrint(
        '[MEDICATION-04] Scheduling next missed-dose boundary check in ${delay.inMinutes}m ${delay.inSeconds % 60}s (at $earliestExpiration)',
      );
      _boundaryTimer = Timer(delay, () async {
        await reconcileMissedDoses();
        _scheduleNextBoundaryTimer();
      });
    }
  }

  void _stopTicker() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
  }

  Future<void> _load() {
    return _loadFuture ??= _performLoad();
  }

  Future<void> _performLoad() async {
    final sw = Stopwatch()..start();
    debugPrint('[TRACE] MedicationNotifier._performLoad START');
    try {
      final currentUser = _ref.read(authNotifierProvider);
      if (currentUser == null) {
        debugPrint('[MEDICATION-05] _load(): no authenticated user');
        state = const AsyncValue.data([]);
        return;
      }

      debugPrint('[MEDICATION-05] _load() starting for user ${currentUser.id}');
      state = const AsyncValue.loading();

      // 1. Reconcile any past-due doses whose 30-min grace period expired
      try {
        debugPrint('[MEDICATION-06] calling reconcileMissedDoses() from _load()');
        await _ref.read(medicationRepositoryProvider).reconcileMissedDoses();
      } catch (e) {
        debugPrint('[MedicationNotifier] reconcileMissedDoses error: $e');
      }

      // 2. Read refreshed medication list (read-only)
      debugPrint('[MEDICATION-07] fetching getMedications() from repo');
      final result =
          await _ref.read(medicationRepositoryProvider).getMedications();
      switch (result) {
        case Success(data: final meds):
          debugPrint('[MEDICATION-08] getMedications() success: ${meds.length} medications found');
          state = AsyncValue.data(List.from(meds));
          _scheduleNextBoundaryTimer();
          // 3. Defer local notification syncing until after first frame paint
          final active = meds.where((m) => m.isActive).toList();
          _deferRescheduleNotifications(active);
        case Failure(message: final msg):
          debugPrint('[MEDICATION-08] getMedications() failure: $msg');
          state = AsyncValue.error(msg, StackTrace.current);
      }
    } finally {
      _loadFuture = null;
      sw.stop();
      debugPrint('[TRACE] MedicationNotifier._performLoad END duration=${sw.elapsedMilliseconds}ms');
    }
  }

  /// Schedules local notifications asynchronously after the current frame is painted,
  /// preventing startup frame drops and duplicate concurrent scheduling.
  void _deferRescheduleNotifications(List<Medication> activeMeds) {
    if (_isReschedulingNotifications) {
      debugPrint(
        '[MEDICATION-NOTIF] Reschedule already in progress — skipping duplicate trigger.',
      );
      return;
    }
    _isReschedulingNotifications = true;

    void runReschedule() async {
      try {
        debugPrint(
          '[MEDICATION-NOTIF] Executing deferred NotificationService.rescheduleAll (${activeMeds.length} active meds)',
        );
        await NotificationService.instance.rescheduleAll(activeMeds);
      } catch (e, st) {
        debugPrint(
          '[MEDICATION-NOTIF] Non-fatal notification reschedule error: $e\n$st',
        );
      } finally {
        _isReschedulingNotifications = false;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      runReschedule();
    });
  }

  /// Reloads medication data from the repository and checks for missed doses.
  Future<void> refresh() => _load();

  /// Reconciles missed doses without full reload spinner, updating state seamlessly.
  /// Throttled to at most once every 15 minutes unless [force] is true.
  Future<void> reconcileMissedDoses({bool force = false}) async {
    if (!force && _lastReconcileTime != null) {
      final elapsed = DateTime.now().difference(_lastReconcileTime!);
      if (elapsed < _reconcileThrottle) {
        debugPrint(
          '[MEDICATION-RECONCILE] skipped — throttled (${elapsed.inMinutes}m elapsed since last run)',
        );
        return;
      }
    }

    if (_isReconciling) {
      debugPrint('[MEDICATION-RECONCILE] skipped — already reconciling');
      return;
    }
    _isReconciling = true;
    _lastReconcileTime = DateTime.now();
    final sw = Stopwatch()..start();
    debugPrint('[TRACE] MedicationNotifier.reconcileMissedDoses START');

    try {
      final currentUser = _ref.read(authNotifierProvider);
      if (currentUser == null) return;

      debugPrint('[MEDICATION-RECONCILE] starting reconcileMissedDoses()');
      final reconcileRes =
          await _ref.read(medicationRepositoryProvider).reconcileMissedDoses();
      if (reconcileRes is Success<int> && reconcileRes.data > 0) {
        debugPrint('[MEDICATION-RECONCILE] newly reconciled ${reconcileRes.data} missed doses, refreshing list');
        // Refresh list to update status badges if new missed doses were recorded
        final result =
            await _ref.read(medicationRepositoryProvider).getMedications();
        if (result is Success<List<Medication>>) {
          state = AsyncValue.data(List.from(result.data));
        }
      }
      _scheduleNextBoundaryTimer();
    } finally {
      _isReconciling = false;
      sw.stop();
      debugPrint('[TRACE] MedicationNotifier.reconcileMissedDoses END duration=${sw.elapsedMilliseconds}ms');
    }
  }

  // ── Derived helpers (operate on current data if available) ───────────────────

  List<Medication> get _meds =>
      state.whenData((m) => m).value ?? const [];

  /// Active medications only.
  List<Medication> get activeMedications =>
      _meds.where((m) => m.isActive).toList();

  /// Inactive / discontinued medications.
  List<Medication> get inactiveMedications =>
      _meds.where((m) => !m.isActive).toList();

  int get takenCount =>
      activeMedications.where((m) => m.status == MedStatus.taken).length;

  int get missedCount =>
      activeMedications.where((m) => m.status == MedStatus.missed).length;

  int get pendingCount =>
      activeMedications.where((m) => m.status == MedStatus.pending).length;

  int get totalCount => activeMedications.length;

  /// Total completed/due doses for today (taken + missed).
  int get dueCount => takenCount + missedCount;

  /// Adherence is computed as: taken / (taken + missed) for completed/due doses.
  /// Future pending doses are excluded from the denominator.
  /// If no doses are due yet today (dueCount == 0), returns 1.0 (100% adherence, 0 missed).
  double get adherence =>
      dueCount == 0 ? 1.0 : (takenCount / dueCount).clamp(0.0, 1.0);

  // ── Mutations ────────────────────────────────────────────────────────────────

  /// Transitions dose status according to clinical state machine:
  /// - pending → taken (user takes dose on time)
  /// - missed → taken (user takes dose late, preserving taken state)
  /// - taken → restored status (pending if within grace period, missed if grace period expired)
  ///
  /// Optimistically updates local UI state, awaits [MedicationRepository.logDose],
  /// and automatically rolls back to the previous state if the mutation fails.
  Future<Result<void>> toggleStatus(int index) async {
    final active = activeMedications;
    if (index < 0 || index >= active.length) {
      return const Failure('Invalid medication selection.');
    }
    final m = active[index];
    final now = DateTime.now();

    final nextStatus = switch (m.status) {
      MedStatus.pending => MedStatus.taken,
      MedStatus.missed => MedStatus.taken, // User takes dose late -> moves to taken!
      MedStatus.taken => Medication.calculateRestoredStatus(
          scheduledTime: m.parsedTimeOfDay,
          now: now,
        ), // Undo -> restores to pending (if in grace period) or missed (if grace period elapsed)
    };

    // Store previous snapshot for rollback
    final previousMeds = List<Medication>.from(_meds);

    // Optimistic local update
    final allMeds = List<Medication>.from(_meds);
    final globalIndex = allMeds.indexWhere((med) => med.id == m.id);
    if (globalIndex != -1) {
      allMeds[globalIndex] = m.copyWith(status: nextStatus);
      state = AsyncValue.data(allMeds);
    }

    // Persist status change to repository
    final result = await _ref
        .read(medicationRepositoryProvider)
        .logDose(m.id, nextStatus);

    switch (result) {
      case Success():
        _scheduleNextBoundaryTimer();
        return const Success(null);
      case Failure(message: final msg):
        // Rollback on failure
        state = AsyncValue.data(previousMeds);
        return Failure(msg);
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
        _scheduleNextBoundaryTimer();
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
        _scheduleNextBoundaryTimer();
        // Cancel reminder for the deleted medication
        await NotificationService.instance.cancelMedicationReminder(medicationId);
        return const Success(null);
      case Failure(message: final msg):
        return Failure(msg);
    }
  }

  @override
  void dispose() {
    _stopTicker();
    _isReschedulingNotifications = false;
    super.dispose();
  }
}

/// Provides the live medication list as [AsyncValue].
final medicationProvider =
    StateNotifierProvider<MedicationNotifier, AsyncValue<List<Medication>>>(
  (ref) => MedicationNotifier(ref),
);

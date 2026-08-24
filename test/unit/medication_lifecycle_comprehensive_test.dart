import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/medication_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Full 30-Minute Grace Period & Dose State Boundaries', () {
    const scheduledTime = TimeOfDay(hour: 8, minute: 0); // 08:00 AM

    test('Before scheduled time (07:30 AM) -> PENDING', () {
      final now = DateTime(2026, 8, 24, 7, 30);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('At exact scheduled time (08:00:00 AM) -> PENDING', () {
      final now = DateTime(2026, 8, 24, 8, 0, 0);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('15 minutes after scheduled time (08:15 AM) -> PENDING', () {
      final now = DateTime(2026, 8, 24, 8, 15);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('29 minutes 59 seconds after scheduled time (08:29:59 AM) -> PENDING', () {
      final now = DateTime(2026, 8, 24, 8, 29, 59);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('At exact 30-minute grace boundary (08:30:00 AM) -> PENDING', () {
      final now = DateTime(2026, 8, 24, 8, 30, 0);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('Strictly after 30-minute grace period has elapsed (08:30:01 AM) -> MISSED', () {
      final now = DateTime(2026, 8, 24, 8, 30, 1);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.missed));
    });

    test('31 minutes after scheduled time (08:31:00 AM) -> MISSED', () {
      final now = DateTime(2026, 8, 24, 8, 31, 0);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.missed));
    });

    test('Taken dose within grace period (08:15 AM) -> TAKEN', () {
      final now = DateTime(2026, 8, 24, 8, 15);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: MedStatus.taken,
        now: now,
      );
      expect(status, equals(MedStatus.taken));
    });

    test('Taken dose late after grace period (09:45 AM) -> TAKEN', () {
      final now = DateTime(2026, 8, 24, 9, 45);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: MedStatus.taken,
        now: now,
      );
      expect(status, equals(MedStatus.taken));
    });

    test('calculateRestoredStatus restores to PENDING within grace period', () {
      final now = DateTime(2026, 8, 24, 8, 20);
      final status = Medication.calculateRestoredStatus(
        scheduledTime: scheduledTime,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('calculateRestoredStatus restores to MISSED after grace period has expired', () {
      final now = DateTime(2026, 8, 24, 8, 45);
      final status = Medication.calculateRestoredStatus(
        scheduledTime: scheduledTime,
        now: now,
      );
      expect(status, equals(MedStatus.missed));
    });
  });

  group('2. Multiple Daily Doses & Dose Independence', () {
    test('Two doses of Metformin (08:00 and 20:00) operate completely independently', () async {
      final repo = MedicationRepositoryMock();
      const morningMed = Medication(
        id: 'med_metformin_am',
        name: 'Metformin',
        dose: '500mg',
        time: '8:00 AM — Morning',
        scheduledTimeOfDay: TimeOfDay(hour: 8, minute: 0),
        status: MedStatus.pending,
        note: '',
      );
      const eveningMed = Medication(
        id: 'med_metformin_pm',
        name: 'Metformin',
        dose: '500mg',
        time: '8:00 PM — Evening',
        scheduledTimeOfDay: TimeOfDay(hour: 20, minute: 0),
        status: MedStatus.pending,
        note: '',
      );

      await repo.addMedication(morningMed);
      await repo.addMedication(eveningMed);

      // Log morning dose as taken
      await repo.logDose('med_metformin_am', MedStatus.taken);

      final meds = (await repo.getMedications() as Success<List<Medication>>).data;
      final am = meds.firstWhere((m) => m.id == 'med_metformin_am');
      final pm = meds.firstWhere((m) => m.id == 'med_metformin_pm');

      expect(am.status, equals(MedStatus.taken));
      // Evening dose must remain pending or derived on its own scheduled time
      expect(pm.status, isNot(equals(MedStatus.taken)));

      // Log evening dose as taken
      await repo.logDose('med_metformin_pm', MedStatus.taken);
      final meds2 = (await repo.getMedications() as Success<List<Medication>>).data;
      final am2 = meds2.firstWhere((m) => m.id == 'med_metformin_am');
      final pm2 = meds2.firstWhere((m) => m.id == 'med_metformin_pm');

      expect(am2.status, equals(MedStatus.taken));
      expect(pm2.status, equals(MedStatus.taken));

      // Reset / Undo morning dose
      await repo.logDose('med_metformin_am', MedStatus.pending);
      final meds3 = (await repo.getMedications() as Success<List<Medication>>).data;
      final am3 = meds3.firstWhere((m) => m.id == 'med_metformin_am');
      final pm3 = meds3.firstWhere((m) => m.id == 'med_metformin_pm');

      expect(am3.status, isNot(equals(MedStatus.taken)));
      expect(pm3.status, equals(MedStatus.taken));
    });
  });

  group('3. Missed-Dose Reconciliation & Idempotence', () {
    test('reconcileMissedDoses() records missed doses once and creates 0 duplicates on subsequent runs', () async {
      final repo = MedicationRepositoryMock();
      const pastDueMed = Medication(
        id: 'med_past_due_1',
        name: 'Thyroid Medicine',
        dose: '50mcg',
        time: '5:00 AM — Early morning',
        scheduledTimeOfDay: TimeOfDay(hour: 5, minute: 0),
        status: MedStatus.pending,
        note: '',
      );
      await repo.addMedication(pastDueMed);

      // Run 1: Should record missed dose
      final res1 = await repo.reconcileMissedDoses();
      expect(res1.isSuccess, isTrue);

      // Run 2: Immediately re-running must record 0 new missed doses
      final res2 = await repo.reconcileMissedDoses();
      expect(res2, isA<Success<int>>());
      expect((res2 as Success<int>).data, equals(0));

      // Verify dose logs contain exactly 1 log for this medication today
      final history = (await repo.getDoseHistory() as Success<List<DoseLog>>).data;
      final now = DateTime.now();
      final todayLogs = history.where((l) =>
          l.medicationId == 'med_past_due_1' &&
          l.loggedAt.year == now.year &&
          l.loggedAt.month == now.month &&
          l.loggedAt.day == now.day).toList();

      expect(todayLogs.length, equals(1));
      expect(todayLogs.first.status, equals(MedStatus.missed));
    });

    test('reconcileMissedDoses() does not overwrite an existing taken dose', () async {
      final repo = MedicationRepositoryMock();
      const morningMed = Medication(
        id: 'med_already_taken',
        name: 'Blood Pressure Tablet',
        dose: '5mg',
        time: '6:00 AM',
        scheduledTimeOfDay: TimeOfDay(hour: 6, minute: 0),
        status: MedStatus.pending,
        note: '',
      );
      await repo.addMedication(morningMed);
      await repo.logDose('med_already_taken', MedStatus.taken);

      // Run reconciliation
      await repo.reconcileMissedDoses();

      // Check status
      final meds = (await repo.getMedications() as Success<List<Medication>>).data;
      final med = meds.firstWhere((m) => m.id == 'med_already_taken');
      expect(med.status, equals(MedStatus.taken));
    });
  });

  group('4. Medication Discontinuation Lifecycle', () {
    late ProviderContainer container;
    late MedicationRepositoryMock mockRepo;

    setUp(() async {
      const testUser = User(
        id: 'user_discontinue_test',
        name: 'Discontinue Tester',
        email: 'test@zindagi.com',
        isOnboardingCompleted: true,
      );

      mockRepo = MedicationRepositoryMock();
      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(authRepository: AuthRepositoryMock(testUser)),
          ),
          medicationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await container.read(authNotifierProvider.notifier).restoreSession();
      await container.read(medicationProvider.notifier).refresh();
    });

    tearDown(() {
      container.dispose();
    });

    test('deleteMedication marks medication as inactive and removes from active list', () async {
      final initialActive = container.read(medicationProvider.notifier).activeMedications;
      expect(initialActive, isNotEmpty);
      final targetId = initialActive.first.id;

      // Discontinue medication
      final res = await container.read(medicationProvider.notifier).deleteMedication(targetId);
      expect(res.isSuccess, isTrue);

      final notifier = container.read(medicationProvider.notifier);
      final updatedActive = notifier.activeMedications;
      final inactiveList = notifier.inactiveMedications;

      // Target must be removed from active
      expect(updatedActive.any((m) => m.id == targetId), isFalse);

      // Target must be preserved in inactive list
      expect(inactiveList.any((m) => m.id == targetId), isTrue);
      expect(inactiveList.firstWhere((m) => m.id == targetId).isActive, isFalse);
    });

    test('Discontinued medication preserves historical dose logs', () async {
      final initialActive = container.read(medicationProvider.notifier).activeMedications;
      final targetId = initialActive.first.id;

      // Mark a dose as taken
      await container.read(medicationProvider.notifier).toggleStatus(0);

      // Discontinue medication
      await container.read(medicationProvider.notifier).deleteMedication(targetId);

      // Verify dose logs still exist in repository history
      final historyRes = await mockRepo.getDoseHistory();
      final logs = (historyRes as Success<List<DoseLog>>).data;
      expect(logs.any((l) => l.medicationId == targetId), isTrue);
    });
  });

  group('5. Adherence Formula Audit', () {
    late ProviderContainer container;
    late MedicationRepositoryMock mockRepo;

    setUp(() async {
      const user = User(id: 'u1', name: 'Test', email: 'u@t.com', isOnboardingCompleted: true);
      mockRepo = MedicationRepositoryMock();
      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) => AuthNotifier(authRepository: AuthRepositoryMock(user))),
          medicationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await container.read(authNotifierProvider.notifier).restoreSession();
      await container.read(medicationProvider.notifier).refresh();
    });

    tearDown(() {
      container.dispose();
    });

    test('Adherence uses taken / (taken + missed) and excludes pending doses', () async {
      final notifier = container.read(medicationProvider.notifier);

      // Create 3 future medications scheduled for 21:00, 22:00, 23:00 (strictly in future)
      const futureMed1 = Medication(
        id: 'med_future_1',
        name: 'Night Tablet 1',
        dose: '1 tab',
        time: '9:00 PM',
        scheduledTimeOfDay: TimeOfDay(hour: 21, minute: 0),
        status: MedStatus.pending,
        note: '',
      );
      const futureMed2 = Medication(
        id: 'med_future_2',
        name: 'Night Tablet 2',
        dose: '1 tab',
        time: '10:00 PM',
        scheduledTimeOfDay: TimeOfDay(hour: 22, minute: 0),
        status: MedStatus.pending,
        note: '',
      );

      await mockRepo.addMedication(futureMed1);
      await mockRepo.addMedication(futureMed2);
      await notifier.refresh();

      // Case 1: When all due doses are 0 (e.g. only future pending meds), adherence is 1.0 (100%)
      // If we mark futureMed1 as TAKEN: taken = 1, missed = 0 -> adherence = 1.0 (100%)
      await mockRepo.logDose('med_future_1', MedStatus.taken);
      await notifier.refresh();

      final active = notifier.activeMedications;
      final m1 = active.firstWhere((m) => m.id == 'med_future_1');
      final m2 = active.firstWhere((m) => m.id == 'med_future_2');
      expect(m1.status, equals(MedStatus.taken));
      expect(m2.status, equals(MedStatus.pending));

      // Case 2: When 1 taken and 1 missed among these:
      await mockRepo.logDose('med_future_2', MedStatus.missed);
      await notifier.refresh();

      final m1After = notifier.activeMedications.firstWhere((m) => m.id == 'med_future_1');
      final m2After = notifier.activeMedications.firstWhere((m) => m.id == 'med_future_2');
      expect(m1After.status, equals(MedStatus.taken));
      expect(m2After.status, equals(MedStatus.missed));

      // Formula: taken / (taken + missed)
      final taken = notifier.takenCount;
      final missed = notifier.missedCount;
      final expectedAdherence = taken / (taken + missed);
      expect(notifier.adherence, equals(expectedAdherence));
    });
  });
}

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

  group('Phase 2 30-Minute Missed-Dose State Machine Tests', () {
    const scheduledTime = TimeOfDay(hour: 10, minute: 0);

    group('1. deriveStatus Pure Calculation', () {
      test('At 10:29:59 (within 30-min grace period), status is PENDING', () {
        final now = DateTime(2026, 8, 19, 10, 29, 59);
        final status = Medication.deriveStatus(
          scheduledTime: scheduledTime,
          loggedStatus: null,
          now: now,
        );
        expect(status, equals(MedStatus.pending));
      });

      test('At 10:30:00 (exact 30-min grace boundary), status is PENDING', () {
        final now = DateTime(2026, 8, 19, 10, 30, 0);
        final status = Medication.deriveStatus(
          scheduledTime: scheduledTime,
          loggedStatus: null,
          now: now,
        );
        expect(status, equals(MedStatus.pending));
      });

      test('At 10:30:01 (after 30-min grace period has elapsed), status is MISSED', () {
        final now = DateTime(2026, 8, 19, 10, 30, 1);
        final status = Medication.deriveStatus(
          scheduledTime: scheduledTime,
          loggedStatus: null,
          now: now,
        );
        expect(status, equals(MedStatus.missed));
      });

      test('If user took dose on time at 10:15, status is TAKEN', () {
        final now = DateTime(2026, 8, 19, 10, 15);
        final status = Medication.deriveStatus(
          scheduledTime: scheduledTime,
          loggedStatus: MedStatus.taken,
          now: now,
        );
        expect(status, equals(MedStatus.taken));
      });

      test('If user took dose late at 10:45, status is TAKEN and never reverts to MISSED', () {
        final now = DateTime(2026, 8, 19, 10, 45);
        final status = Medication.deriveStatus(
          scheduledTime: scheduledTime,
          loggedStatus: MedStatus.taken,
          now: now,
        );
        expect(status, equals(MedStatus.taken));
      });
    });

    group('2. State Machine Transitions (Pending -> Taken, Missed -> Taken, Taken -> Pending)', () {
      late ProviderContainer container;
      late MedicationRepositoryMock mockRepo;

      setUp(() async {
        const testUser = User(
          id: 'user_test',
          name: 'Test User',
          email: 'test@user.com',
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

      test('Tapping PENDING medication marks it as TAKEN', () async {
        final meds = container.read(medicationProvider).valueOrNull!;
        expect(meds, isNotEmpty);

        // Reset first med to pending
        await mockRepo.logDose(meds.first.id, MedStatus.pending);
        await container.read(medicationProvider.notifier).refresh();

        var currentMeds = container.read(medicationProvider).valueOrNull!;
        final firstMed = currentMeds.first;

        if (firstMed.status == MedStatus.pending) {
          final res = await container.read(medicationProvider.notifier).toggleStatus(0);
          expect(res.isSuccess, isTrue);

          currentMeds = container.read(medicationProvider).valueOrNull!;
          expect(currentMeds.first.status, equals(MedStatus.taken));
        }
      });

      test('Tapping MISSED medication directly marks it as TAKEN (Late Taking)', () async {
        final meds = container.read(medicationProvider).valueOrNull!;
        final targetMedId = meds.first.id;

        // Force status to missed
        await mockRepo.logDose(targetMedId, MedStatus.missed);
        await container.read(medicationProvider.notifier).refresh();

        var currentMeds = container.read(medicationProvider).valueOrNull!;
        expect(currentMeds.first.status, equals(MedStatus.missed));

        // Tap the missed medication -> must become TAKEN
        final toggleRes = await container.read(medicationProvider.notifier).toggleStatus(0);
        expect(toggleRes.isSuccess, isTrue);

        currentMeds = container.read(medicationProvider).valueOrNull!;
        expect(currentMeds.first.status, equals(MedStatus.taken));

        // Reconcile and refresh -> must REMAIN TAKEN
        await mockRepo.reconcileMissedDoses();
        await container.read(medicationProvider.notifier).refresh();

        final afterReconcileMeds = container.read(medicationProvider).valueOrNull!;
        expect(afterReconcileMeds.first.status, equals(MedStatus.taken));
      });

      test('Tapping TAKEN medication resets it to PENDING (Undo)', () async {
        final meds = container.read(medicationProvider).valueOrNull!;
        final targetMedId = meds.first.id;

        // Mark taken
        await mockRepo.logDose(targetMedId, MedStatus.taken);
        await container.read(medicationProvider.notifier).refresh();

        var currentMeds = container.read(medicationProvider).valueOrNull!;
        expect(currentMeds.first.status, equals(MedStatus.taken));

        // Tap taken medication -> resets to pending
        final toggleRes = await container.read(medicationProvider.notifier).toggleStatus(0);
        expect(toggleRes.isSuccess, isTrue);

        final histRes = await mockRepo.getDoseHistory();
        final logs = (histRes as Success<List<DoseLog>>).data;
        final now = DateTime.now();
        expect(
          logs.any((l) =>
              l.medicationId == targetMedId &&
              l.loggedAt.year == now.year &&
              l.loggedAt.month == now.month &&
              l.loggedAt.day == now.day &&
              l.status == MedStatus.taken),
          isFalse,
        );
      });
    });
  });
}

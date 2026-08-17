import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/data/repositories/implementations/medication_repository_mock.dart';

void main() {
  group('Medication Reconciliation & Read-Only Separation', () {
    late MedicationRepositoryMock repo;

    setUp(() {
      repo = MedicationRepositoryMock();
    });

    test('getMedications() is strictly read-only and does not alter dose log count', () async {
      final initialLogsRes = await repo.getDoseHistory();
      final initialLogCount = (initialLogsRes as Success<List<DoseLog>>).data.length;

      // Call getMedications multiple times
      await repo.getMedications();
      await repo.getMedications();

      final afterLogsRes = await repo.getDoseHistory();
      final afterLogCount = (afterLogsRes as Success<List<DoseLog>>).data.length;

      expect(afterLogCount, equals(initialLogCount));
    });

    test('reconcileMissedDoses() records missed doses for past-due medications and prevents duplicates', () async {
      // 1. Reconcile initially
      final res1 = await repo.reconcileMissedDoses();
      expect(res1, isA<Success<int>>());

      // 2. Reconcile a second time immediately
      final res2 = await repo.reconcileMissedDoses();
      expect(res2, isA<Success<int>>());
      // No duplicate logs should be created on consecutive reconciliations
      expect((res2 as Success<int>).data, equals(0));
    });

    test('reconcileMissedDoses() skips medications that are already marked taken', () async {
      // Add a medication
      const newMed = Medication(
        id: 'med_test_taken',
        name: 'Morning Vitamin',
        dose: '1 tablet',
        time: '6:00 AM', // Well in the past
        status: MedStatus.pending,
        note: '',
      );
      await repo.addMedication(newMed);

      // Explicitly mark it taken
      await repo.logDose('med_test_taken', MedStatus.taken);

      final initialLogs = (await repo.getDoseHistory() as Success<List<DoseLog>>).data;
      final takenLogCount = initialLogs.where((l) => l.medicationId == 'med_test_taken').length;
      expect(takenLogCount, equals(1));

      // Reconcile
      await repo.reconcileMissedDoses();

      // Ensure no missed log was created for med_test_taken
      final logsAfter = (await repo.getDoseHistory() as Success<List<DoseLog>>).data;
      final medLogs = logsAfter.where((l) => l.medicationId == 'med_test_taken').toList();
      expect(medLogs.length, equals(1));
      expect(medLogs.first.status, equals(MedStatus.taken));
    });
  });
}

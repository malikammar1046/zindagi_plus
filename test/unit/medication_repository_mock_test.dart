import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/data/repositories/implementations/medication_repository_mock.dart';

void main() {
  late MedicationRepositoryMock repo;

  setUp(() {
    repo = MedicationRepositoryMock();
  });

  group('MedicationRepositoryMock', () {
    group('getMedications()', () {
      test('returns a non-empty list with pre-seeded mock data', () async {
        final result = await repo.getMedications();
        expect(result, isA<Success<List<Medication>>>());
        final meds = (result as Success<List<Medication>>).data;
        expect(meds, isNotEmpty);
      });

      test('all returned medications have non-empty ids', () async {
        final result = await repo.getMedications();
        final meds = (result as Success<List<Medication>>).data;
        for (final m in meds) {
          expect(m.id, isNotEmpty);
        }
      });
    });

    group('addMedication()', () {
      test('adds a medication and it appears in getMedications()', () async {
        const newMed = Medication(
          id: 'test-id',
          name: 'Test Drug',
          dose: '100mg',
          time: '8:00 AM',
          status: MedStatus.pending,
          note: '',
        );

        final addResult = await repo.addMedication(newMed);
        expect(addResult, isA<Success<Medication>>());

        final listResult = await repo.getMedications();
        final meds = (listResult as Success<List<Medication>>).data;
        expect(meds.any((m) => m.id == 'test-id'), isTrue);
      });
    });

    group('deleteMedication()', () {
      test('soft-deletes a medication (sets isActive=false)', () async {
        // Get an existing medication id.
        final listResult = await repo.getMedications();
        final meds = (listResult as Success<List<Medication>>).data;
        final firstId = meds.first.id;

        final deleteResult = await repo.deleteMedication(firstId);
        expect(deleteResult, isA<Success<void>>());

        // After delete, medication still exists but isActive=false.
        final afterResult = await repo.getMedications();
        final afterMeds = (afterResult as Success<List<Medication>>).data;
        final deleted = afterMeds.firstWhere((m) => m.id == firstId);
        expect(deleted.isActive, isFalse);
      });

      test('returns Failure for unknown id', () async {
        final result = await repo.deleteMedication('nonexistent-id');
        expect(result, isA<Failure<void>>());
      });
    });

    group('logDose()', () {
      test('returns a DoseLog on success', () async {
        final listResult = await repo.getMedications();
        final meds = (listResult as Success<List<Medication>>).data;
        final medId = meds.first.id;

        final doseResult = await repo.logDose(medId, MedStatus.taken);
        expect(doseResult, isA<Success<DoseLog>>());
        final log = (doseResult as Success<DoseLog>).data;
        expect(log.medicationId, equals(medId));
        expect(log.status, equals(MedStatus.taken));
      });

      test('returns Success even for unknown medication (mock uses fallback)', () async {
        // The mock uses firstWhere with orElse fallback, so unknown IDs still succeed.
        final result = await repo.logDose('unknown-id', MedStatus.taken);
        expect(result, isA<Success<DoseLog>>());
        final log = (result as Success<DoseLog>).data;
        expect(log.medicationId, equals('unknown-id'));
      });
    });

    group('getDoseHistory()', () {
      test('returns pre-seeded logs initially (mock is pre-populated)', () async {
        final result = await repo.getDoseHistory();
        expect(result, isA<Success<List<DoseLog>>>());
        // The mock is pre-seeded with sample dose log entries.
        final logs = (result as Success<List<DoseLog>>).data;
        expect(logs, isNotEmpty);
      });

      test('returns a log entry after logDose is called', () async {
        final listResult = await repo.getMedications();
        final meds = (listResult as Success<List<Medication>>).data;
        final medId = meds.first.id;

        await repo.logDose(medId, MedStatus.taken);
        final histResult = await repo.getDoseHistory();
        final logs = (histResult as Success<List<DoseLog>>).data;
        expect(logs, isNotEmpty);
        expect(logs.first.medicationId, equals(medId));
      });
    });
  });
}

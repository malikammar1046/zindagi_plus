import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/medication_repository_mock.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

class _FailingMedicationRepo extends MedicationRepositoryMock {
  @override
  Future<Result<DoseLog>> logDose(String medicationId, MedStatus status) async {
    return const Failure('Simulated network error');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 Foundation Hardening Tests', () {
    group('1. Account Deletion', () {
      test('AuthNotifier.deleteAccount() clears session on success', () async {
        const user = User(
          id: 'user-001',
          name: 'Ammar',
          email: 'ammar@test.com',
          isOnboardingCompleted: true,
        );

        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(authRepository: AuthRepositoryMock(user)),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authNotifierProvider.notifier).restoreSession();
        expect(container.read(authNotifierProvider), equals(user));

        final result = await container.read(authNotifierProvider.notifier).deleteAccount();
        expect(result.isSuccess, isTrue);
        expect(container.read(authNotifierProvider), isNull);
      });
    });

    group('2. Honest Report Data & No Fake Biomarkers', () {
      test('LabReport correctly handles 0 biomarkers and retains real OCR text', () {
        final report = LabReport(
          id: 'rep_123',
          fileName: 'real_scan.jpg',
          uploadedAt: DateTime.now(),
          status: ReportStatus.completed,
          extractedText: 'Patient: Ammar\nHbA1c: 5.6%\nGlucose: 95 mg/dL',
          biomarkerCount: 0,
          attentionCount: 0,
        );

        expect(report.biomarkerCount, equals(0));
        expect(report.hasExtractedText, isTrue);
        expect(report.extractedText, contains('HbA1c: 5.6%'));
        expect(report.isCompleted, isTrue);
      });
    });

    group('3. Medication Dose Rollback on Failure', () {
      test('toggleStatus rolls back optimistic update when logDose fails', () async {
        const testUser = User(
          id: 'user-001',
          name: 'Ammar',
          email: 'ammar@test.com',
          isOnboardingCompleted: true,
        );

        final failingRepo = _FailingMedicationRepo();
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(authRepository: AuthRepositoryMock(testUser)),
            ),
            medicationRepositoryProvider.overrideWithValue(failingRepo),
          ],
        );
        addTearDown(container.dispose);

        // Restore session and load medications
        await container.read(authNotifierProvider.notifier).restoreSession();
        await container.read(medicationProvider.notifier).refresh();

        final initialMeds = container.read(medicationProvider).valueOrNull!;
        expect(initialMeds, isNotEmpty);
        final initialStatus = initialMeds.first.status;

        // Attempt toggleStatus on first medication with failing repo
        final result = await container.read(medicationProvider.notifier).toggleStatus(0);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull?.message, contains('Simulated network error'));

        // Verify status rolled back to initial state
        final currentMeds = container.read(medicationProvider).valueOrNull!;
        expect(currentMeds.first.status, equals(initialStatus));
      });

      test('logDose supports resetting status to pending', () async {
        final repo = MedicationRepositoryMock();
        final listRes = await repo.getMedications();
        final medId = (listRes as Success<List<Medication>>).data.first.id;

        // Log taken
        await repo.logDose(medId, MedStatus.taken);
        var histRes = await repo.getDoseHistory();
        var logs = (histRes as Success<List<DoseLog>>).data;
        expect(logs.any((l) => l.medicationId == medId && l.status == MedStatus.taken), isTrue);

        // Revert to pending
        final pendingRes = await repo.logDose(medId, MedStatus.pending);
        expect(pendingRes.isSuccess, isTrue);

        histRes = await repo.getDoseHistory();
        logs = (histRes as Success<List<DoseLog>>).data;
        final now = DateTime.now();
        expect(
          logs.any((l) =>
              l.medicationId == medId &&
              l.loggedAt.year == now.year &&
              l.loggedAt.month == now.month &&
              l.loggedAt.day == now.day),
          isFalse,
        );
      });
    });

    group('4. Result<T> Utility Getters', () {
      test('Success getters work correctly', () {
        const Result<String> r = Success('data');
        expect(r.isSuccess, isTrue);
        expect(r.isFailure, isFalse);
        expect(r.dataOrNull, equals('data'));
        expect(r.failureOrNull, isNull);
      });

      test('Failure getters work correctly', () {
        const Result<String> r = Failure('error_msg');
        expect(r.isSuccess, isFalse);
        expect(r.isFailure, isTrue);
        expect(r.dataOrNull, isNull);
        expect(r.failureOrNull?.message, equals('error_msg'));
      });
    });
  });
}

import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/data/repositories/interfaces/medication_repository.dart';

/// Mock implementation of [MedicationRepository].
///
/// Returns hard-coded data with artificial delays. Swap for a real API
/// implementation by updating `lib/providers/repository_providers.dart`.
class MedicationRepositoryMock implements MedicationRepository {
  // In-memory mutable list — simulates a local cache.
  final List<Medication> _medications = [
    const Medication(
      id: 'med_001',
      name: 'Metformin',
      dose: '500mg',
      time: '8:00 AM — With breakfast',
      status: MedStatus.taken,
      note: 'For blood glucose control',
      iconCodePoint: 0xe3a3, // Icons.medication_rounded
      colorValue: 0xFF00674F, // Emerald
    ),
    const Medication(
      id: 'med_002',
      name: 'Vitamin D3',
      dose: '2000 IU',
      time: '1:00 PM — With lunch',
      status: MedStatus.pending,
      note: 'Deficiency correction',
      iconCodePoint: 0xe8fa, // Icons.wb_sunny_outlined
      colorValue: 0xFFFF9800, // Orange
    ),
    const Medication(
      id: 'med_003',
      name: 'Omega-3',
      dose: '1000mg',
      time: '8:00 PM — With dinner',
      status: MedStatus.pending,
      note: 'For LDL cholesterol support',
      iconCodePoint: 0xe798, // Icons.water_drop_outlined
      colorValue: 0xFF2196F3, // Blue
    ),
    const Medication(
      id: 'med_004',
      name: 'Metformin (Evening)',
      dose: '500mg',
      time: '8:00 PM — With dinner',
      status: MedStatus.missed,
      note: 'Missed yesterday',
      iconCodePoint: 0xe3a3, // Icons.medication_rounded
      colorValue: 0xFF670018, // Burgundy
    ),
  ];

  final List<DoseLog> _doseLogs = [
    DoseLog(
      medicationId: 'med_001',
      medicationName: 'Metformin',
      dose: '500mg',
      status: MedStatus.taken,
      loggedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    DoseLog(
      medicationId: 'med_004',
      medicationName: 'Metformin (Evening)',
      dose: '500mg',
      status: MedStatus.missed,
      loggedAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    DoseLog(
      medicationId: 'med_001',
      medicationName: 'Metformin',
      dose: '500mg',
      status: MedStatus.taken,
      loggedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    DoseLog(
      medicationId: 'med_002',
      medicationName: 'Vitamin D3',
      dose: '2000 IU',
      status: MedStatus.taken,
      loggedAt: DateTime.now().subtract(const Duration(days: 1, hours: 7)),
    ),
    DoseLog(
      medicationId: 'med_003',
      medicationName: 'Omega-3',
      dose: '1000mg',
      status: MedStatus.taken,
      loggedAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
    ),
    DoseLog(
      medicationId: 'med_004',
      medicationName: 'Metformin (Evening)',
      dose: '500mg',
      status: MedStatus.missed,
      loggedAt: DateTime.now().subtract(const Duration(days: 2, hours: 14)),
    ),
  ];

  @override
  Future<Result<List<Medication>>> getMedications() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Success(List.unmodifiable(_medications));
  }

  @override
  Future<Result<Medication>> addMedication(Medication medication) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _medications.add(medication);
    return Success(medication);
  }

  @override
  Future<Result<void>> deleteMedication(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _medications.indexWhere((m) => m.id == id);
    if (index == -1) {
      return const Failure('Medication not found.');
    }
    _medications[index] = _medications[index].copyWith(isActive: false);
    return const Success(null);
  }

  @override
  Future<Result<DoseLog>> logDose(String medicationId, MedStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final med = _medications.firstWhere(
      (m) => m.id == medicationId,
      orElse: () => const Medication(
        id: '',
        name: 'Unknown',
        dose: '',
        time: '',
        status: MedStatus.pending,
        note: '',
      ),
    );
    final log = DoseLog(
      medicationId: medicationId,
      medicationName: med.name,
      dose: med.dose,
      status: status,
      loggedAt: DateTime.now(),
    );
    _doseLogs.insert(0, log);
    return Success(log);
  }

  @override
  Future<Result<List<DoseLog>>> getDoseHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Success(List.unmodifiable(_doseLogs));
  }

  @override
  Future<Result<int>> reconcileMissedDoses() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    int count = 0;

    for (int i = 0; i < _medications.length; i++) {
      final med = _medications[i];
      if (!med.isActive) continue;

      // Check if a dose log already exists for this medication today
      final hasLogToday = _doseLogs.any(
        (log) =>
            log.medicationId == med.id &&
            log.loggedAt.year == now.year &&
            log.loggedAt.month == now.month &&
            log.loggedAt.day == now.day,
      );

      if (hasLogToday) continue;

      final time = med.parsedTimeOfDay;
      if (time == null) continue;

      final scheduledToday = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      final gracePeriodEnd = scheduledToday.add(const Duration(minutes: 30));

      if (now.isAfter(gracePeriodEnd) || now.isAtSameMomentAs(gracePeriodEnd)) {
        final log = DoseLog(
          medicationId: med.id,
          medicationName: med.name,
          dose: med.dose,
          status: MedStatus.missed,
          loggedAt: gracePeriodEnd,
        );
        _doseLogs.insert(0, log);
        _medications[i] = med.copyWith(status: MedStatus.missed);
        count++;
      }
    }

    return Success(count);
  }
}


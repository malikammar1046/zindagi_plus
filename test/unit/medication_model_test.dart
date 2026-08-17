import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/medication.dart';

void main() {
  group('Medication.fromSupabase', () {
    final sampleRow = {
      'id': 'abc-123',
      'name': 'Metformin',
      'dose': '500mg',
      'schedule_time': '8:00 AM — With breakfast',
      'notes': 'Take with water',
      'is_active': true,
    };

    test('maps all fields correctly', () {
      final m = Medication.fromSupabase(sampleRow);
      expect(m.id, equals('abc-123'));
      expect(m.name, equals('Metformin'));
      expect(m.dose, equals('500mg'));
      expect(m.time, equals('8:00 AM — With breakfast'));
      expect(m.note, equals('Take with water'));
      expect(m.isActive, isTrue);
      expect(m.status, equals(MedStatus.pending)); // default
    });

    test('respects explicit todayStatus', () {
      final m = Medication.fromSupabase(sampleRow, todayStatus: MedStatus.taken);
      expect(m.status, equals(MedStatus.taken));
    });

    test('handles null optional fields gracefully', () {
      final m = Medication.fromSupabase({
        'id': 'x',
        'name': 'Panadol',
        'dose': '1 pill',
        'schedule_time': '9:00 AM',
        // notes and is_active omitted
      });
      expect(m.note, equals(''));
      expect(m.isActive, isTrue); // default
    });

    test('handles completely empty map', () {
      final m = Medication.fromSupabase({});
      expect(m.id, equals(''));
      expect(m.name, equals(''));
      expect(m.isActive, isTrue);
    });
  });

  group('Medication.toSupabase', () {
    test('produces correct payload keys', () {
      const m = Medication(
        id: 'x',
        name: 'Aspirin',
        dose: '100mg',
        time: '7:00 AM',
        status: MedStatus.pending,
        note: 'With food',
      );
      final payload = m.toSupabase('user-xyz');
      expect(payload['user_id'], equals('user-xyz'));
      expect(payload['name'], equals('Aspirin'));
      expect(payload['dose'], equals('100mg'));
      expect(payload['schedule_time'], equals('7:00 AM'));
      expect(payload['notes'], equals('With food'));
      expect(payload['is_active'], isTrue);
      expect(payload.containsKey('updated_at'), isTrue);
    });

    test('respects isActive = false', () {
      const m = Medication(
        id: 'y',
        name: 'Drug',
        dose: '1mg',
        time: '8 AM',
        status: MedStatus.missed,
        note: '',
        isActive: false,
      );
      final payload = m.toSupabase('user-abc');
      expect(payload['is_active'], isFalse);
    });
  });

  group('Medication.copyWith', () {
    const base = Medication(
      id: '1',
      name: 'Med',
      dose: '1mg',
      time: '8 AM',
      status: MedStatus.pending,
      note: '',
    );

    test('returns new instance with changed fields', () {
      final updated = base.copyWith(status: MedStatus.taken, note: 'note');
      expect(updated.status, equals(MedStatus.taken));
      expect(updated.note, equals('note'));
      expect(updated.name, equals('Med')); // unchanged
    });

    test('original is immutable', () {
      base.copyWith(name: 'New');
      expect(base.name, equals('Med'));
    });
  });

  group('DoseLog.fromSupabase', () {
    test('maps taken status', () {
      final row = {
        'medication_id': 'med-1',
        'status': 'taken',
        'logged_at': '2024-01-01T10:00:00Z',
        'medications': {'name': 'Metformin', 'dose': '500mg'},
      };
      final log = DoseLog.fromSupabase(row);
      expect(log.medicationId, equals('med-1'));
      expect(log.medicationName, equals('Metformin'));
      expect(log.dose, equals('500mg'));
      expect(log.status, equals(MedStatus.taken));
    });

    test('maps missed status', () {
      final row = {
        'medication_id': 'med-2',
        'status': 'missed',
        'logged_at': '2024-01-01T08:00:00Z',
        'medications': {'name': 'Aspirin', 'dose': '100mg'},
      };
      final log = DoseLog.fromSupabase(row);
      expect(log.status, equals(MedStatus.missed));
    });

    test('handles null medications join gracefully', () {
      final row = {
        'medication_id': 'med-3',
        'status': 'taken',
        'logged_at': '2024-01-01T08:00:00Z',
        'medications': null,
      };
      final log = DoseLog.fromSupabase(row);
      expect(log.medicationName, equals('Unknown'));
      expect(log.dose, equals(''));
    });
  });
}

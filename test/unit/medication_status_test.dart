import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/medication.dart';

void main() {
  group('Medication Status & 30-Minute Grace Period Logic', () {
    const scheduledTime = TimeOfDay(hour: 8, minute: 0); // 8:00 AM

    test('Status is TAKEN if a taken log exists, regardless of time', () {
      final now = DateTime(2026, 8, 17, 10, 0); // 10:00 AM (2h later)
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: MedStatus.taken,
        now: now,
      );
      expect(status, equals(MedStatus.taken));
    });

    test('Status is MISSED if an explicit missed log exists', () {
      final now = DateTime(2026, 8, 17, 8, 15); // 8:15 AM
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: MedStatus.missed,
        now: now,
      );
      expect(status, equals(MedStatus.missed));
    });

    test('Status is PENDING before scheduled time (e.g. 7:30 AM)', () {
      final now = DateTime(2026, 8, 17, 7, 30);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('Status is PENDING at exact scheduled time (8:00 AM)', () {
      final now = DateTime(2026, 8, 17, 8, 0);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('Status is PENDING within the 30-minute grace period (e.g. 8:20 AM)', () {
      final now = DateTime(2026, 8, 17, 8, 20);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('Status is PENDING at 29 minutes after scheduled time (8:29 AM)', () {
      final now = DateTime(2026, 8, 17, 8, 29);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('Status is PENDING at exact 30-minute grace boundary (8:30:00 AM)', () {
      final now = DateTime(2026, 8, 17, 8, 30, 0);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.pending));
    });

    test('Status is MISSED immediately after 30-minute grace period has elapsed (8:30:01 AM)', () {
      final now = DateTime(2026, 8, 17, 8, 30, 1);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.missed));
    });

    test('Status is MISSED well after the 30-minute grace period has passed (e.g. 9:15 AM)', () {
      final now = DateTime(2026, 8, 17, 9, 15);
      final status = Medication.deriveStatus(
        scheduledTime: scheduledTime,
        loggedStatus: null,
        now: now,
      );
      expect(status, equals(MedStatus.missed));
    });

    test('calculateRestoredStatus returns PENDING within grace period and MISSED after', () {
      final withinGrace = DateTime(2026, 8, 17, 8, 25);
      expect(
        Medication.calculateRestoredStatus(scheduledTime: scheduledTime, now: withinGrace),
        equals(MedStatus.pending),
      );

      final afterGrace = DateTime(2026, 8, 17, 8, 35);
      expect(
        Medication.calculateRestoredStatus(scheduledTime: scheduledTime, now: afterGrace),
        equals(MedStatus.missed),
      );
    });
  });

  group('Time Parsing Utilities', () {
    test('parseTimeString parses HH:mm:ss format', () {
      final t1 = Medication.parseTimeString('08:30:00');
      expect(t1?.hour, equals(8));
      expect(t1?.minute, equals(30));

      final t2 = Medication.parseTimeString('20:15:00');
      expect(t2?.hour, equals(20));
      expect(t2?.minute, equals(15));
    });

    test('parseTimeOfDay parses 12-hour AM/PM string', () {
      final t1 = Medication.parseTimeOfDay('8:00 AM — With breakfast');
      expect(t1?.hour, equals(8));
      expect(t1?.minute, equals(0));

      final t2 = Medication.parseTimeOfDay('1:30 PM — With lunch');
      expect(t2?.hour, equals(13));
      expect(t2?.minute, equals(30));

      final t3 = Medication.parseTimeOfDay('12:00 AM — Midnight');
      expect(t3?.hour, equals(0));
      expect(t3?.minute, equals(0));

      final t4 = Medication.parseTimeOfDay('12:00 PM — Noon');
      expect(t4?.hour, equals(12));
      expect(t4?.minute, equals(0));
    });

    test('parseTimeOfDay parses 24-hour string', () {
      final t = Medication.parseTimeOfDay('19:45');
      expect(t?.hour, equals(19));
      expect(t?.minute, equals(45));
    });

    test('parsedTimeOfDay property on Medication returns scheduledTimeOfDay if present', () {
      const med = Medication(
        id: '1',
        name: 'Test',
        dose: '1 pill',
        time: '8:00 AM',
        scheduledTimeOfDay: TimeOfDay(hour: 9, minute: 15),
        status: MedStatus.pending,
        note: '',
      );
      expect(med.parsedTimeOfDay?.hour, equals(9));
      expect(med.parsedTimeOfDay?.minute, equals(15));
    });

    test('parsedTimeOfDay falls back to parsing string time if scheduledTimeOfDay is null', () {
      const med = Medication(
        id: '1',
        name: 'Test',
        dose: '1 pill',
        time: '7:30 PM — Dinner',
        status: MedStatus.pending,
        note: '',
      );
      expect(med.parsedTimeOfDay?.hour, equals(19));
      expect(med.parsedTimeOfDay?.minute, equals(30));
    });
  });
}

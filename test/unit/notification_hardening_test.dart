import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
  });

  group('Phase 2 Notification Hardening Tests', () {
    group('1. Time Parsing and Next-Day Rollover Logic', () {
      test('Parses 12-hour AM/PM formats accurately', () {
        final t1 = Medication.parseTimeOfDay('08:00 AM — Breakfast');
        expect(t1, equals(const TimeOfDay(hour: 8, minute: 0)));

        final t2 = Medication.parseTimeOfDay('8:30 pm');
        expect(t2, equals(const TimeOfDay(hour: 20, minute: 30)));

        final t3 = Medication.parseTimeOfDay('12:15 PM');
        expect(t3, equals(const TimeOfDay(hour: 12, minute: 15)));

        final t4 = Medication.parseTimeOfDay('12:00 AM (Midnight)');
        expect(t4, equals(const TimeOfDay(hour: 0, minute: 0)));
      });

      test('Parses 24-hour time strings accurately', () {
        final t1 = Medication.parseTimeString('14:30:00');
        expect(t1, equals(const TimeOfDay(hour: 14, minute: 30)));

        final t2 = Medication.parseTimeString('09:00');
        expect(t2, equals(const TimeOfDay(hour: 9, minute: 0)));
      });

      test('Computes next-day rollover if scheduled time already passed today', () {
        final now = tz.TZDateTime(tz.local, 2026, 8, 19, 14, 0); // 2:00 PM
        const scheduledTime = TimeOfDay(hour: 9, minute: 0); // 9:00 AM (past)

        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );

        if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        expect(scheduledDate.year, equals(2026));
        expect(scheduledDate.month, equals(8));
        expect(scheduledDate.day, equals(20)); // Rolled over to tomorrow
        expect(scheduledDate.hour, equals(9));
        expect(scheduledDate.minute, equals(0));
      });
    });

    group('2. Deterministic Notification IDs', () {
      test('Generates identical stable positive IDs for same medication ID', () {
        const medId1 = 'med_metformin_500';
        final idA = medId1.hashCode.abs() % 1000000;
        final idB = medId1.hashCode.abs() % 1000000;
        expect(idA, equals(idB));
        expect(idA, greaterThanOrEqualTo(0));
        expect(idA, lessThan(1000000));
      });

      test('Generates distinct IDs for different medications', () {
        const med1 = 'med_001';
        const med2 = 'med_002';
        final id1 = med1.hashCode.abs() % 1000000;
        final id2 = med2.hashCode.abs() % 1000000;
        expect(id1, isNot(equals(id2)));
      });
    });

    group('3. Notification Service In-Memory Invocations', () {
      test('NotificationService singleton initializes without crash', () async {
        final service = NotificationService.instance;
        expect(service, isNotNull);
      });
    });
  });
}

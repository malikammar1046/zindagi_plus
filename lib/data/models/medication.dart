import 'package:flutter/material.dart';

/// Represents a medication entry in the user's schedule.
///
/// [fromSupabase] maps a row from `public.medications` (optionally joined with
/// a today-status resolved from `public.medication_dose_logs`).
/// [toSupabase] produces the insert/update payload for `public.medications`.
class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.time,
    required this.status,
    required this.note,
    this.scheduledTimeOfDay,
    this.isActive = true,
    this.iconCodePoint = 0xe3a3, // Icons.medication_rounded
    this.colorValue = 0xFF00674F, // Emerald
  });

  final String id;
  final String name;
  final String dose;

  /// Display-friendly schedule string, e.g. "8:00 AM — With breakfast".
  /// Mapped to `schedule_time TEXT` in `public.medications`.
  final String time;

  /// Parsed time of day representing the exact daily reminder time.
  /// Mapped to `scheduled_time_of_day TIME` in `public.medications`.
  final TimeOfDay? scheduledTimeOfDay;

  /// UI-only field: derived from today's dose log or computed via the 30-min grace period rule.
  final MedStatus status;

  final String note;

  /// Mirrors `is_active` in `public.medications`.
  /// `false` = soft-deleted / archived.
  final bool isActive;

  final int iconCodePoint;
  final int colorValue;

  /// Returns [scheduledTimeOfDay] if explicitly set, or attempts to parse
  /// the hour and minute from the display [time] string.
  TimeOfDay? get parsedTimeOfDay {
    if (scheduledTimeOfDay != null) {
      return scheduledTimeOfDay;
    }
    return parseTimeOfDay(time);
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    String? time,
    TimeOfDay? scheduledTimeOfDay,
    MedStatus? status,
    String? note,
    bool? isActive,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      time: time ?? this.time,
      scheduledTimeOfDay: scheduledTimeOfDay ?? this.scheduledTimeOfDay,
      status: status ?? this.status,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  /// Creates a [Medication] from a `public.medications` row.
  ///
  /// [todayStatus] is the resolved status from today's dose logs and grace period.
  factory Medication.fromSupabase(
    Map<String, dynamic> map, {
    MedStatus todayStatus = MedStatus.pending,
  }) {
    final rawTimeOfDay = map['scheduled_time_of_day'] as String?;
    TimeOfDay? timeOfDay;
    if (rawTimeOfDay != null && rawTimeOfDay.isNotEmpty) {
      timeOfDay = parseTimeString(rawTimeOfDay);
    }
    final scheduleTimeStr = (map['schedule_time'] as String?) ?? '';
    timeOfDay ??= parseTimeOfDay(scheduleTimeStr);

    return Medication(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      dose: (map['dose'] as String?) ?? '',
      time: scheduleTimeStr,
      scheduledTimeOfDay: timeOfDay,
      note: (map['notes'] as String?) ?? '',
      isActive: (map['is_active'] as bool?) ?? true,
      status: todayStatus,
      iconCodePoint: 0xe3a3,
      colorValue: 0xFF00674F,
    );
  }

  /// Returns the insert/update payload for `public.medications`.
  Map<String, dynamic> toSupabase(String userId) {
    final time = parsedTimeOfDay;
    final timeOfDayStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00'
        : null;

    return {
      'user_id': userId,
      'name': name,
      'dose': dose,
      'schedule_time': this.time,
      'scheduled_time_of_day': timeOfDayStr,
      'notes': note,
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Helper to parse a time string like "08:30:00" or "14:15" into a [TimeOfDay].
  static TimeOfDay? parseTimeString(String s) {
    try {
      final parts = s.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        if (h >= 0 && h < 24 && m >= 0 && m < 60) {
          return TimeOfDay(hour: h, minute: m);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Helper to extract [TimeOfDay] from natural language or 12h/24h strings
  /// such as "8:00 AM — With breakfast", "1:30 PM", "20:00", etc.
  static TimeOfDay? parseTimeOfDay(String str) {
    if (str.isEmpty) return null;

    // Try 12-hour format with AM/PM (e.g., "8:00 AM", "01:30 PM", "8:00am")
    final match12 = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm|AM|PM)').firstMatch(str);
    if (match12 != null) {
      int hour = int.parse(match12.group(1)!);
      final int minute = int.parse(match12.group(2)!);
      final isPm = match12.group(3)!.toLowerCase() == 'pm';

      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    // Try 24-hour format (e.g., "08:00", "20:15")
    final match24 = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(str);
    if (match24 != null) {
      final int hour = int.parse(match24.group(1)!);
      final int minute = int.parse(match24.group(2)!);
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return null;
  }

  /// Pure helper: derives today's [MedStatus] based on:
  /// - today's existing dose log status (if any)
  /// - scheduled medication time
  /// - current local time
  /// - full 30-minute grace period (scheduledTime through scheduledTime + 30m is PENDING; strictly after is MISSED)
  static MedStatus deriveStatus({
    required TimeOfDay? scheduledTime,
    required MedStatus? loggedStatus,
    required DateTime now,
  }) {
    if (loggedStatus == MedStatus.taken) {
      return MedStatus.taken;
    }
    if (loggedStatus == MedStatus.missed) {
      return MedStatus.missed;
    }

    if (scheduledTime == null) {
      return MedStatus.pending;
    }

    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // Full 30-minute grace period after scheduled time.
    // Scheduled time through scheduledTime + 30m (inclusive) is PENDING.
    // After the 30-minute grace period has actually elapsed (now.isAfter(gracePeriodEnd)) is MISSED.
    final gracePeriodEnd = scheduledDateTime.add(const Duration(minutes: 30));

    if (now.isAfter(gracePeriodEnd)) {
      return MedStatus.missed;
    } else {
      return MedStatus.pending;
    }
  }

  /// Calculates the restored status when an existing dose log is undone/unchecked.
  /// If [now] is within the 30-minute grace period, restores to [MedStatus.pending].
  /// If [now] is strictly after the 30-minute grace period has elapsed, restores to [MedStatus.missed].
  static MedStatus calculateRestoredStatus({
    required TimeOfDay? scheduledTime,
    required DateTime now,
  }) {
    return deriveStatus(
      scheduledTime: scheduledTime,
      loggedStatus: null,
      now: now,
    );
  }
}

enum MedStatus { taken, pending, missed }

/// Represents a single dose log entry for history.
class DoseLog {
  const DoseLog({
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    required this.status,
    required this.loggedAt,
    this.scheduledTime,
  });

  final String medicationId;
  final String medicationName;
  final String dose;
  final MedStatus status;
  final DateTime loggedAt;
  final String? scheduledTime;

  /// Creates a [DoseLog] from a `public.medication_dose_logs` row joined with
  /// `public.medications`.
  factory DoseLog.fromSupabase(Map<String, dynamic> map) {
    final medication = map['medications'] as Map<String, dynamic>?;
    final rawStatus = (map['status'] as String?) ?? 'missed';
    return DoseLog(
      medicationId: (map['medication_id'] as String?) ?? '',
      medicationName: (medication?['name'] as String?) ?? 'Unknown',
      dose: (medication?['dose'] as String?) ?? '',
      scheduledTime: medication?['schedule_time'] as String?,
      status: rawStatus == 'taken' ? MedStatus.taken : MedStatus.missed,
      loggedAt: DateTime.parse(
        (map['logged_at'] as String?) ??
            DateTime.now().toUtc().toIso8601String(),
      ).toLocal(),
    );
  }
}

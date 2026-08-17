import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:zindagi_plus/data/models/medication.dart';

/// Centralized local notification service for scheduling daily medication reminders.
///
/// Features:
/// - Dynamic device local timezone resolution (never hard-coded).
/// - Android 13+ notification & exact alarm permissions.
/// - Exact alarm scheduling with AlarmClock priority to prevent vendor Doze/power delays.
/// - Recurring daily reminder scheduling using [DateTimeComponents.time].
/// - Notification tap listener that emits the tapped medication ID without auto-marking taken.
/// - Diagnostic logging for timing, timezone, schedule mode, and exact alarm status.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'medication_reminders';
  static const String channelName = 'Medication Reminders';
  static const String channelDescription =
      'Timely reminders to take your prescribed medications';

  final _tapController = StreamController<String>.broadcast();

  /// Stream of medication IDs tapped from local notifications.
  Stream<String> get onNotificationTap => _tapController.stream;

  bool _isInitialized = false;
  String _detectedTimezone = 'UTC';

  /// Returns the detected device local timezone.
  String get detectedTimezone => _detectedTimezone;

  /// Initializes the local notification plugin and local timezone database.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database dynamically
      tz.initializeTimeZones();
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        _detectedTimezone = timeZoneName;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint(
          '[NotificationService] Local timezone resolved: $timeZoneName',
        );
      } catch (e) {
        _detectedTimezone = tz.local.name;
        debugPrint(
          '[NotificationService] Could not resolve device timezone, fallback to local: $e',
        );
        tz.setLocalLocation(tz.local);
      }

      // 2. Platform initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            debugPrint(
              '[NotificationService] Notification tapped with payload: $payload',
            );
            _tapController.add(payload);
          }
        },
      );

      // 3. Create Android notification channel (High importance, standard soft sound)
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully.');
    } catch (e, st) {
      debugPrint('[NotificationService] Initialization error: $e\n$st');
    }
  }

  /// Requests notification permissions on Android 13+ and requests exact alarm permission.
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final postGranted =
            await androidPlugin.requestNotificationsPermission();
        debugPrint(
          '[NotificationService] Android POST_NOTIFICATIONS permission: $postGranted',
        );

        final exactGranted =
            await androidPlugin.requestExactAlarmsPermission();
        debugPrint(
          '[NotificationService] Android requestExactAlarmsPermission: $exactGranted',
        );

        return postGranted ?? false;
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] Error requesting permissions: $e');
    }
    return false;
  }

  /// Generates a stable positive 31-bit notification ID from a medication string ID.
  int _notificationId(String medId) => medId.hashCode.abs() % 1000000;

  /// Schedules a recurring daily reminder for [medication] at its scheduled time.
  Future<void> scheduleMedicationReminder(Medication medication) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!medication.isActive) {
      await cancelMedicationReminder(medication.id);
      return;
    }

    final time = medication.parsedTimeOfDay;
    if (time == null) {
      debugPrint(
        '[NotificationService] Skipping reminder for ${medication.name}: no valid time found.',
      );
      return;
    }

    final int id = _notificationId(medication.id);
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If scheduled time already passed today, start from tomorrow's occurrence
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final displayTime = medication.time.contains('—')
        ? medication.time.split('—').first.trim()
        : medication.time;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Medication reminder',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    debugPrint('----------------------------------------------------');
    debugPrint('[NotificationService] SCHEDULING REMINDER AUDIT:');
    debugPrint('  - Current Device Time: $now (${now.timeZoneName}, offset: ${now.timeZoneOffset})');
    debugPrint('  - Medication: ${medication.name} (${medication.dose})');
    debugPrint('  - Scheduled Local Time: $scheduledDate');
    debugPrint('  - Timezone: $_detectedTimezone');
    debugPrint('  - Notification ID: $id');
    debugPrint('  - Target AndroidScheduleMode: alarmClock (exact) / exactAllowWhileIdle');
    debugPrint('----------------------------------------------------');

    try {
      // 1. Try alarmClock mode first: AlarmManager.setAlarmClock() is guaranteed by
      // Android to wake the device from deep sleep at the exact second without Doze throttling.
      await _notifications.zonedSchedule(
        id,
        '💊 Time for your medicine',
        '${medication.name} (${medication.dose}) — scheduled for $displayTime',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medication.id,
      );

      debugPrint(
        '[NotificationService] Scheduled exact alarmClock reminder for ${medication.name} (id=$id) at $scheduledDate (recurring daily)',
      );
      return;
    } catch (e) {
      debugPrint(
        '[NotificationService] alarmClock mode threw ($e), attempting exactAllowWhileIdle...',
      );
      try {
        // 2. Fallback to exactAllowWhileIdle
        await _notifications.zonedSchedule(
          id,
          '💊 Time for your medicine',
          '${medication.name} (${medication.dose}) — scheduled for $displayTime',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: medication.id,
        );

        debugPrint(
          '[NotificationService] Scheduled exactAllowWhileIdle reminder for ${medication.name} (id=$id) at $scheduledDate (recurring daily)',
        );
        return;
      } catch (e2) {
        debugPrint(
          '[NotificationService] exactAllowWhileIdle failed ($e2), falling back to inexact...',
        );
      }
    }

    // 3. Inexact fallback if exact alarms are completely disallowed
    try {
      await _notifications.zonedSchedule(
        id,
        '💊 Time for your medicine',
        '${medication.name} (${medication.dose})',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medication.id,
      );

      debugPrint(
        '[NotificationService] Scheduled inexact reminder fallback for ${medication.name}',
      );
    } catch (fallbackError) {
      debugPrint(
        '[NotificationService] Failed to schedule reminder: $fallbackError',
      );
    }
  }

  /// Cancels any scheduled reminder for the given medication ID.
  Future<void> cancelMedicationReminder(String medicationId) async {
    try {
      final int id = _notificationId(medicationId);
      await _notifications.cancel(id);
      debugPrint(
        '[NotificationService] Cancelled reminder for medId=$medicationId (id=$id)',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling reminder: $e');
    }
  }

  /// Re-syncs all active medications to ensure reminder schedules are up to date.
  Future<void> rescheduleAll(List<Medication> activeMeds) async {
    for (final med in activeMeds) {
      if (med.isActive) {
        await scheduleMedicationReminder(med);
      } else {
        await cancelMedicationReminder(med.id);
      }
    }
  }
}

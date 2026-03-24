import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  // Jadwalkan reminder harian untuk good habit
  Future<void> scheduleGoodHabitReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      '⏰ Reminder habit',
      'Jangan lupa: $habitName hari ini!',
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'good_habit_reminder',
          'Reminder Good Habit',
          channelDescription: 'Pengingat untuk good habit harian',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF1D9E75),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ulang tiap hari
    );
  }

  // Milestone bad habit
  Future<void> showMilestoneNotification({
    required String habitName,
    required int days,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🏆 Milestone tercapai!',
      'Hebat! $habitName — $days hari clean! Terus pertahankan!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'milestone',
          'Milestone Bad Habit',
          channelDescription: 'Notifikasi pencapaian milestone',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFD85A30),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // Batalkan reminder
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  // Batalkan semua reminder
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

// ignore: non_constant_identifier_names



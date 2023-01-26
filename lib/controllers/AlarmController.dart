import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:xitem/api/AuthenticationApi.dart';

class AlarmController {
  static const int notificationAlarmID = 420;
  static const TimeOfDay startTime = TimeOfDay(hour: 18, minute:30);

  static void initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> startPeriodic() async {
    return;
    await AndroidAlarmManager.cancel(420);

    DateTime now = DateTime.now();
    DateTime startAt = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);

    if(startAt.isBefore(now)) {
      //startAt.add(const Duration(days: 1));
    }

    print("Periodic Task will start at: $startAt");
    print("Periodic started: ${await AndroidAlarmManager.periodic(const Duration(minutes: 1), notificationAlarmID, _alarmCallback, allowWhileIdle:true, exact: true, wakeup: true, rescheduleOnReboot: true, startAt: startAt)}");
  }

  static void _alarmCallback(int id) {
    print("$id: ${DateTime.now()}");
    AuthenticationApi api = AuthenticationApi();
    api.checkStatus();
  }
}
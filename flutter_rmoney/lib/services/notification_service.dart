import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../models/models.dart';
import '../utils/utils.dart';

final notifications = FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await notifications.initialize(settings);

    const channel = AndroidNotificationChannel(
      'rmoney_reminders',
      'RMoney сануулга',
      description: 'Зардал болон хадгаламжийн өдөр тутмын сануулга',
      importance: Importance.defaultImportance,
    );
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    } else if (Platform.isIOS) {
      await notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> sendNeeded(
      FinanceSummary summary, DateTime now, SavingsPlan plan) async {
    if (summary.overspending) {
      await _show(
        201,
        'Зардал өндөр байна',
        'Хязгаар: ${formatMnt(summary.expectedSpendingToDate)}, зарцуулсан: ${formatMnt(summary.expense)}',
      );
    }
    if (FinanceCalculator.needsUrgentSavingsReminder(summary, now, plan)) {
      await _show(203, 'Хадгаламжаа яаралтай нэмээрэй',
          'Зорилт: ${formatMnt(plan.totalTarget)}, одоо: ${formatMnt(summary.savings)}');
    } else if (FinanceCalculator.needsSavingsReminder(summary, now, plan)) {
      await _show(202, 'Хадгаламжийн сануулга',
          'Зорилт: ${formatMnt(plan.firstAmount)}, одоо: ${formatMnt(summary.savings)}');
    }
  }

  static Future<void> _show(int id, String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'rmoney_reminders',
        'RMoney сануулга',
        channelDescription: 'Зардал болон хадгаламжийн өдөр тутмын сануулга',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await notifications.show(id, title, body, details);
  }
}

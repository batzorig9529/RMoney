import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app/rmoney_app.dart';
import 'constants/app_constants.dart';
import 'services/services.dart';
import 'utils/finance_calculator.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.initialize();
    final store = RMoneyStore();
    final records = await store.load();
    final plan = await store.loadSavingsPlan();
    final now = DateTime.now();
    final summary = FinanceCalculator.summarizeMonth(records, now, now, plan);
    await NotificationService.sendNeeded(summary, now, plan);
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const RMoneyApp());

  unawaited(NotificationService.requestPermission());
  unawaited(AdService.instance.initialize());
  unawaited(_initializeBackgroundWork());
}

Future<void> _initializeBackgroundWork() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    reminderTask,
    reminderTask,
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

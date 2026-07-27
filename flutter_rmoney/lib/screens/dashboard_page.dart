import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage(
      {super.key, required this.records, required this.savingsPlan});

  final List<MoneyRecord> records;
  final SavingsPlan savingsPlan;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary =
        FinanceCalculator.summarizeMonth(records, now, now, savingsPlan);
    final period = FinanceCalculator.periodFor(now);
    final alerts = <Widget>[];
    if (summary.overspending) {
      alerts.add(const AlertCard(
          title: 'Зардал өндөр байна',
          body: 'Одоогийн зардал төлөвлөсөн өдрийн хязгаараас давсан байна.'));
    }
    if (FinanceCalculator.needsUrgentSavingsReminder(
        summary, now, savingsPlan)) {
      alerts.add(AlertCard(
          title: 'Хадгаламж яаралтай',
          body:
              '15-наас хойш зорилтот ${formatMnt(savingsPlan.totalTarget)} хүрээгүй байна.'));
    } else if (FinanceCalculator.needsSavingsReminder(
        summary, now, savingsPlan)) {
      alerts.add(AlertCard(
          title: 'Хадгаламжийн сануулга',
          body:
              '5-наас хойш зорилтот ${formatMnt(savingsPlan.firstAmount)} хүрээгүй байна.'));
    }

    return PageShell(
      title: 'RMoney',
      subtitle: '${FinanceCalculator.periodLabel(period)} санхүүгийн тойм',
      children: [
        SummaryGrid(summary: summary),
        ...alerts,
      ],
    );
  }
}

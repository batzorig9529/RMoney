import 'package:flutter/material.dart';

import '../components/components.dart';
import '../components/finance_scene.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage(
      {super.key,
      required this.records,
      required this.savingsPlan,
      this.onAdd,
      this.onAdvice});

  final List<MoneyRecord> records;
  final SavingsPlan savingsPlan;
  final VoidCallback? onAdd;
  final VoidCallback? onAdvice;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary =
        FinanceCalculator.summarizeMonth(records, now, now, savingsPlan);
    final period = FinanceCalculator.periodFor(now);
    final score = FinanceCalculator.aiScore(summary);
    final statHeight =
        134.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final recent = records
        .where((record) => period.contains(record.date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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
        const SizedBox(height: 8),
        Text('Өнөөдрийн боломж',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(formatMnt(summary.dailyBudget),
                  style: const TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800)),
            )),
        const SizedBox(height: 4),
        Text('${summary.remainingDays} хоног үлдлээ',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
        FinanceScene(summary: summary),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Гүйлгээ нэмэх'))),
          const SizedBox(width: 12),
          IconButton.filledTonal(
              onPressed: onAdvice,
              tooltip: 'AI үнэлгээ',
              icon: const Icon(Icons.auto_awesome),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
        ]),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(
              child: Text('Энэ үеийн тойм',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700))),
          Icon(Icons.circle,
              size: 7, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 6),
          const Text('Одоо', style: TextStyle(fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: SizedBox(
                  height: statHeight,
                  child: StatCard(
                      title: 'Нийт орлого',
                      amount: summary.income,
                      icon: Icons.south_west))),
          const SizedBox(width: 12),
          Expanded(
              child: SizedBox(
                  height: statHeight,
                  child: StatCard(
                      title: 'Нийт зардал',
                      amount: summary.expense,
                      icon: Icons.north_east))),
        ]),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.onSecondaryContainer)),
          title: const Text('Санхүүгийн үнэлгээ',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(FinanceCalculator.aiScoreLabel(score)),
          trailing: Text(score == null ? '-- / 5' : '$score / 5',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          onTap: onAdvice,
        ),
        const Divider(height: 32),
        ...alerts,
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Сүүлийн гүйлгээ',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...recent.take(3).map((record) => RecordTile(record: record)),
        ],
      ],
    );
  }
}

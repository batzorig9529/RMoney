import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class AiAdvicePage extends StatelessWidget {
  const AiAdvicePage({
    super.key,
    required this.records,
    required this.savingsPlan,
  });

  final List<MoneyRecord> records;
  final SavingsPlan savingsPlan;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = FinanceCalculator.periodFor(now);
    final summary =
        FinanceCalculator.summarizeMonth(records, now, now, savingsPlan);
    final adviceItems = FinanceCalculator.aiAdviceItems(summary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI үнэлгээ'),
      ),
      body: PageShell(
        title: 'AI үнэлгээ',
        subtitle: '${FinanceCalculator.periodLabel(period)} зөвлөгөө',
        children: [
          SummaryGrid(
            summary: summary,
            extraItems: [
              ('Үлдсэн хоног', summary.remainingDays, Icons.event_available),
            ],
          ),
          _AdvicePanel(items: adviceItems),
          InfoCard(
            title: 'Товч дүгнэлт',
            body: FinanceCalculator.aiAssessment(summary),
          ),
        ],
      ),
    );
  }
}

class _AdvicePanel extends StatelessWidget {
  const _AdvicePanel({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Зөвлөгөө',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: scheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

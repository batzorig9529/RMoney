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
    final adviceItems = FinanceCalculator.aiAdviceItems(summary, savingsPlan);
    final score = FinanceCalculator.aiScore(summary);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI үнэлгээ'),
      ),
      body: PageShell(
        title: 'AI үнэлгээ',
        subtitle: '${FinanceCalculator.periodLabel(period)} зөвлөгөө',
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score == null ? 'Оноо хараахан гараагүй' : '$score / 5',
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(FinanceCalculator.aiScoreLabel(score),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Semantics(
                  label:
                      score == null ? 'Үнэлгээ байхгүй' : '5-аас $score оноо',
                  child: Row(
                      children: List.generate(
                          5,
                          (index) => Icon(
                                index < (score ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Theme.of(context).colorScheme.primary,
                              ))),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Бүртгэсэн гүйлгээнд үндэслэсэн төсвийн үнэлгээ. Зээлийн оноо биш.'),
                const SizedBox(height: 12),
                ...FinanceCalculator.aiScoreFactors(summary).entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value} / 5'),
                        ]),
                      ),
                    ),
                if (score != null)
                  const Text(
                      'Гурван үзүүлэлтийн дундаж. Зардал орлогод хүрвэл 1; төсвийн үлдэгдэлгүй бол дээд тал нь 2 оноо.'),
              ],
            ),
          ),
          SummaryGrid(
            summary: summary,
            extraItems: [
              ('Үлдсэн хоног', summary.remainingDays, Icons.event_available),
            ],
          ),
          _AdvicePanel(items: adviceItems),
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

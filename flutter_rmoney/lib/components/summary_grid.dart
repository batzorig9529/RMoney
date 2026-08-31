import 'dart:math';

import 'package:flutter/material.dart';

import '../models/finance_summary.dart';
import 'stat_card.dart';

class SummaryGrid extends StatelessWidget {
  const SummaryGrid(
      {super.key, required this.summary, this.extraItems = const []});

  final FinanceSummary summary;
  final List<(String title, int amount, IconData icon)> extraItems;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Орлого', summary.income, Icons.trending_up),
      ('Зардал', summary.expense, Icons.trending_down),
      ('Хадгаламж', summary.savings, Icons.savings_outlined),
      (
        '10% нөөц',
        summary.reservedTenPercent,
        Icons.account_balance_wallet_outlined
      ),
      ('Өдрийн боломж', summary.dailyBudget, Icons.today_outlined),
      ('Үлдсэн мөнгө', summary.remainingMoney, Icons.account_balance_outlined),
      ...extraItems,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 640 ? 3 : 2;
        return LayoutBuilder(
          builder: (context, innerConstraints) {
            const spacing = 10.0;
            final tileWidth =
                (innerConstraints.maxWidth - spacing * (columns - 1)) / columns;
            final textScale =
                MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
            final tileHeight = max(152.0, 124.0 * textScale);
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items
                  .map((item) => SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: StatCard(
                            title: item.$1, amount: item.$2, icon: item.$3),
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }
}

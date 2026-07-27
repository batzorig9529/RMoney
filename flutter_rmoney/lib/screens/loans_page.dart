import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class LoansPage extends StatelessWidget {
  const LoansPage({super.key, required this.records});

  final List<MoneyRecord> records;

  @override
  Widget build(BuildContext context) {
    final balances = FinanceCalculator.openLoanBalances(records);
    return PageShell(
      title: 'Зээлийн мэдээлэл',
      subtitle: 'Үлдэгдэлтэй зээл болон буцаан авалт',
      children: balances.isEmpty
          ? [const EmptyState(text: 'Төлөгдөөгүй зээл алга')]
          : balances.entries.map((entry) {
              final balance = entry.value;
              return InfoCard(
                title: entry.key,
                body:
                    'Зээлсэн: ${formatMnt(balance.given)}\nБуцаан авсан: ${formatMnt(balance.repaid)}\nҮлдэгдэл: ${formatMnt(balance.remaining)}',
              );
            }).toList(),
    );
  }
}

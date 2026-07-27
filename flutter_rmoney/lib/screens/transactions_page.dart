import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../utils/finance_calculator.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.records});

  final List<MoneyRecord> records;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  MoneyType? filterType;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = FinanceCalculator.periodFor(now);
    final monthly = widget.records
        .where((record) => period.contains(record.date))
        .where((record) => filterType == null || record.type == filterType)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return PageShell(
      title: 'Гүйлгээ',
      subtitle: '${FinanceCalculator.periodLabel(period)} бүх бүртгэл',
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: filterType == null,
                  label: const Text('Бүгд'),
                  avatar: const Icon(Icons.all_inclusive, size: 18),
                  onSelected: (_) => setState(() => filterType = null),
                ),
              ),
              ...MoneyType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: filterType == type,
                    label: Text(type.label),
                    avatar: Icon(type.icon, size: 18),
                    onSelected: (_) => setState(() => filterType = type),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: monthly.isEmpty
              ? EmptyState(
                  key: ValueKey(filterType?.storageValue ?? 'all-empty'),
                  text: filterType == null
                      ? 'Энэ сард бүртгэл алга'
                      : '${filterType!.label} бүртгэл алга',
                )
              : Column(
                  key: ValueKey(filterType?.storageValue ?? 'all-list'),
                  children: monthly
                      .map((record) => RecordTile(record: record))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

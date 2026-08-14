import 'package:flutter/material.dart';

import '../components/components.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage(
      {super.key,
      required this.records,
      required this.savingsPlan,
      required this.onSave});

  final List<MoneyRecord> records;
  final SavingsPlan savingsPlan;
  final Future<void> Function(SavingsPlan plan) onSave;

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  late final TextEditingController firstAmount;
  late final TextEditingController secondAmount;
  late int firstDay;
  late int secondDay;

  @override
  void initState() {
    super.initState();
    firstAmount = TextEditingController(
        text: formatMoneyInput(widget.savingsPlan.firstAmount));
    secondAmount = TextEditingController(
        text: formatMoneyInput(widget.savingsPlan.secondAmount));
    firstDay = widget.savingsPlan.firstDay;
    secondDay = widget.savingsPlan.secondDay;
  }

  @override
  void didUpdateWidget(covariant SavingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.savingsPlan != widget.savingsPlan) {
      firstAmount.text = formatMoneyInput(widget.savingsPlan.firstAmount);
      secondAmount.text = formatMoneyInput(widget.savingsPlan.secondAmount);
      firstDay = widget.savingsPlan.firstDay;
      secondDay = widget.savingsPlan.secondDay;
    }
  }

  @override
  void dispose() {
    firstAmount.dispose();
    secondAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = FinanceCalculator.periodFor(now);
    final summary = FinanceCalculator.summarizeMonth(
        widget.records, now, now, widget.savingsPlan);
    final totalSaved = widget.records
        .where((record) => record.type == MoneyType.savings)
        .fold<int>(0, (sum, record) => sum + record.amount);

    return PageShell(
      title: 'Хадгаламж',
      subtitle: '${FinanceCalculator.periodLabel(period)} зорилт',
      children: [
        SummaryGrid(
            summary: summary,
            extraItems: [('Нийт хадгалсан', totalSaved, Icons.savings)]),
        InfoCard(
          title: 'Энэ үеийн зорилт',
          body:
              '${widget.savingsPlan.firstDay}-нд ${formatMnt(widget.savingsPlan.firstAmount)}\n${widget.savingsPlan.secondDay}-нд ${formatMnt(widget.savingsPlan.secondAmount)}\nНийт: ${formatMnt(widget.savingsPlan.totalTarget)}',
        ),
        DropdownButtonFormField<int>(
          value: firstDay,
          decoration: const InputDecoration(labelText: 'Эхний сануулах өдөр'),
          items: List.generate(31, (index) => index + 1)
              .map((day) => DropdownMenuItem(value: day, child: Text('$day')))
              .toList(),
          onChanged: (value) => setState(() => firstDay = value ?? 5),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: firstAmount,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyAmountInputFormatter()],
          decoration: const InputDecoration(
              labelText: 'Эхний хадгалах дүн',
              prefixIcon: Icon(Icons.payments_outlined)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: secondDay,
          decoration:
              const InputDecoration(labelText: 'Дараагийн сануулах өдөр'),
          items: List.generate(31, (index) => index + 1)
              .map((day) => DropdownMenuItem(value: day, child: Text('$day')))
              .toList(),
          onChanged: (value) => setState(() => secondDay = value ?? 15),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: secondAmount,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyAmountInputFormatter()],
          decoration: const InputDecoration(
              labelText: 'Дараагийн хадгалах дүн',
              prefixIcon: Icon(Icons.payments_outlined)),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Зорилт хадгалах'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final first = parseMoneyInput(firstAmount.text);
    final second = parseMoneyInput(secondAmount.text);
    if (firstDay < 1 || secondDay < 1 || first <= 0 || second <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Өдөр болон дүнгээ зөв оруулна уу')),
      );
      return;
    }
    await widget.onSave(SavingsPlan(
      firstDay: firstDay,
      firstAmount: first,
      secondDay: secondDay,
      secondAmount: second,
    ));
  }
}

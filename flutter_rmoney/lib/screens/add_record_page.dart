import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/info_card.dart';
import '../components/page_shell.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key, required this.records, required this.onAdd});

  final List<MoneyRecord> records;
  final Future<void> Function(MoneyRecord record) onAdd;

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final amount = TextEditingController();
  final category = TextEditingController();
  final borrower = TextEditingController();
  final note = TextEditingController();
  var type = MoneyType.income;
  var necessity = 'Зайлшгүй';
  var purchaseCategory = purchaseCategories.first;
  String? selectedRepaymentBorrower;
  var date = DateTime.now();

  @override
  void dispose() {
    amount.dispose();
    category.dispose();
    borrower.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = type == MoneyType.expense;
    final isLoanGiven = type == MoneyType.loanGiven;
    final isLoanRepayment = type == MoneyType.loanRepayment;
    final openLoans = FinanceCalculator.openLoanBalances(widget.records);
    if (isLoanRepayment &&
        openLoans.isNotEmpty &&
        !openLoans.containsKey(selectedRepaymentBorrower)) {
      selectedRepaymentBorrower = openLoans.keys.first;
    }
    return PageShell(
      title: 'Гүйлгээ нэмэх',
      subtitle: 'Орлого, зардал, хадгаламж, зээлээ бүртгэнэ',
      children: [
        DropdownButtonFormField<MoneyType>(
          value: type,
          decoration: const InputDecoration(labelText: 'Төрөл'),
          items: MoneyType.values
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item.label)))
              .toList(),
          onChanged: (value) =>
              setState(() => type = value ?? MoneyType.income),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyAmountInputFormatter()],
          decoration: const InputDecoration(
              labelText: 'Дүн', prefixIcon: Icon(Icons.payments_outlined)),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              );
            },
            child: _dynamicFields(
              key: ValueKey(type),
              isExpense: isExpense,
              isLoanGiven: isLoanGiven,
              isLoanRepayment: isLoanRepayment,
              openLoans: openLoans,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          decoration: const InputDecoration(
              labelText: 'Тэмдэглэл', prefixIcon: Icon(Icons.notes_outlined)),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month),
          label: Text(DateFormat('yyyy-MM-dd').format(date)),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Хадгалах'),
        ),
      ],
    );
  }

  Widget _dynamicFields({
    required Key key,
    required bool isExpense,
    required bool isLoanGiven,
    required bool isLoanRepayment,
    required Map<String, LoanBalance> openLoans,
  }) {
    return Column(
      key: key,
      children: [
        if (isExpense)
          DropdownButtonFormField<String>(
            value: purchaseCategory,
            decoration: const InputDecoration(
                labelText: 'Худалдан авалтын төрөл',
                prefixIcon: Icon(Icons.category_outlined)),
            items: purchaseCategories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(
                () => purchaseCategory = value ?? purchaseCategories.first),
          )
        else
          TextField(
            controller: category,
            decoration: const InputDecoration(
              labelText: 'Ангилал',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
        if (isExpense) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: necessity,
            decoration: const InputDecoration(labelText: 'Зардлын шаардлага'),
            items: const [
              DropdownMenuItem(value: 'Зайлшгүй', child: Text('Зайлшгүй')),
              DropdownMenuItem(
                  value: 'Зайлшгүй бус', child: Text('Зайлшгүй бус')),
            ],
            onChanged: (value) =>
                setState(() => necessity = value ?? 'Зайлшгүй'),
          ),
        ],
        if (isLoanGiven) ...[
          const SizedBox(height: 12),
          TextField(
            controller: borrower,
            decoration: const InputDecoration(
                labelText: 'Хэнд', prefixIcon: Icon(Icons.person_outline)),
          ),
        ],
        if (isLoanRepayment) ...[
          const SizedBox(height: 12),
          if (openLoans.isEmpty)
            const InfoCard(
                title: 'Төлөгдөөгүй зээл алга',
                body:
                    'Бүрэн төлөгдөөгүй зээл байхгүй тул буцаан авалт бүртгэх боломжгүй.')
          else
            DropdownButtonFormField<String>(
              value: selectedRepaymentBorrower,
              decoration: const InputDecoration(
                  labelText: 'Ямар зээлийн төлөлт вэ',
                  prefixIcon: Icon(Icons.person_outline)),
              isExpanded: true,
              selectedItemBuilder: (context) => openLoans.entries
                  .map((entry) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${entry.key} · ${formatMnt(entry.value.remaining)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              items: openLoans.entries
                  .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        '${entry.key}\nҮлдэгдэл: ${formatMnt(entry.value.remaining)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )))
                  .toList(),
              onChanged: (value) =>
                  setState(() => selectedRepaymentBorrower = value),
            ),
        ],
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 370)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: date,
    );
    if (picked != null) {
      setState(() => date = picked);
    }
  }

  Future<void> _save() async {
    final parsedAmount = parseMoneyInput(amount.text);
    final isLoanGiven = type == MoneyType.loanGiven;
    final isLoanRepayment = type == MoneyType.loanRepayment;
    if (parsedAmount <= 0) {
      _toast('Дүнгээ зөв оруулна уу');
      return;
    }
    if (isLoanGiven && borrower.text.trim().isEmpty) {
      _toast('Хэнд гэдэг талбарыг бөглөнө үү');
      return;
    }
    if (isLoanRepayment) {
      final openLoans = FinanceCalculator.openLoanBalances(widget.records);
      final selected = selectedRepaymentBorrower;
      if (selected == null || !openLoans.containsKey(selected)) {
        _toast('Төлөгдөөгүй зээл сонгоно уу');
        return;
      }
      if (parsedAmount > openLoans[selected]!.remaining) {
        _toast('Төлөх дүн үлдэгдлээс их байна');
        return;
      }
    }
    await widget.onAdd(MoneyRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      amount: parsedAmount,
      date: date,
      category:
          type == MoneyType.expense ? purchaseCategory : category.text.trim(),
      necessity: type == MoneyType.expense ? necessity : '',
      borrower: isLoanRepayment
          ? (selectedRepaymentBorrower ?? '')
          : borrower.text.trim(),
      note: note.text.trim(),
    ));
    amount.clear();
    category.clear();
    borrower.clear();
    note.clear();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/info_card.dart';
import '../components/page_shell.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({
    super.key,
    required this.records,
    required this.expenseCategories,
    required this.onAdd,
    required this.onAddExpenseCategory,
  });

  final List<MoneyRecord> records;
  final List<String> expenseCategories;
  final Future<void> Function(MoneyRecord record) onAdd;
  final Future<void> Function(String category) onAddExpenseCategory;

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
  var incomeCategory = incomeCategories.first;
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
    final expenseCategoryOptions = _expenseCategoryOptions();
    if (isExpense && !expenseCategoryOptions.contains(purchaseCategory)) {
      purchaseCategory = expenseCategoryOptions.first;
    }
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
          initialValue: type,
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
                  alignment: Alignment.topCenter,
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
              expenseCategoryOptions: expenseCategoryOptions,
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
    required List<String> expenseCategoryOptions,
  }) {
    return Column(
      key: key,
      children: [
        if (isExpense)
          _ExpenseCategoryPicker(
            value: purchaseCategory,
            categories: expenseCategoryOptions,
            onChanged: (value) => setState(() => purchaseCategory = value),
            onAdd: _addExpenseCategory,
          )
        else if (type == MoneyType.income)
          DropdownButtonFormField<String>(
            initialValue: incomeCategory,
            decoration: const InputDecoration(
              labelText: 'Орлогын төрөл',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: incomeCategories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(
                () => incomeCategory = value ?? incomeCategories.first),
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
            initialValue: necessity,
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
              initialValue: selectedRepaymentBorrower,
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
      category: type == MoneyType.expense
          ? purchaseCategory
          : type == MoneyType.income
              ? incomeCategory
              : category.text.trim(),
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

  List<String> _expenseCategoryOptions() {
    final options = {
      ...purchaseCategories,
      ...widget.expenseCategories,
      purchaseCategory,
    }.where((item) => item.trim().isNotEmpty).toList();
    if (options.isEmpty) return ['Бусад'];
    return options;
  }

  Future<void> _addExpenseCategory() async {
    final added = await showDialog<String>(
      context: context,
      builder: (context) => const _AddExpenseCategoryDialog(),
    );
    final trimmed = added?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await widget.onAddExpenseCategory(trimmed);
    if (mounted) {
      setState(() => purchaseCategory = trimmed);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ExpenseCategoryPicker extends StatelessWidget {
  const _ExpenseCategoryPicker({
    required this.value,
    required this.categories,
    required this.onChanged,
    required this.onAdd,
  });

  final String value;
  final List<String> categories;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: categories.contains(value) ? value : categories.first,
            decoration: const InputDecoration(
              labelText: 'Худалдан авалтын төрөл',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            isExpanded: true,
            items: categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => onChanged(value ?? categories.first),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Төрөл нэмэх',
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _AddExpenseCategoryDialog extends StatefulWidget {
  const _AddExpenseCategoryDialog();

  @override
  State<_AddExpenseCategoryDialog> createState() =>
      _AddExpenseCategoryDialogState();
}

class _AddExpenseCategoryDialogState extends State<_AddExpenseCategoryDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Зардлын төрөл нэмэх'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Шинэ төрөл',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Болих'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Нэмэх'),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.pop(context, controller.text.trim());
  }
}

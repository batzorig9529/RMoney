import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/components.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.records,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<MoneyRecord> records;
  final Future<void> Function(MoneyRecord record) onUpdate;
  final Future<void> Function(MoneyRecord record) onDelete;

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
                      .map((record) => RecordTile(
                            record: record,
                            onEdit: () => _editRecord(record),
                            onDelete: () => _confirmDelete(record),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _editRecord(MoneyRecord record) async {
    final updated = await showModalBottomSheet<MoneyRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _EditRecordSheet(record: record, records: widget.records),
    );
    if (updated != null) {
      await widget.onUpdate(updated);
    }
  }

  Future<void> _confirmDelete(MoneyRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Устгах уу?'),
        content: Text(
          '${record.type.label} - ${formatMnt(record.amount)} бүртгэлийг устгана.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Устгах'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onDelete(record);
    }
  }
}

class _EditRecordSheet extends StatefulWidget {
  const _EditRecordSheet({required this.record, required this.records});

  final MoneyRecord record;
  final List<MoneyRecord> records;

  @override
  State<_EditRecordSheet> createState() => _EditRecordSheetState();
}

class _EditRecordSheetState extends State<_EditRecordSheet> {
  late final TextEditingController amount;
  late final TextEditingController category;
  late final TextEditingController borrower;
  late final TextEditingController note;
  late MoneyType type;
  late String necessity;
  late String purchaseCategory;
  late DateTime date;
  String? selectedRepaymentBorrower;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    amount = TextEditingController(text: formatMoneyInput(record.amount));
    category = TextEditingController(
      text: record.type == MoneyType.expense ? '' : record.category,
    );
    borrower = TextEditingController(
      text: record.type == MoneyType.loanRepayment ? '' : record.borrower,
    );
    note = TextEditingController(text: record.note);
    type = record.type;
    necessity = record.necessity.isEmpty ? 'Зайлшгүй' : record.necessity;
    purchaseCategory = purchaseCategories.contains(record.category)
        ? record.category
        : purchaseCategories.first;
    selectedRepaymentBorrower =
        record.type == MoneyType.loanRepayment ? record.borrower : null;
    date = record.date;
  }

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
    final editableRecords = widget.records
        .where((record) => record.id != widget.record.id)
        .toList();
    final openLoans = FinanceCalculator.openLoanBalances(editableRecords);
    if (isLoanRepayment &&
        openLoans.isNotEmpty &&
        !openLoans.containsKey(selectedRepaymentBorrower)) {
      selectedRepaymentBorrower = openLoans.keys.first;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Бүртгэл засах',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                labelText: 'Дүн',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (isExpense)
              DropdownButtonFormField<String>(
                initialValue: purchaseCategory,
                decoration: const InputDecoration(
                  labelText: 'Худалдан авалтын төрөл',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: purchaseCategories
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
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
                initialValue: necessity,
                decoration:
                    const InputDecoration(labelText: 'Зардлын шаардлага'),
                items: const [
                  DropdownMenuItem(value: 'Зайлшгүй', child: Text('Зайлшгүй')),
                  DropdownMenuItem(
                    value: 'Зайлшгүй бус',
                    child: Text('Зайлшгүй бус'),
                  ),
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
                  labelText: 'Хэнд',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ],
            if (isLoanRepayment) ...[
              const SizedBox(height: 12),
              if (openLoans.isEmpty)
                const InfoCard(
                  title: 'Төлөгдөөгүй зээл алга',
                  body: 'Бүрэн төлөгдөөгүй зээл байхгүй байна.',
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: selectedRepaymentBorrower,
                  decoration: const InputDecoration(
                    labelText: 'Ямар зээлийн төлөлт вэ',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  isExpanded: true,
                  items: openLoans.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              '${entry.key}\nҮлдэгдэл: ${formatMnt(entry.value.remaining)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedRepaymentBorrower = value),
                ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Тэмдэглэл',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(DateFormat('yyyy-MM-dd').format(date)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _save(openLoans),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Засах'),
            ),
          ],
        ),
      ),
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

  void _save(Map<String, LoanBalance> openLoans) {
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

    Navigator.pop(
      context,
      widget.record.copyWith(
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
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

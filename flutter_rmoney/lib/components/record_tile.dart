import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../utils/money_formatter.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record});

  final MoneyRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = [
      DateFormat('yyyy-MM-dd').format(record.date),
      if (record.category.isNotEmpty) 'Ангилал: ${record.category}',
      if (record.necessity.isNotEmpty) record.necessity,
      if (record.borrower.isNotEmpty) 'Хэнд: ${record.borrower}',
      if (record.note.isNotEmpty) record.note,
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: scheme.surfaceContainer,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: Icon(record.type.icon, size: 22),
        ),
        title: Text('${record.type.label} - ${formatMnt(record.amount)}'),
        subtitle: Text(parts.join('\n')),
      ),
    );
  }
}

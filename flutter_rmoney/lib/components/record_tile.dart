import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../utils/money_formatter.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.record,
    this.onEdit,
    this.onDelete,
  });

  final MoneyRecord record;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
        trailing: onEdit == null && onDelete == null
            ? null
            : PopupMenuButton<_RecordAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case _RecordAction.edit:
                      onEdit?.call();
                    case _RecordAction.delete:
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: _RecordAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Засах'),
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: _RecordAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Устгах'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

enum _RecordAction { edit, delete }

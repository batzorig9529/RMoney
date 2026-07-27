import 'money_type.dart';

class MoneyRecord {
  const MoneyRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
    this.category = '',
    this.necessity = '',
    this.borrower = '',
  });

  final String id;
  final MoneyType type;
  final int amount;
  final DateTime date;
  final String note;
  final String category;
  final String necessity;
  final String borrower;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.storageValue,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'category': category,
        'necessity': necessity,
        'borrower': borrower,
      };

  factory MoneyRecord.fromJson(Map<String, dynamic> json) {
    return MoneyRecord(
      id: json['id']?.toString() ?? '',
      type: MoneyType.fromStorage(json['type']?.toString() ?? ''),
      amount: (json['amount'] as num?)?.round() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      note: json['note']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      necessity: json['necessity']?.toString() ?? '',
      borrower: json['borrower']?.toString() ?? '',
    );
  }
}

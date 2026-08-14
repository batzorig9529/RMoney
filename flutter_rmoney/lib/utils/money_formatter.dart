import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _mntNumberFormat = NumberFormat('#,###', 'en_US');

String formatMnt(int amount) {
  return '${_mntNumberFormat.format(amount)} MNT';
}

String formatMoneyInput(int amount) {
  return _mntNumberFormat.format(amount);
}

int parseMoneyInput(String value) {
  return int.tryParse(value.replaceAll(',', '').trim()) ?? 0;
}

class MoneyAmountInputFormatter extends TextInputFormatter {
  const MoneyAmountInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final amount = int.parse(digits);
    final formatted = formatMoneyInput(amount);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

import 'package:flutter/material.dart';

enum MoneyType {
  income('Орлого', 'income', Icons.trending_up),
  expense('Зардал', 'expense', Icons.trending_down),
  savings('Хадгаламж', 'savings', Icons.savings_outlined),
  loanGiven('Зээл өгөх', 'loan_given', Icons.call_made),
  loanRepayment('Зээл буцаан авах', 'loan_repayment', Icons.call_received);

  const MoneyType(this.label, this.storageValue, this.icon);

  final String label;
  final String storageValue;
  final IconData icon;

  static MoneyType fromStorage(String value) {
    return MoneyType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => MoneyType.income,
    );
  }
}

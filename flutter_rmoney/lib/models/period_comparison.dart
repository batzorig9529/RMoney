import 'finance_period.dart';

class PeriodComparison {
  const PeriodComparison({
    required this.period,
    required this.income,
    required this.expense,
    required this.savings,
  });

  final FinancePeriod period;
  final int income;
  final int expense;
  final int savings;

  String get shortLabel {
    final month = period.start.month.toString().padLeft(2, '0');
    return '${period.start.year % 100}/$month';
  }
}

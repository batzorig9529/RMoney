class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expense,
    required this.savings,
    required this.reservedTenPercent,
    required this.dailyBudget,
    required this.remainingDays,
    required this.remainingMoney,
    required this.expectedSpendingToDate,
    required this.overspending,
    required this.expensesByCategory,
    required this.expensesByNecessity,
    required this.reportBreakdown,
    required this.extraOutflowBreakdown,
  });

  final int income;
  final int expense;
  final int savings;
  final int reservedTenPercent;
  final int dailyBudget;
  final int remainingDays;
  final int remainingMoney;
  final int expectedSpendingToDate;
  final bool overspending;
  final Map<String, int> expensesByCategory;
  final Map<String, int> expensesByNecessity;
  final Map<String, int> reportBreakdown;
  final Map<String, int> extraOutflowBreakdown;
}

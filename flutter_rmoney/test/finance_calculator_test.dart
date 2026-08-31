import 'package:flutter_test/flutter_test.dart';
import 'package:rmoney_flutter/models/models.dart';
import 'package:rmoney_flutter/utils/finance_calculator.dart';

void main() {
  test('period summary reserves 10 percent and includes loan repayment income',
      () {
    final month = DateTime(2026, 7, 5);
    final today = DateTime(2026, 7, 10);
    final records = [
      MoneyRecord(
          id: 'old',
          type: MoneyType.income,
          amount: 999999,
          date: DateTime(2026, 7, 4)),
      MoneyRecord(
          id: '1',
          type: MoneyType.income,
          amount: 2000000,
          date: DateTime(2026, 7, 5)),
      MoneyRecord(
          id: '2',
          type: MoneyType.loanRepayment,
          amount: 200000,
          date: DateTime(2026, 8, 4)),
      MoneyRecord(
          id: '3',
          type: MoneyType.expense,
          amount: 100000,
          date: DateTime(2026, 7, 10)),
    ];

    final summary = FinanceCalculator.summarizeMonth(records, month, today);

    expect(summary.income, 2200000);
    expect(summary.reservedTenPercent, 220000);
    expect(
        summary.dailyBudget,
        ((2200000 - 220000 - const SavingsPlan().totalTarget - 100000) / 26)
            .floor());
    expect(summary.expense, 100000);
  });

  test('expense totals are grouped by necessity and purchase category', () {
    final month = DateTime(2026, 7, 5);
    final records = [
      MoneyRecord(
        id: '1',
        type: MoneyType.expense,
        amount: 80000,
        date: DateTime(2026, 7, 6),
        category: 'Хоол хүнс',
        necessity: 'Зайлшгүй',
      ),
      MoneyRecord(
        id: '2',
        type: MoneyType.expense,
        amount: 40000,
        date: DateTime(2026, 8, 4),
        category: 'Дэлгүүр',
        necessity: 'Зайлшгүй бус',
      ),
    ];

    final summary = FinanceCalculator.summarizeMonth(records, month, month);

    expect(summary.expensesByCategory['Хоол хүнс'], 80000);
    expect(summary.expensesByCategory['Дэлгүүр'], 40000);
    expect(summary.expensesByNecessity['Зайлшгүй'], 80000);
    expect(summary.expensesByNecessity['Зайлшгүй бус'], 40000);
  });

  test('six month pruning keeps current and previous five months', () {
    final records = [
      MoneyRecord(
          id: '1',
          type: MoneyType.income,
          amount: 1,
          date: DateTime(2026, 2, 5)),
      MoneyRecord(
          id: '2',
          type: MoneyType.income,
          amount: 1,
          date: DateTime(2026, 2, 4)),
    ];

    final result =
        FinanceCalculator.latestSixMonths(records, DateTime(2026, 7));

    expect(result.length, 1);
    expect(result.single.date.day, 5);
  });

  test('finance period starts on the 5th and ends before next 5th', () {
    final period = FinanceCalculator.periodFor(DateTime(2026, 7, 25));

    expect(period.start, DateTime(2026, 7, 5));
    expect(period.end, DateTime(2026, 8, 5));
    expect(period.contains(DateTime(2026, 7, 4)), isFalse);
    expect(period.contains(DateTime(2026, 7, 5)), isTrue);
    expect(period.contains(DateTime(2026, 8, 4)), isTrue);
    expect(period.contains(DateTime(2026, 8, 5)), isFalse);
  });

  test('savings reminders follow day 5 and day 15 rules', () {
    const summary = FinanceSummary(
      income: 0,
      expense: 0,
      savings: 499999,
      reservedTenPercent: 0,
      dailyBudget: 0,
      remainingDays: 1,
      remainingMoney: 0,
      expectedSpendingToDate: 0,
      overspending: false,
      expensesByCategory: {},
      expensesByNecessity: {},
      reportBreakdown: {},
      extraOutflowBreakdown: {},
    );

    expect(
        FinanceCalculator.needsSavingsReminder(
            summary, DateTime(2026, 7, 5), const SavingsPlan()),
        isTrue);
    expect(
        FinanceCalculator.needsUrgentSavingsReminder(
            summary, DateTime(2026, 7, 15), const SavingsPlan()),
        isTrue);
  });

  test('report graph includes savings and unpaid loans', () {
    final records = [
      MoneyRecord(
          id: 'expense',
          type: MoneyType.expense,
          amount: 100000,
          date: DateTime(2026, 7, 6),
          category: 'Хоол хүнс',
          necessity: 'Зайлшгүй'),
      MoneyRecord(
          id: 'saving',
          type: MoneyType.savings,
          amount: 500000,
          date: DateTime(2026, 7, 7)),
      MoneyRecord(
          id: 'loan',
          type: MoneyType.loanGiven,
          amount: 300000,
          date: DateTime(2026, 7, 8),
          borrower: 'Бат'),
      MoneyRecord(
          id: 'repay',
          type: MoneyType.loanRepayment,
          amount: 100000,
          date: DateTime(2026, 7, 9),
          borrower: 'Бат'),
    ];

    final summary = FinanceCalculator.summarizeMonth(
        records, DateTime(2026, 7, 10), DateTime(2026, 7, 10));

    expect(summary.reportBreakdown['Хоол хүнс'], 100000);
    expect(summary.reportBreakdown['Хадгаламж'], 500000);
    expect(summary.reportBreakdown['Төлөгдөөгүй зээл'], 200000);
  });

  test('open loan balances hide fully paid loans', () {
    final records = [
      MoneyRecord(
          id: 'loan1',
          type: MoneyType.loanGiven,
          amount: 100000,
          date: DateTime(2026, 7, 5),
          borrower: 'Бат'),
      MoneyRecord(
          id: 'paid',
          type: MoneyType.loanRepayment,
          amount: 100000,
          date: DateTime(2026, 7, 6),
          borrower: 'Бат'),
      MoneyRecord(
          id: 'loan2',
          type: MoneyType.loanGiven,
          amount: 200000,
          date: DateTime(2026, 7, 7),
          borrower: 'Сараа'),
    ];

    final balances = FinanceCalculator.openLoanBalances(records);

    expect(balances.containsKey('Бат'), isFalse);
    expect(balances['Сараа']?.remaining, 200000);
  });

  test('last six period comparisons include current and previous periods', () {
    final records = [
      MoneyRecord(
          id: 'old',
          type: MoneyType.expense,
          amount: 10000,
          date: DateTime(2026, 2, 5)),
      MoneyRecord(
          id: 'current',
          type: MoneyType.expense,
          amount: 50000,
          date: DateTime(2026, 7, 6)),
      MoneyRecord(
          id: 'income',
          type: MoneyType.income,
          amount: 100000,
          date: DateTime(2026, 7, 7)),
    ];

    final comparisons = FinanceCalculator.lastSixPeriodComparisons(
        records, DateTime(2026, 7, 27));

    expect(comparisons.length, 6);
    expect(comparisons.first.period.start, DateTime(2026, 2, 5));
    expect(comparisons.last.period.start, DateTime(2026, 7, 5));
    expect(comparisons.first.expense, 10000);
    expect(comparisons.last.expense, 50000);
    expect(comparisons.last.income, 100000);
  });

  test('ai assessment explains missing income and daily budget', () {
    final emptySummary = FinanceCalculator.summarizeMonth(
      const [],
      DateTime(2026, 7, 10),
      DateTime(2026, 7, 10),
    );

    expect(FinanceCalculator.aiAssessment(emptySummary), contains('орлого'));
    expect(FinanceCalculator.aiAdviceItems(emptySummary), isNotEmpty);

    final summary = FinanceCalculator.summarizeMonth(
      [
        MoneyRecord(
          id: 'income',
          type: MoneyType.income,
          amount: 2000000,
          date: DateTime(2026, 7, 5),
        ),
        MoneyRecord(
          id: 'expense',
          type: MoneyType.expense,
          amount: 200000,
          date: DateTime(2026, 7, 6),
        ),
      ],
      DateTime(2026, 7, 10),
      DateTime(2026, 7, 10),
    );

    expect(FinanceCalculator.aiAssessment(summary), contains('Өдөрт'));
    expect(FinanceCalculator.aiAdviceItems(summary), isNotEmpty);
  });
}

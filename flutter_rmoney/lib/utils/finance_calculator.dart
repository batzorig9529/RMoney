import 'dart:math';

import 'package:intl/intl.dart';

import '../models/models.dart';

class FinanceCalculator {
  static FinanceSummary summarizeMonth(
    List<MoneyRecord> records,
    DateTime selectedMonth,
    DateTime today, [
    SavingsPlan savingsPlan = const SavingsPlan(),
  ]) {
    final period = periodFor(selectedMonth);
    var income = 0;
    var expense = 0;
    var savings = 0;
    final byCategory = <String, int>{};
    final byNecessity = <String, int>{};
    final extraOutflow = <String, int>{};

    for (final record in records) {
      if (!period.contains(record.date)) continue;
      if (record.type == MoneyType.income ||
          record.type == MoneyType.loanRepayment) {
        income += record.amount;
      } else if (record.type == MoneyType.expense) {
        expense += record.amount;
        _add(byCategory, _nonEmpty(record.category), record.amount);
        _add(byNecessity, _nonEmpty(record.necessity), record.amount);
      } else if (record.type == MoneyType.savings) {
        savings += record.amount;
      }
    }

    final reserved = (income * 0.10).round();
    final daysInPeriod = period.end.difference(period.start).inDays;
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final remainingDays = max(1, period.end.difference(normalizedToday).inDays);
    final protectedSavings = max<int>(savings, savingsPlan.totalTarget);
    final remainingMoney = income - reserved - protectedSavings - expense;
    final dailyBudget = max<int>(0, (remainingMoney / remainingDays).floor());
    final dayForLimit = period.dayNumber(today);
    final originalDailyBudget = max(0,
        ((income - reserved - savingsPlan.totalTarget) / daysInPeriod).floor());
    final expected = originalDailyBudget * dayForLimit;
    if (savings > 0) {
      extraOutflow['Хадгаламж'] = savings;
    }
    final unpaidLoan = openLoanBalances(records)
        .values
        .fold<int>(0, (sum, balance) => sum + balance.remaining);
    if (unpaidLoan > 0) {
      extraOutflow['Төлөгдөөгүй зээл'] = unpaidLoan;
    }
    final reportBreakdown = <String, int>{...byCategory, ...extraOutflow};

    return FinanceSummary(
      income: income,
      expense: expense,
      savings: savings,
      reservedTenPercent: reserved,
      dailyBudget: dailyBudget,
      remainingDays: remainingDays,
      remainingMoney: max<int>(0, remainingMoney),
      expectedSpendingToDate: expected,
      overspending: dailyBudget > 0 && expense > expected,
      expensesByCategory: byCategory,
      expensesByNecessity: byNecessity,
      reportBreakdown: reportBreakdown,
      extraOutflowBreakdown: extraOutflow,
    );
  }

  static List<MoneyRecord> latestSixMonths(
      List<MoneyRecord> records, DateTime now) {
    final threshold = DateTime(now.year, now.month - 5, 5);
    return records.where((record) => !record.date.isBefore(threshold)).toList();
  }

  static List<PeriodComparison> lastSixPeriodComparisons(
      List<MoneyRecord> records, DateTime anchor) {
    final current = periodFor(anchor);
    final periods = List.generate(6, (index) {
      final start =
          DateTime(current.start.year, current.start.month - (5 - index), 5);
      return FinancePeriod(
          start: start, end: DateTime(start.year, start.month + 1, 5));
    });

    return periods.map((period) {
      var income = 0;
      var expense = 0;
      var savings = 0;
      for (final record in records) {
        if (!period.contains(record.date)) continue;
        if (record.type == MoneyType.income ||
            record.type == MoneyType.loanRepayment) {
          income += record.amount;
        } else if (record.type == MoneyType.expense) {
          expense += record.amount;
        } else if (record.type == MoneyType.savings) {
          savings += record.amount;
        }
      }
      return PeriodComparison(
        period: period,
        income: income,
        expense: expense,
        savings: savings,
      );
    }).toList();
  }

  static Map<String, (int given, int repaid)> loanBalances(
      List<MoneyRecord> records) {
    final balances = <String, (int, int)>{};
    for (final record in records) {
      final name = record.borrower.trim();
      if (name.isEmpty) continue;
      final current = balances[name] ?? (0, 0);
      if (record.type == MoneyType.loanGiven) {
        balances[name] = (current.$1 + record.amount, current.$2);
      } else if (record.type == MoneyType.loanRepayment) {
        balances[name] = (current.$1, current.$2 + record.amount);
      }
    }
    return balances;
  }

  static Map<String, LoanBalance> openLoanBalances(List<MoneyRecord> records) {
    final balances = <String, LoanBalance>{};
    for (final entry in loanBalances(records).entries) {
      final balance =
          LoanBalance(given: entry.value.$1, repaid: entry.value.$2);
      if (balance.remaining > 0) {
        balances[entry.key] = balance;
      }
    }
    return balances;
  }

  static bool needsSavingsReminder(
      FinanceSummary summary, DateTime today, SavingsPlan plan) {
    return today.day >= plan.firstDay && summary.savings < plan.firstAmount;
  }

  static bool needsUrgentSavingsReminder(
      FinanceSummary summary, DateTime today, SavingsPlan plan) {
    return today.day >= plan.secondDay && summary.savings < plan.totalTarget;
  }

  static String aiAssessment(FinanceSummary summary) {
    return aiAdviceItems(summary).join('\n');
  }

  static List<String> aiAdviceItems(FinanceSummary summary) {
    if (summary.income <= 0) {
      return [
        'Энэ үед орлого бүртгэгдээгүй байна.',
        'Орлогоо нэмбэл өдрийн боломж болон зарцуулалтын үнэлгээ илүү бодитой гарна.',
      ];
    }

    final expenseRate = summary.expense / summary.income;
    final savingsTargetMet = summary.savings >= summary.reservedTenPercent;
    final lines = <String>[];

    if (expenseRate >= 0.75) {
      lines.add(
          'Зардал орлогын ${(expenseRate * 100).round()}%-д хүрсэн байна. Зайлшгүй бус зардлаа түр хязгаарлах нь зөв.');
    } else if (expenseRate >= 0.5) {
      lines.add(
          'Зардал дунд түвшинд байна. Том худалдан авалтаа үлдсэн хоногийн өдрийн боломжтой тулгаж шийдээрэй.');
    } else {
      lines.add(
          'Зардлын харьцаа боломжийн байна. Энэ хэмнэлээ хадгалбал сарын төгсгөлд илүү тайван үлдэгдэлтэй байна.');
    }

    if (summary.dailyBudget <= 0) {
      lines.add(
          'Үлдсэн өдрийн боломж 0 болсон тул нэмэлт орлого орох хүртэл шинэ зардал нэмэхгүй байхыг санал болгож байна.');
    } else {
      lines.add(
          'Өдөрт дунджаар ${NumberFormat.decimalPattern().format(summary.dailyBudget)} төгрөг зарцуулах боломжтой.');
    }

    if (!savingsTargetMet) {
      lines.add('10% нөөц/хадгаламжийн түвшин дутуу байна.');
    } else {
      lines.add('Нөөц бүрдүүлэлт сайн байна.');
    }

    return lines;
  }

  static bool sameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  static FinancePeriod periodFor(DateTime anchor) {
    final normalized = DateTime(anchor.year, anchor.month, anchor.day);
    final start = normalized.day >= 5
        ? DateTime(normalized.year, normalized.month, 5)
        : DateTime(normalized.year, normalized.month - 1, 5);
    return FinancePeriod(
        start: start, end: DateTime(start.year, start.month + 1, 5));
  }

  static String periodLabel(FinancePeriod period) {
    final format = DateFormat('yyyy-MM-dd');
    return '${format.format(period.start)} - ${format.format(period.end)}';
  }

  static void _add(Map<String, int> map, String key, int amount) {
    map[key] = (map[key] ?? 0) + amount;
  }

  static String _nonEmpty(String value) =>
      value.trim().isEmpty ? 'Бусад' : value.trim();
}

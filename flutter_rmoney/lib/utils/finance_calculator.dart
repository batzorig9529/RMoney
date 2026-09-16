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
    final remainingMoney = income - reserved - savings - expense;
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

  // A budgeting indicator for recorded activity, not a credit rating.
  static Map<String, int> aiScoreFactors(FinanceSummary summary) {
    if (summary.income <= 0) return {};
    final expenseRate = summary.expense / summary.income;
    final savingsRate = summary.savings / summary.income;
    final pace = summary.expectedSpendingToDate;
    return {
      'Зардал / орлого': expenseRate <= 0.5
          ? 5
          : expenseRate <= 0.65
              ? 4
              : expenseRate <= 0.8
                  ? 3
                  : expenseRate < 1
                      ? 2
                      : 1,
      'Хадгаламж / орлого': savingsRate >= 0.2
          ? 5
          : savingsRate >= 0.15
              ? 4
              : savingsRate >= 0.1
                  ? 3
                  : savingsRate > 0
                      ? 2
                      : 1,
      'Төсвийн хэмнэл': summary.expense == 0
          ? 5
          : pace <= 0
              ? 1
              : summary.expense <= pace
                  ? 5
                  : summary.expense <= pace * 1.1
                      ? 4
                      : summary.expense <= pace * 1.25
                          ? 3
                          : summary.expense <= pace * 1.5
                              ? 2
                              : 1,
    };
  }

  static int? aiScore(FinanceSummary summary) {
    final factors = aiScoreFactors(summary);
    if (factors.isEmpty) return null;
    if (summary.expense >= summary.income) return 1;
    final score =
        (factors.values.reduce((a, b) => a + b) / factors.length).round();
    return summary.remainingMoney <= 0 ? min(2, score) : score;
  }

  static String aiScoreLabel(int? score) => switch (score) {
        1 => 'Анхаарал шаардлагатай',
        2 => 'Сайжруулах хэрэгтэй',
        3 => 'Дундаж',
        4 => 'Сайн',
        5 => 'Маш сайн',
        _ => 'Мэдээлэл дутуу',
      };

  static List<String> aiAdviceItems(FinanceSummary summary,
      [SavingsPlan? plan]) {
    if (summary.income <= 0) {
      return [
        'Энэ үед орлого бүртгэгдээгүй байна.',
        'Орлогоо нэмбэл өдрийн боломж болон зарцуулалтын үнэлгээ илүү бодитой гарна.',
      ];
    }

    final expenseRate = summary.expense / summary.income;
    final target = max(summary.reservedTenPercent, plan?.totalTarget ?? 0);
    final savingsTargetMet = summary.savings >= target;
    String money(int value) =>
        '${NumberFormat.decimalPattern().format(value)} ₮';
    final lines = <String>[];

    if (summary.expense >= summary.income) {
      lines.add(
          'Зардал орлогод хүрсэн эсвэл давсан байна. Зөрүү: ${money(summary.expense - summary.income)}. Эхлээд зайлшгүй төлбөрүүдээ эрэмбэлж, хойшлуулж болох худалдан авалтаа түр азнаарай.');
    }

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
          'Нөөц болон хадгаламжийн зорилгыг тооцсоны дараах өдрийн төсөв 0 байна. Зайлшгүй төлбөрөө шалгаж, хадгаламжийн зорилгоо бодит орлоготойгоо тохируулаарай.');
    } else {
      lines.add(
          'Өдөрт дунджаар ${NumberFormat.decimalPattern().format(summary.dailyBudget)} төгрөг зарцуулах боломжтой.');
    }

    if (!savingsTargetMet) {
      final gap = target - summary.savings;
      lines.add(
          'Хадгаламжийн зорилгод ${money(gap)} дутуу байна. Үлдсэн ${summary.remainingDays} хоногт өдөрт ${money((gap / summary.remainingDays).ceil())} хуримтлуулах шаардлагатай. Зайлшгүй зардлын дараах бодит үлдэгдэлдээ тааруулж төлөвлөөрэй.');
    } else {
      lines.add('Нөөц бүрдүүлэлт сайн байна.');
    }

    if (summary.expense > summary.expectedSpendingToDate) {
      lines.add(
          'Энэ өдрийн төлөвлөсөн зардлаас ${money(summary.expense - summary.expectedSpendingToDate)} илүү зарцуулсан байна. Үлдсэн хугацааны өдрийн төсвөө баримтлаарай.');
    }
    final optional = summary.expensesByNecessity['Зайлшгүй бус'] ?? 0;
    if (optional > 0) {
      lines.add(
          'Зайлшгүй бус зардал ${money(optional)} байна. Үүнийг 20% бууруулбал ${money((optional * 0.2).round())} хэмнэх боломжтой.');
    }
    final categories = summary.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (categories.isNotEmpty && summary.expense > 0) {
      final largest = categories.first;
      lines.add(
          'Хамгийн их зардал: ${largest.key}, ${money(largest.value)} (${(largest.value / summary.expense * 100).round()}%). Энэ ангиллын давтагддаг төлбөрүүдээ шалгаарай.');
    }
    final receivable = summary.extraOutflowBreakdown['Төлөгдөөгүй зээл'] ?? 0;
    if (receivable > 0) {
      lines.add(
          'Бусдад өгсөн зээлийн ${money(receivable)} авлага байна. Буцаан авах хугацаагаа тохирч, орж ирэх хүртэл зарцуулах мөнгөндөө бүү тооцоорой.');
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

package com.example.rmoney;

import org.junit.Test;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class FinanceCalculatorTest {
    private final FinanceCalculator calculator = new FinanceCalculator();

    @Test
    public void monthlySummaryReservesTenPercentAndIncludesLoanRepaymentIncome() {
        Calendar month = FinanceCalculator.month(2026, Calendar.JULY);
        Calendar today = FinanceCalculator.month(2026, Calendar.JULY);
        today.set(Calendar.DAY_OF_MONTH, 10);
        List<TransactionRecord> records = new ArrayList<>();
        records.add(record(TransactionRecord.TYPE_INCOME, 1_000_000, month));
        records.add(record(TransactionRecord.TYPE_LOAN_REPAYMENT, 200_000, month));
        records.add(record(TransactionRecord.TYPE_EXPENSE, 100_000, month));

        FinanceSummary summary = calculator.summarizeMonth(records, month, today);

        assertEquals(1_200_000, summary.income);
        assertEquals(120_000, summary.reservedTenPercent);
        assertEquals((1_200_000 - 120_000 - FinanceCalculator.SAVINGS_TARGET) / 31, summary.dailyBudget);
        assertEquals(100_000, summary.expense);
    }

    @Test
    public void expenseTotalsAreGroupedByNecessityAndCategory() {
        Calendar month = FinanceCalculator.month(2026, Calendar.JULY);
        TransactionRecord food = record(TransactionRecord.TYPE_EXPENSE, 80_000, month);
        food.category = "Хоол";
        food.necessity = "Зайлшгүй";
        TransactionRecord shopping = record(TransactionRecord.TYPE_EXPENSE, 40_000, month);
        shopping.category = "Дэлгүүр";
        shopping.necessity = "Зайлшгүй бус";

        List<TransactionRecord> records = new ArrayList<>();
        records.add(food);
        records.add(shopping);

        FinanceSummary summary = calculator.summarizeMonth(records, month, month);

        assertEquals(Long.valueOf(80_000), summary.expensesByCategory.get("Хоол"));
        assertEquals(Long.valueOf(40_000), summary.expensesByCategory.get("Дэлгүүр"));
        assertEquals(Long.valueOf(80_000), summary.expensesByNecessity.get("Зайлшгүй"));
        assertEquals(Long.valueOf(40_000), summary.expensesByNecessity.get("Зайлшгүй бус"));
    }

    @Test
    public void sixMonthPruningKeepsCurrentAndPreviousFiveMonths() {
        Calendar now = FinanceCalculator.month(2026, Calendar.JULY);
        List<TransactionRecord> records = new ArrayList<>();
        records.add(record(TransactionRecord.TYPE_INCOME, 1, FinanceCalculator.month(2026, Calendar.FEBRUARY)));
        records.add(record(TransactionRecord.TYPE_INCOME, 1, FinanceCalculator.month(2026, Calendar.JANUARY)));

        List<TransactionRecord> result = calculator.filterLatestSixMonths(records, now);

        assertEquals(1, result.size());
        Calendar kept = Calendar.getInstance();
        kept.setTimeInMillis(result.get(0).dateMillis);
        assertEquals(Calendar.FEBRUARY, kept.get(Calendar.MONTH));
    }

    @Test
    public void remindersFollowSavingsRules() {
        FinanceSummary summary = new FinanceSummary();
        summary.savings = 499_999;
        Calendar fifth = FinanceCalculator.month(2026, Calendar.JULY);
        fifth.set(Calendar.DAY_OF_MONTH, 5);
        Calendar fifteenth = FinanceCalculator.month(2026, Calendar.JULY);
        fifteenth.set(Calendar.DAY_OF_MONTH, 15);

        assertTrue(calculator.needsSavingsReminder(summary, fifth));
        assertTrue(calculator.needsUrgentSavingsReminder(summary, fifteenth));
        summary.savings = 500_000;
        assertFalse(calculator.needsSavingsReminder(summary, fifteenth));
    }

    private TransactionRecord record(String type, long amount, Calendar date) {
        return new TransactionRecord(type + amount, type, amount, date.getTimeInMillis());
    }
}

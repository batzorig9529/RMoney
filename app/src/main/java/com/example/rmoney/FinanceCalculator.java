package com.example.rmoney;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class FinanceCalculator {
    public static final long SAVINGS_TARGET = 500_000L;

    public FinanceSummary summarizeMonth(List<TransactionRecord> records, Calendar selectedMonth, Calendar today) {
        FinanceSummary summary = new FinanceSummary();
        int selectedYear = selectedMonth.get(Calendar.YEAR);
        int selectedMonthIndex = selectedMonth.get(Calendar.MONTH);

        for (TransactionRecord record : records) {
            Calendar date = Calendar.getInstance();
            date.setTimeInMillis(record.dateMillis);
            if (date.get(Calendar.YEAR) != selectedYear || date.get(Calendar.MONTH) != selectedMonthIndex) {
                continue;
            }

            if (TransactionRecord.TYPE_INCOME.equals(record.type)
                    || TransactionRecord.TYPE_LOAN_REPAYMENT.equals(record.type)) {
                summary.income += record.amount;
            } else if (TransactionRecord.TYPE_EXPENSE.equals(record.type)) {
                summary.expense += record.amount;
                addTo(summary.expensesByCategory, emptyToOther(record.category), record.amount);
                addTo(summary.expensesByNecessity, emptyToOther(record.necessity), record.amount);
            } else if (TransactionRecord.TYPE_SAVINGS.equals(record.type)) {
                summary.savings += record.amount;
            }
        }

        summary.reservedTenPercent = Math.round(summary.income * 0.10d);
        int daysInMonth = selectedMonth.getActualMaximum(Calendar.DAY_OF_MONTH);
        summary.dailyBudget = Math.max(0L, (summary.income - summary.reservedTenPercent - SAVINGS_TARGET) / daysInMonth);

        int dayOfMonth = 1;
        if (today.get(Calendar.YEAR) == selectedYear && today.get(Calendar.MONTH) == selectedMonthIndex) {
            dayOfMonth = today.get(Calendar.DAY_OF_MONTH);
        } else if (today.after(selectedMonth)) {
            dayOfMonth = daysInMonth;
        }
        summary.expectedSpendingToDate = summary.dailyBudget * dayOfMonth;
        summary.overspending = summary.expense > summary.expectedSpendingToDate && summary.dailyBudget > 0;
        return summary;
    }

    public List<TransactionRecord> filterLatestSixMonths(List<TransactionRecord> records, Calendar now) {
        Calendar threshold = (Calendar) now.clone();
        threshold.set(Calendar.DAY_OF_MONTH, 1);
        threshold.set(Calendar.HOUR_OF_DAY, 0);
        threshold.set(Calendar.MINUTE, 0);
        threshold.set(Calendar.SECOND, 0);
        threshold.set(Calendar.MILLISECOND, 0);
        threshold.add(Calendar.MONTH, -5);

        List<TransactionRecord> result = new ArrayList<>();
        for (TransactionRecord record : records) {
            if (record.dateMillis >= threshold.getTimeInMillis()) {
                result.add(record);
            }
        }
        return result;
    }

    public Map<String, long[]> loanBalances(List<TransactionRecord> records) {
        Map<String, long[]> balances = new LinkedHashMap<>();
        for (TransactionRecord record : records) {
            if (record.borrower == null || record.borrower.trim().isEmpty()) {
                continue;
            }
            String borrower = record.borrower.trim();
            long[] totals = balances.get(borrower);
            if (totals == null) {
                totals = new long[]{0L, 0L};
                balances.put(borrower, totals);
            }
            if (TransactionRecord.TYPE_LOAN_GIVEN.equals(record.type)) {
                totals[0] += record.amount;
            } else if (TransactionRecord.TYPE_LOAN_REPAYMENT.equals(record.type)) {
                totals[1] += record.amount;
            }
        }
        return balances;
    }

    public boolean needsSavingsReminder(FinanceSummary summary, Calendar today) {
        return today.get(Calendar.DAY_OF_MONTH) >= 5 && summary.savings < SAVINGS_TARGET;
    }

    public boolean needsUrgentSavingsReminder(FinanceSummary summary, Calendar today) {
        return today.get(Calendar.DAY_OF_MONTH) >= 15 && summary.savings < SAVINGS_TARGET;
    }

    private void addTo(Map<String, Long> map, String key, long amount) {
        Long current = map.get(key);
        map.put(key, current == null ? amount : current + amount);
    }

    private String emptyToOther(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "Бусад";
        }
        return value.trim();
    }

    public static Calendar month(int year, int zeroBasedMonth) {
        Calendar calendar = Calendar.getInstance(Locale.ROOT);
        calendar.clear();
        calendar.set(Calendar.YEAR, year);
        calendar.set(Calendar.MONTH, zeroBasedMonth);
        calendar.set(Calendar.DAY_OF_MONTH, 1);
        return calendar;
    }
}

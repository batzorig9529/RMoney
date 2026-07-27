package com.example.rmoney;

import java.util.LinkedHashMap;
import java.util.Map;

public class FinanceSummary {
    public long income;
    public long expense;
    public long savings;
    public long reservedTenPercent;
    public long dailyBudget;
    public long expectedSpendingToDate;
    public boolean overspending;
    public final Map<String, Long> expensesByCategory = new LinkedHashMap<>();
    public final Map<String, Long> expensesByNecessity = new LinkedHashMap<>();
}

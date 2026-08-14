package com.example.rmoney;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.Locale;

public class MoneyFormatter {
    private static final DecimalFormat FORMAT;

    static {
        DecimalFormatSymbols symbols = DecimalFormatSymbols.getInstance(Locale.US);
        FORMAT = new DecimalFormat("#,###", symbols);
    }

    public static String mnt(long amount) {
        return FORMAT.format(amount) + " MNT";
    }

    public static String input(long amount) {
        return FORMAT.format(amount);
    }
}

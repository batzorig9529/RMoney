package com.example.rmoney;

import android.Manifest;
import android.app.DatePickerDialog;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.DatePicker;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import android.text.InputType;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

public class MainActivity extends AppCompatActivity {
    private final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
    private final FinanceCalculator calculator = new FinanceCalculator();
    private RMoneyStore store;
    private FrameLayout contentFrame;
    private Calendar selectedDate;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        store = new RMoneyStore(this);
        contentFrame = findViewById(R.id.contentFrame);
        selectedDate = Calendar.getInstance();

        requestNotificationPermission();
        ReminderScheduler.scheduleDaily(this);

        BottomNavigationView navigation = findViewById(R.id.bottomNavigation);
        navigation.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_dashboard) {
                showDashboard();
            } else if (id == R.id.nav_add) {
                showAdd();
            } else if (id == R.id.nav_transactions) {
                showTransactions();
            } else if (id == R.id.nav_loans) {
                showLoans();
            } else if (id == R.id.nav_reports) {
                showReports();
            }
            return true;
        });
        navigation.setSelectedItemId(R.id.nav_dashboard);
    }

    private void showDashboard() {
        List<TransactionRecord> records = store.loadRecords();
        Calendar now = Calendar.getInstance();
        FinanceSummary summary = calculator.summarizeMonth(records, now, now);

        LinearLayout root = page("RMoney", "Энэ сарын санхүүгийн тойм");
        LinearLayout stats = vertical();
        stats.addView(stat("Орлого", MoneyFormatter.mnt(summary.income)));
        stats.addView(stat("Зардал", MoneyFormatter.mnt(summary.expense)));
        stats.addView(stat("Хадгаламж", MoneyFormatter.mnt(summary.savings)));
        stats.addView(stat("10% нөөц", MoneyFormatter.mnt(summary.reservedTenPercent)));
        stats.addView(stat("Өдрийн зардлын боломж", MoneyFormatter.mnt(summary.dailyBudget)));
        root.addView(stats);

        if (summary.overspending) {
            root.addView(alert("Зардал өндөр байна", "Одоогийн зардал төлөвлөсөн хязгаараас давсан байна."));
        }
        if (calculator.needsUrgentSavingsReminder(summary, now)) {
            root.addView(alert("Хадгаламж яаралтай", "15-наас хойш зорилтот 500,000 MNT хүрээгүй байна."));
        } else if (calculator.needsSavingsReminder(summary, now)) {
            root.addView(alert("Хадгаламжийн сануулга", "5-наас хойш зорилтот 500,000 MNT хүрээгүй байна."));
        }
        setPage(root);
    }

    private void showAdd() {
        LinearLayout root = page("Гүйлгээ нэмэх", "Орлого, зардал, хадгаламж, зээлээ бүртгэнэ");

        Spinner type = spinner(new String[]{"Орлого", "Зардал", "Хадгаламж", "Зээл өгөх", "Зээл буцаан авах"});
        TextInputEditText amount = input(root, "Дүн");
        amount.setInputType(InputType.TYPE_CLASS_NUMBER);
        TextInputEditText category = input(root, "Ангилал");
        Spinner necessity = spinner(new String[]{"Зайлшгүй", "Зайлшгүй бус"});
        TextInputEditText borrower = input(root, "Хэнд");
        TextInputEditText note = input(root, "Тэмдэглэл");
        Button dateButton = new Button(this);
        dateButton.setText(dateFormat.format(selectedDate.getTime()));
        dateButton.setAllCaps(false);
        dateButton.setOnClickListener(v -> pickDate(dateButton));
        root.addView(label("Огноо"));
        root.addView(dateButton);
        root.addView(label("Төрөл"));
        root.addView(type);
        TextView necessityLabel = label("Зардлын шаардлага");
        root.addView(necessityLabel);
        root.addView(necessity);

        type.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                boolean isExpense = position == 1;
                boolean isLoan = position == 3 || position == 4;
                necessityLabel.setVisibility(isExpense ? View.VISIBLE : View.GONE);
                necessity.setVisibility(isExpense ? View.VISIBLE : View.GONE);
                setFieldVisibility(borrower, isLoan);
                category.setHint(isExpense ? "Худалдан авалтын төрөл" : "Ангилал");
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
        setFieldVisibility(borrower, false);
        necessityLabel.setVisibility(View.GONE);
        necessity.setVisibility(View.GONE);

        Button save = new Button(this);
        save.setText("Хадгалах");
        save.setAllCaps(false);
        save.setOnClickListener(v -> {
            long parsedAmount = parseAmount(amount.getText() == null ? "" : amount.getText().toString());
            if (parsedAmount <= 0) {
                Toast.makeText(this, "Дүнгээ зөв оруулна уу", Toast.LENGTH_SHORT).show();
                return;
            }
            int position = type.getSelectedItemPosition();
            TransactionRecord record = new TransactionRecord(UUID.randomUUID().toString(), typeValue(position), parsedAmount, selectedDate.getTimeInMillis());
            record.category = textOf(category);
            record.necessity = position == 1 ? necessity.getSelectedItem().toString() : "";
            record.borrower = textOf(borrower);
            record.note = textOf(note);
            if ((position == 3 || position == 4) && record.borrower.isEmpty()) {
                Toast.makeText(this, "Хэнд гэдэг талбарыг бөглөнө үү", Toast.LENGTH_SHORT).show();
                return;
            }
            store.addRecord(record);
            Toast.makeText(this, "Хадгаллаа", Toast.LENGTH_SHORT).show();
            showDashboard();
        });
        root.addView(save);
        setPage(root);
    }

    private void showTransactions() {
        List<TransactionRecord> records = store.loadRecords();
        Calendar now = Calendar.getInstance();
        LinearLayout root = page("Гүйлгээ", "Энэ сарын бүх бүртгэл");
        boolean hasItems = false;
        for (TransactionRecord record : records) {
            if (!isSameMonth(record.dateMillis, now)) {
                continue;
            }
            hasItems = true;
            root.addView(transactionRow(record));
        }
        if (!hasItems) {
            root.addView(empty("Энэ сард бүртгэл алга"));
        }
        setPage(root);
    }

    private void showLoans() {
        List<TransactionRecord> records = store.loadRecords();
        Map<String, long[]> balances = calculator.loanBalances(records);
        LinearLayout root = page("Зээлийн мэдээлэл", "Бусдад өгсөн зээл болон буцаан авалт");
        if (balances.isEmpty()) {
            root.addView(empty("Зээлийн бүртгэл алга"));
        }
        for (Map.Entry<String, long[]> entry : balances.entrySet()) {
            long given = entry.getValue()[0];
            long repaid = entry.getValue()[1];
            root.addView(card(entry.getKey(),
                    "Өгсөн: " + MoneyFormatter.mnt(given)
                            + "\nБуцаан авсан: " + MoneyFormatter.mnt(repaid)
                            + "\nҮлдэгдэл: " + MoneyFormatter.mnt(Math.max(0L, given - repaid))));
        }
        setPage(root);
    }

    private void showReports() {
        List<TransactionRecord> records = store.loadRecords();
        Calendar now = Calendar.getInstance();
        FinanceSummary summary = calculator.summarizeMonth(records, now, now);
        LinearLayout root = page("Тайлан", "Энэ сарын зардлын дэлгэрэнгүй");
        ChartView chart = new ChartView(this);
        chart.setValues(summary.expensesByCategory);
        root.addView(chart, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(220)));
        root.addView(card("Зайлшгүй / Зайлшгүй бус", lines(summary.expensesByNecessity)));
        root.addView(card("Ангиллаар", lines(summary.expensesByCategory)));
        setPage(root);
    }

    private LinearLayout page(String title, String subtitle) {
        LinearLayout root = vertical();
        root.setPadding(dp(18), dp(18), dp(18), dp(18));
        TextView titleView = new TextView(this);
        titleView.setText(title);
        titleView.setTextSize(28f);
        titleView.setGravity(Gravity.START);
        titleView.setTextColor(0xFF0F172A);
        root.addView(titleView);
        TextView subtitleView = new TextView(this);
        subtitleView.setText(subtitle);
        subtitleView.setTextSize(15f);
        subtitleView.setTextColor(0xFF64748B);
        root.addView(subtitleView);
        return root;
    }

    private void setPage(LinearLayout root) {
        ScrollView scrollView = new ScrollView(this);
        scrollView.addView(root);
        contentFrame.removeAllViews();
        contentFrame.addView(scrollView);
    }

    private LinearLayout vertical() {
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        return layout;
    }

    private View stat(String name, String value) {
        return card(name, value);
    }

    private View alert(String title, String body) {
        TextView view = new TextView(this);
        view.setText(title + "\n" + body);
        view.setTextSize(16f);
        view.setTextColor(0xFF7F1D1D);
        view.setBackgroundColor(0xFFFEE2E2);
        view.setPadding(dp(14), dp(12), dp(14), dp(12));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        params.setMargins(0, dp(12), 0, 0);
        view.setLayoutParams(params);
        return view;
    }

    private TextView card(String title, String body) {
        TextView view = new TextView(this);
        view.setText(title + "\n" + body);
        view.setTextSize(16f);
        view.setTextColor(0xFF1E293B);
        view.setBackgroundColor(0xFFF8FAFC);
        view.setPadding(dp(14), dp(12), dp(14), dp(12));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        params.setMargins(0, dp(12), 0, 0);
        view.setLayoutParams(params);
        return view;
    }

    private TextView empty(String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(16f);
        view.setPadding(0, dp(24), 0, 0);
        return view;
    }

    private TextView transactionRow(TransactionRecord record) {
        String detail = dateFormat.format(new Date(record.dateMillis))
                + "\n" + typeLabel(record.type) + " - " + MoneyFormatter.mnt(record.amount)
                + (record.category.isEmpty() ? "" : "\nАнгилал: " + record.category)
                + (record.necessity.isEmpty() ? "" : "\n" + record.necessity)
                + (record.borrower.isEmpty() ? "" : "\nХэнд: " + record.borrower)
                + (record.note.isEmpty() ? "" : "\n" + record.note);
        return card(typeLabel(record.type), detail);
    }

    private TextView label(String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(14f);
        view.setTextColor(0xFF475569);
        view.setPadding(0, dp(12), 0, dp(4));
        return view;
    }

    private TextInputEditText input(LinearLayout root, String hint) {
        TextInputLayout layout = new TextInputLayout(this);
        layout.setHint(hint);
        TextInputEditText editText = new TextInputEditText(layout.getContext());
        layout.addView(editText);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        params.setMargins(0, dp(10), 0, 0);
        layout.setLayoutParams(params);
        root.addView(layout);
        return editText;
    }

    private Spinner spinner(String[] values) {
        Spinner spinner = new Spinner(this);
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, values);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter);
        return spinner;
    }

    private void pickDate(Button button) {
        DatePickerDialog dialog = new DatePickerDialog(this, (DatePicker view, int year, int month, int dayOfMonth) -> {
            selectedDate.set(Calendar.YEAR, year);
            selectedDate.set(Calendar.MONTH, month);
            selectedDate.set(Calendar.DAY_OF_MONTH, dayOfMonth);
            button.setText(dateFormat.format(selectedDate.getTime()));
        }, selectedDate.get(Calendar.YEAR), selectedDate.get(Calendar.MONTH), selectedDate.get(Calendar.DAY_OF_MONTH));
        dialog.show();
    }

    private String lines(Map<String, Long> values) {
        if (values.isEmpty()) {
            return "Мэдээлэл алга";
        }
        List<String> lines = new ArrayList<>();
        for (Map.Entry<String, Long> entry : values.entrySet()) {
            lines.add(entry.getKey() + ": " + MoneyFormatter.mnt(entry.getValue()));
        }
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < lines.size(); i++) {
            if (i > 0) {
                builder.append('\n');
            }
            builder.append(lines.get(i));
        }
        return builder.toString();
    }

    private boolean isSameMonth(long millis, Calendar month) {
        Calendar date = Calendar.getInstance();
        date.setTimeInMillis(millis);
        return date.get(Calendar.YEAR) == month.get(Calendar.YEAR)
                && date.get(Calendar.MONTH) == month.get(Calendar.MONTH);
    }

    private String typeValue(int position) {
        if (position == 1) {
            return TransactionRecord.TYPE_EXPENSE;
        } else if (position == 2) {
            return TransactionRecord.TYPE_SAVINGS;
        } else if (position == 3) {
            return TransactionRecord.TYPE_LOAN_GIVEN;
        } else if (position == 4) {
            return TransactionRecord.TYPE_LOAN_REPAYMENT;
        }
        return TransactionRecord.TYPE_INCOME;
    }

    private String typeLabel(String type) {
        if (TransactionRecord.TYPE_EXPENSE.equals(type)) {
            return "Зардал";
        } else if (TransactionRecord.TYPE_SAVINGS.equals(type)) {
            return "Хадгаламж";
        } else if (TransactionRecord.TYPE_LOAN_GIVEN.equals(type)) {
            return "Зээл өгөх";
        } else if (TransactionRecord.TYPE_LOAN_REPAYMENT.equals(type)) {
            return "Зээл буцаан авах";
        }
        return "Орлого";
    }

    private long parseAmount(String value) {
        try {
            return Long.parseLong(value.replace(",", "").trim());
        } catch (NumberFormatException ignored) {
            return 0L;
        }
    }

    private String textOf(EditText editText) {
        return editText.getText() == null ? "" : editText.getText().toString().trim();
    }

    private void setFieldVisibility(EditText editText, boolean visible) {
        View parent = (View) editText.getParent();
        parent.setVisibility(visible ? View.VISIBLE : View.GONE);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
                && ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.POST_NOTIFICATIONS}, 41);
        }
    }
}

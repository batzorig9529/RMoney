package com.example.rmoney;

import android.content.Context;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

public class RMoneyStore {
    private static final String FILE_NAME = "rmoney_data.json";

    private final Context context;
    private final FinanceCalculator calculator = new FinanceCalculator();

    public RMoneyStore(Context context) {
        this.context = context.getApplicationContext();
    }

    public synchronized List<TransactionRecord> loadRecords() {
        File file = new File(context.getFilesDir(), FILE_NAME);
        if (!file.exists()) {
            return new ArrayList<>();
        }

        StringBuilder builder = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                new FileInputStream(file), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                builder.append(line);
            }
            JSONObject root = new JSONObject(builder.toString());
            JSONArray items = root.optJSONArray("transactions");
            List<TransactionRecord> records = new ArrayList<>();
            if (items != null) {
                for (int i = 0; i < items.length(); i++) {
                    records.add(TransactionRecord.fromJson(items.getJSONObject(i)));
                }
            }
            List<TransactionRecord> pruned = calculator.filterLatestSixMonths(records, Calendar.getInstance());
            if (pruned.size() != records.size()) {
                saveRecords(pruned);
            }
            return pruned;
        } catch (IOException | JSONException ignored) {
            return new ArrayList<>();
        }
    }

    public synchronized void addRecord(TransactionRecord record) {
        List<TransactionRecord> records = loadRecords();
        records.add(record);
        saveRecords(calculator.filterLatestSixMonths(records, Calendar.getInstance()));
    }

    public synchronized void saveRecords(List<TransactionRecord> records) {
        JSONObject root = new JSONObject();
        JSONArray items = new JSONArray();
        try {
            for (TransactionRecord record : records) {
                items.put(record.toJson());
            }
            root.put("transactions", items);
        } catch (JSONException ignored) {
            return;
        }

        File file = new File(context.getFilesDir(), FILE_NAME);
        try (FileOutputStream stream = new FileOutputStream(file, false)) {
            stream.write(root.toString().getBytes(StandardCharsets.UTF_8));
        } catch (IOException ignored) {
            // The UI keeps running; the next save attempt can recover.
        }
    }
}

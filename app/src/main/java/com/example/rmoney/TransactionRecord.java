package com.example.rmoney;

import org.json.JSONException;
import org.json.JSONObject;

public class TransactionRecord {
    public static final String TYPE_INCOME = "income";
    public static final String TYPE_EXPENSE = "expense";
    public static final String TYPE_SAVINGS = "savings";
    public static final String TYPE_LOAN_GIVEN = "loan_given";
    public static final String TYPE_LOAN_REPAYMENT = "loan_repayment";

    public String id;
    public String type;
    public long amount;
    public long dateMillis;
    public String note;
    public String category;
    public String necessity;
    public String borrower;

    public TransactionRecord(String id, String type, long amount, long dateMillis) {
        this.id = id;
        this.type = type;
        this.amount = amount;
        this.dateMillis = dateMillis;
        this.note = "";
        this.category = "";
        this.necessity = "";
        this.borrower = "";
    }

    public JSONObject toJson() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("id", id);
        json.put("type", type);
        json.put("amount", amount);
        json.put("dateMillis", dateMillis);
        json.put("note", note);
        json.put("category", category);
        json.put("necessity", necessity);
        json.put("borrower", borrower);
        return json;
    }

    public static TransactionRecord fromJson(JSONObject json) {
        TransactionRecord record = new TransactionRecord(
                json.optString("id"),
                json.optString("type"),
                json.optLong("amount"),
                json.optLong("dateMillis")
        );
        record.note = json.optString("note");
        record.category = json.optString("category");
        record.necessity = json.optString("necessity");
        record.borrower = json.optString("borrower");
        return record;
    }
}

package com.example.rmoney;

import android.Manifest;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import java.util.Calendar;
import java.util.List;

public class ReminderReceiver extends BroadcastReceiver {
    private static final String CHANNEL_ID = "rmoney_reminders";

    @Override
    public void onReceive(Context context, Intent intent) {
        createChannel(context);
        RMoneyStore store = new RMoneyStore(context);
        List<TransactionRecord> records = store.loadRecords();
        Calendar now = Calendar.getInstance();
        FinanceSummary summary = new FinanceCalculator().summarizeMonth(records, now, now);

        if (summary.overspending) {
            notify(context, 201, "Зардал өндөр байна",
                    "Өнөөдрийн хязгаар: " + MoneyFormatter.mnt(summary.expectedSpendingToDate)
                            + ", зарцуулсан: " + MoneyFormatter.mnt(summary.expense));
        }

        FinanceCalculator calculator = new FinanceCalculator();
        if (calculator.needsUrgentSavingsReminder(summary, now)) {
            notify(context, 203, "Хадгаламжаа яаралтай нэмээрэй",
                    "Энэ сарын зорилт " + MoneyFormatter.mnt(FinanceCalculator.SAVINGS_TARGET)
                            + ", одоо: " + MoneyFormatter.mnt(summary.savings));
        } else if (calculator.needsSavingsReminder(summary, now)) {
            notify(context, 202, "Хадгаламжийн сануулга",
                    "Энэ сарын хадгаламж " + MoneyFormatter.mnt(summary.savings)
                            + ". Зорилт: " + MoneyFormatter.mnt(FinanceCalculator.SAVINGS_TARGET));
        }
    }

    private void notify(Context context, int id, String title, String text) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
                && ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
            return;
        }

        Intent openIntent = new Intent(context, MainActivity.class);
        openIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(
                context,
                id,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_dashboard)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT);
        NotificationManagerCompat.from(context).notify(id, builder.build());
    }

    private void createChannel(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) {
            return;
        }
        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "RMoney сануулга",
                NotificationManager.IMPORTANCE_DEFAULT
        );
        channel.setDescription("Зардал болон хадгаламжийн өдөр тутмын сануулга");
        manager.createNotificationChannel(channel);
    }
}

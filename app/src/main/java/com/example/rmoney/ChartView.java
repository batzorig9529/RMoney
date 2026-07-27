package com.example.rmoney;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.View;

import java.util.LinkedHashMap;
import java.util.Map;

public class ChartView extends View {
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Map<String, Long> values = new LinkedHashMap<>();
    private final int[] colors = {
            Color.rgb(37, 99, 235),
            Color.rgb(22, 163, 74),
            Color.rgb(234, 88, 12),
            Color.rgb(147, 51, 234),
            Color.rgb(220, 38, 38),
            Color.rgb(8, 145, 178),
            Color.rgb(79, 70, 229)
    };

    public ChartView(Context context) {
        super(context);
    }

    public ChartView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public void setValues(Map<String, Long> newValues) {
        values.clear();
        values.putAll(newValues);
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        int width = getWidth();
        int height = getHeight();
        if (width <= 0 || height <= 0) {
            return;
        }

        if (values.isEmpty()) {
            paint.setColor(Color.rgb(100, 116, 139));
            paint.setTextSize(36f);
            paint.setTextAlign(Paint.Align.CENTER);
            canvas.drawText("Энэ сард зардал алга", width / 2f, height / 2f, paint);
            return;
        }

        long max = 1L;
        for (Long value : values.values()) {
            max = Math.max(max, value);
        }

        int count = values.size();
        float gap = 18f;
        float barWidth = Math.max(24f, (width - gap * (count + 1)) / count);
        float base = height - 54f;
        int index = 0;
        paint.setTextAlign(Paint.Align.CENTER);
        for (Map.Entry<String, Long> entry : values.entrySet()) {
            float left = gap + index * (barWidth + gap);
            float barHeight = Math.max(8f, (base - 24f) * entry.getValue() / max);
            paint.setColor(colors[index % colors.length]);
            canvas.drawRoundRect(left, base - barHeight, left + barWidth, base, 10f, 10f, paint);
            paint.setColor(Color.rgb(51, 65, 85));
            paint.setTextSize(22f);
            String label = entry.getKey().length() > 8 ? entry.getKey().substring(0, 8) : entry.getKey();
            canvas.drawText(label, left + barWidth / 2f, height - 16f, paint);
            index++;
        }
    }
}

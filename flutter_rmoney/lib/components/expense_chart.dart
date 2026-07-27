import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ExpenseChart extends StatelessWidget {
  const ExpenseChart({super.key, required this.values});

  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainer,
      child: SizedBox(
        height: 230,
        child: values.isEmpty
            ? Center(
                child: Text('Энэ сард зардал алга',
                    style: TextStyle(color: scheme.onSurfaceVariant)))
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) {
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: CustomPaint(
                        painter: ExpenseChartPainter(
                            values, scheme.onSurfaceVariant, progress)),
                  );
                },
              ),
      ),
    );
  }
}

class ExpenseChartPainter extends CustomPainter {
  ExpenseChartPainter(this.values, this.labelColor, this.progress);

  final Map<String, int> values;
  final Color labelColor;
  final double progress;
  final colors = const [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final maxValue = values.values.fold<int>(1, max);
    final gap = 14.0;
    final barWidth =
        max(22.0, (size.width - gap * (values.length + 1)) / values.length);
    final base = size.height - 34;
    var index = 0;
    for (final entry in values.entries) {
      final left = gap + index * (barWidth + gap);
      final height = max(8.0, (base - 8) * entry.value / maxValue) * progress;
      paint.color = colors[index % colors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, base - height, barWidth, height),
            const Radius.circular(8)),
        paint,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key.length > 8 ? entry.key.substring(0, 8) : entry.key,
          style: TextStyle(color: labelColor, fontSize: 11),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: barWidth + 8);
      textPainter.paint(canvas,
          Offset(left + (barWidth - textPainter.width) / 2, size.height - 22));
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant ExpenseChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.progress != progress;
}

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/money_formatter.dart';

class PeriodComparisonChart extends StatelessWidget {
  const PeriodComparisonChart({super.key, required this.items});

  final List<PeriodComparison> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сүүлийн 6 үеийн зардал',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Санхүүгийн үе бүр сарын 5-наас дараа сарын 5 хүртэл',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 780),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) {
                  return CustomPaint(
                    painter: PeriodComparisonPainter(
                      items: items,
                      barColor: scheme.secondary,
                      labelColor: scheme.onSurfaceVariant,
                      valueColor: scheme.onSurface,
                      progress: progress,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeriodComparisonPainter extends CustomPainter {
  const PeriodComparisonPainter({
    required this.items,
    required this.barColor,
    required this.labelColor,
    required this.valueColor,
    required this.progress,
  });

  final List<PeriodComparison> items;
  final Color barColor;
  final Color labelColor;
  final Color valueColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    final paint = Paint()..isAntiAlias = true;
    final maxExpense =
        items.map((item) => item.expense).fold<int>(1, (a, b) => max(a, b));
    const gap = 12.0;
    final base = size.height - 42;
    const top = 30.0;
    final barWidth =
        max(20.0, (size.width - gap * (items.length + 1)) / items.length);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final left = gap + i * (barWidth + gap);
      final fullHeight = max(6.0, (base - top) * item.expense / maxExpense);
      final height = fullHeight * progress;
      paint.color = barColor.withValues(alpha: 0.86);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, base - height, barWidth, height),
          const Radius.circular(8),
        ),
        paint,
      );
      _drawText(
        canvas,
        text: item.shortLabel,
        color: labelColor,
        size: 10,
        maxWidth: barWidth + 10,
        offset: Offset(left + barWidth / 2, size.height - 24),
      );
      _drawText(
        canvas,
        text: _shortMoney(item.expense),
        color: valueColor,
        size: 10,
        maxWidth: barWidth + 18,
        offset: Offset(left + barWidth / 2, max(0, base - height - 18)),
      );
    }
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Color color,
    required double size,
    required double maxWidth,
    required Offset offset,
  }) {
    final painter = TextPainter(
      text:
          TextSpan(text: text, style: TextStyle(color: color, fontSize: size)),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(offset.dx - painter.width / 2, offset.dy));
  }

  String _shortMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).round()}K';
    }
    return formatMnt(amount).replaceAll(' MNT', '');
  }

  @override
  bool shouldRepaint(covariant PeriodComparisonPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.barColor != barColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.valueColor != valueColor ||
        oldDelegate.progress != progress;
  }
}

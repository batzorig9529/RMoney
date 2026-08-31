import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/money_formatter.dart';

class ExpenseChart extends StatefulWidget {
  const ExpenseChart({super.key, required this.values});

  final Map<String, int> values;

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total =
        widget.values.values.fold<int>(0, (sum, value) => sum + value);
    final selectedEntry = selectedIndex == null ||
            selectedIndex! < 0 ||
            selectedIndex! >= widget.values.length
        ? null
        : widget.values.entries.elementAt(selectedIndex!);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 250,
          child: widget.values.isEmpty
              ? Center(
                  child: Text('Энэ сард зардал алга',
                      style: TextStyle(color: scheme.onSurfaceVariant)))
              : Column(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, progress, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final chartWidth = max(
                                constraints.maxWidth,
                                ExpenseChartPainter.widthForItemCount(
                                    widget.values.length),
                              );
                              return Scrollbar(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: chartWidth,
                                    height: constraints.maxHeight,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (details) {
                                        final tappedIndex = ExpenseChartPainter
                                            .indexForPosition(
                                          position: details.localPosition,
                                          itemCount: widget.values.length,
                                        );
                                        setState(
                                            () => selectedIndex = tappedIndex);
                                      },
                                      child: CustomPaint(
                                        painter: ExpenseChartPainter(
                                          widget.values,
                                          scheme.onSurfaceVariant,
                                          progress,
                                          selectedIndex,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selectedEntry == null
                          ? Text(
                              'График дээр дарж дэлгэрэнгүй харна уу',
                              key: const ValueKey('empty-selection'),
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            )
                          : _ExpenseChartSelection(
                              key: ValueKey(selectedEntry.key),
                              name: selectedEntry.key,
                              amount: selectedEntry.value,
                              total: total,
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class ExpenseChartPainter extends CustomPainter {
  ExpenseChartPainter(
      this.values, this.labelColor, this.progress, this.selectedIndex);

  final Map<String, int> values;
  final Color labelColor;
  final double progress;
  final int? selectedIndex;
  static const gap = 14.0;
  static const minBarWidth = 42.0;
  final colors = const [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
  ];

  static int? indexForPosition({
    required Offset position,
    required int itemCount,
  }) {
    if (itemCount == 0) return null;
    const barWidth = minBarWidth;
    for (var index = 0; index < itemCount; index++) {
      final left = gap + index * (barWidth + gap);
      final right = left + barWidth;
      final touchRect = Rect.fromLTRB(
        left - gap / 2,
        0,
        right + gap / 2,
        double.infinity,
      );
      if (touchRect.contains(position)) {
        return index;
      }
    }
    return null;
  }

  static double widthForItemCount(int itemCount) {
    if (itemCount <= 0) return 0;
    return gap * (itemCount + 1) + minBarWidth * itemCount;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final maxValue = values.values.fold<int>(1, max);
    const barWidth = minBarWidth;
    final base = size.height - 34;
    var index = 0;
    for (final entry in values.entries) {
      final selected = selectedIndex == index;
      final left = gap + index * (barWidth + gap);
      final height = max(8.0, (base - 8) * entry.value / maxValue) * progress;
      final rect = Rect.fromLTWH(left, base - height, barWidth, height);
      paint.color =
          colors[index % colors.length].withValues(alpha: selected ? 1 : .76);
      if (selected) {
        final highlightPaint = Paint()
          ..isAntiAlias = true
          ..color = colors[index % colors.length].withValues(alpha: .16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(10)),
          highlightPaint,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
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
      oldDelegate.progress != progress ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _ExpenseChartSelection extends StatelessWidget {
  const _ExpenseChartSelection({
    super.key,
    required this.name,
    required this.amount,
    required this.total,
  });

  final String name;
  final int amount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = total == 0 ? 0 : amount * 100 / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$name · ${percent.toStringAsFixed(1)}% · ${formatMnt(amount)}',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

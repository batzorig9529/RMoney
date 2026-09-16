import 'package:flutter/material.dart';

import '../utils/money_formatter.dart';

class StatCard extends StatelessWidget {
  const StatCard(
      {super.key,
      required this.title,
      required this.amount,
      required this.icon});

  final String title;
  final int amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outgoing = icon == Icons.trending_down || icon == Icons.north_east;
    final color = outgoing ? const Color(0xFFE78272) : scheme.secondary;
    return Card(
      color: scheme.surfaceContainer,
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 19),
            ),
            const Spacer(),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatMnt(amount),
                    maxLines: 1,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

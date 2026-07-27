import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.notifications_active_outlined,
            color: scheme.onErrorContainer),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: scheme.onErrorContainer)),
        subtitle: Text(body, style: TextStyle(color: scheme.onErrorContainer)),
      ),
    );
  }
}

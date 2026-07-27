class FinancePeriod {
  const FinancePeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return !normalized.isBefore(start) && normalized.isBefore(end);
  }

  int dayNumber(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isBefore(start)) return 1;
    if (!normalized.isBefore(end)) return end.difference(start).inDays;
    return normalized.difference(start).inDays + 1;
  }
}

import 'dart:math';

class LoanBalance {
  const LoanBalance({required this.given, required this.repaid});

  final int given;
  final int repaid;

  int get remaining => max(0, given - repaid);
}

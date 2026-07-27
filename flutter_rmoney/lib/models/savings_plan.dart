class SavingsPlan {
  const SavingsPlan({
    this.firstDay = 5,
    this.firstAmount = 500000,
    this.secondDay = 15,
    this.secondAmount = 500000,
  });

  final int firstDay;
  final int firstAmount;
  final int secondDay;
  final int secondAmount;

  int get totalTarget => firstAmount + secondAmount;

  Map<String, dynamic> toJson() => {
        'firstDay': firstDay,
        'firstAmount': firstAmount,
        'secondDay': secondDay,
        'secondAmount': secondAmount,
      };

  factory SavingsPlan.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SavingsPlan();
    return SavingsPlan(
      firstDay: (json['firstDay'] as num?)?.round() ?? 5,
      firstAmount: (json['firstAmount'] as num?)?.round() ?? 500000,
      secondDay: (json['secondDay'] as num?)?.round() ?? 15,
      secondAmount: (json['secondAmount'] as num?)?.round() ?? 500000,
    );
  }
}

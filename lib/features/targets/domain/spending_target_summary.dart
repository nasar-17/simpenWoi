import 'dart:math';

class SpendingTargetSummary {
  const SpendingTargetSummary({
    required this.limitAmount,
    required this.spent,
    required this.daysRemaining,
    required this.dailyAllowance,
  });

  final int limitAmount;
  final int spent;
  final int daysRemaining;
  final int dailyAllowance;

  int get remaining => max(0, limitAmount - spent);

  bool get isOver => spent > limitAmount;

  double get progress {
    if (limitAmount <= 0) {
      return 0;
    }
    return (spent / limitAmount).clamp(0, 1).toDouble();
  }
}

SpendingTargetSummary summarizeSpendingTarget({
  required int limitAmount,
  required int spent,
  required DateTime month,
  required DateTime now,
}) {
  final DateTime start = DateTime(month.year, month.month, 1);
  final DateTime end = DateTime(month.year, month.month + 1, 1);
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime effectiveToday = today.isBefore(start) ? start : today;
  final int daysRemaining = effectiveToday.isBefore(end)
      ? end.difference(effectiveToday).inDays
      : 0;
  final int remaining = max(0, limitAmount - spent);
  return SpendingTargetSummary(
    limitAmount: limitAmount,
    spent: spent,
    daysRemaining: daysRemaining,
    dailyAllowance: daysRemaining > 0 ? remaining ~/ daysRemaining : 0,
  );
}

String spendingMonthKey(DateTime month) {
  final String year = month.year.toString().padLeft(4, '0');
  final String value = month.month.toString().padLeft(2, '0');
  return '$year-$value';
}

DateTime shiftSpendingMonth(DateTime month, int direction) {
  return DateTime(month.year, month.month + direction, 1);
}

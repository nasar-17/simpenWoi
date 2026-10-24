import '../../../core/database/app_database.dart';
import '../../../core/utils/currency.dart';

/// Progres dan saran setoran untuk sebuah target tabungan.
class SavingsProgress {
  const SavingsProgress({
    required this.progress,
    required this.remaining,
    this.suggestion,
  });

  final double progress;
  final int remaining;
  final String? suggestion;
}

SavingsProgress calculateSavingsProgress(SavingsGoal goal, {DateTime? now}) {
  final double progress = goal.targetAmount <= 0
      ? 0
      : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0).toDouble();
  final int remaining = goal.targetAmount > goal.savedAmount
      ? goal.targetAmount - goal.savedAmount
      : 0;

  String? suggestion;
  if (goal.savedAmount >= goal.targetAmount) {
    suggestion = 'Target tercapai';
  } else if (goal.deadline != null) {
    final DateTime deadline = DateTime(
      goal.deadline!.year,
      goal.deadline!.month,
      goal.deadline!.day,
    );
    final DateTime today = now ?? DateTime.now();
    final int daysLeft = deadline.difference(today).inDays;
    if (daysLeft <= 0) {
      suggestion = 'Tenggat sudah lewat';
    } else {
      final int perDay = (remaining / daysLeft).ceil();
      suggestion = 'Sisihkan ${formatRupiah(perDay)} per hari';
    }
  }

  return SavingsProgress(
    progress: progress,
    remaining: remaining,
    suggestion: suggestion,
  );
}

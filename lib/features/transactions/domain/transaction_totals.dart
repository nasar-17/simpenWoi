import '../../../core/constants/transaction_values.dart';
import '../data/transaction_detail.dart';

/// Total pemasukan dan pengeluaran dari sekumpulan transaksi.
class TransactionTotals {
  const TransactionTotals({required this.expense, required this.income});

  final int expense;
  final int income;
}

TransactionTotals summarizeTransactions(
  Iterable<TransactionDetail> transactions,
) {
  int expense = 0;
  int income = 0;
  for (final TransactionDetail detail in transactions) {
    if (detail.transaction.type == TransactionType.expense) {
      expense += detail.transaction.amount;
    } else if (detail.transaction.type == TransactionType.income) {
      income += detail.transaction.amount;
    }
  }
  return TransactionTotals(expense: expense, income: income);
}

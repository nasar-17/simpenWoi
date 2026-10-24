import 'package:drift/drift.dart';

import '../../../core/constants/transaction_values.dart';
import '../../../core/constants/ui_text.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/domain/transaction_totals.dart';
import '../domain/recap_period.dart';

/// Total pengeluaran untuk satu kategori pada periode rekap.
class RecapCategoryTotal {
  const RecapCategoryTotal({required this.name, required this.amount});

  final String name;
  final int amount;
}

/// Query agregat rekap agar tidak memuat seluruh transaksi ke Dart.
class RecapRepository {
  RecapRepository(this._database);

  final AppDatabase _database;

  Stream<TransactionTotals> watchTotals(RecapRange range) {
    return _database
        .customSelect(
          'SELECT '
          'COALESCE(SUM(CASE WHEN type = ? THEN 0 ELSE amount END), 0) AS income, '
          'COALESCE(SUM(CASE WHEN type = ? THEN amount ELSE 0 END), 0) AS expense '
          'FROM transactions '
          'WHERE created_at >= ? AND created_at < ?',
          variables: <Variable<Object>>[
            Variable.withString(TransactionType.expense),
            Variable.withString(TransactionType.expense),
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
          ],
        )
        .watchSingle()
        .map(
          (QueryRow row) => TransactionTotals(
            income: row.read<int>('income'),
            expense: row.read<int>('expense'),
          ),
        );
  }

  Stream<List<RecapCategoryTotal>> watchCategoryTotals(RecapRange range) {
    return _database
        .customSelect(
          'SELECT COALESCE(c.name, ?) AS category_name, SUM(t.amount) AS total '
          'FROM transactions t '
          'LEFT JOIN categories c ON c.id = t.category_id '
          'WHERE t.type = ? AND t.created_at >= ? AND t.created_at < ? '
          'GROUP BY category_name '
          'ORDER BY total DESC, MAX(t.created_at) DESC, MAX(t.id) DESC',
          variables: <Variable<Object>>[
            Variable.withString(UiText.uncategorized),
            Variable.withString(TransactionType.expense),
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
          ],
        )
        .watch()
        .map(
          (List<QueryRow> rows) => rows
              .map(
                (QueryRow row) => RecapCategoryTotal(
                  name: row.read<String>('category_name'),
                  amount: row.read<int>('total'),
                ),
              )
              .toList(growable: false),
        );
  }
}

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'transaction_detail.dart';

/// Query gabungan transaksi, dompet, dan kategori.
class TransactionQueries {
  const TransactionQueries(this._database);

  final AppDatabase _database;

  Stream<List<TransactionDetail>> watchWhere(Expression<bool> predicate) {
    final query = _database.select(_database.transactions).join(
      <Join<HasResultSet, dynamic>>[
        innerJoin(
          _database.wallets,
          _database.wallets.id.equalsExp(_database.transactions.walletId),
        ),
        leftOuterJoin(
          _database.categories,
          _database.categories.id.equalsExp(_database.transactions.categoryId),
        ),
      ],
    )..where(predicate);

    return query.watch().map((List<TypedResult> rows) {
      final List<TransactionDetail> details = rows
          .map(mapRow)
          .toList(growable: false);
      details.sort((TransactionDetail a, TransactionDetail b) {
        final int byDate = b.transaction.createdAt.compareTo(
          a.transaction.createdAt,
        );
        return byDate != 0
            ? byDate
            : b.transaction.id.compareTo(a.transaction.id);
      });
      return details;
    });
  }

  TransactionDetail mapRow(TypedResult row) {
    return TransactionDetail(
      transaction: row.readTable(_database.transactions),
      wallet: row.readTable(_database.wallets),
      category: row.readTableOrNull(_database.categories),
    );
  }
}

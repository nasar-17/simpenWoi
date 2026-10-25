import 'package:drift/drift.dart';

import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import 'transaction_detail.dart';
import 'transaction_queries.dart';
import 'transaction_writer.dart';

/// Akses baca transaksi, kategori, dan operasi tulis turunan [TransactionWriter].
class TransactionRepository extends TransactionWriter {
  TransactionRepository(AppDatabase database)
    : _queries = TransactionQueries(database),
      super(database);

  final TransactionQueries _queries;

  Stream<List<TransactionDetail>> watchBetween(DateTime start, DateTime end) {
    return _queries.watchWhere(
      database.transactions.createdAt.isBiggerOrEqualValue(start) &
          database.transactions.createdAt.isSmallerThanValue(end),
    );
  }

  Stream<List<TransactionDetail>> watchUncategorized() {
    return _queries.watchWhere(
      database.transactions.isCategorized.equals(false),
    );
  }

  Future<List<Category>> getCategories() async {
    final List<Category> categories = await database
        .select(database.categories)
        .get();
    categories.sort((Category a, Category b) => a.id.compareTo(b.id));
    return categories;
  }

  Future<List<Category>> getExpenseCategories() async {
    final List<Category> categories = await getCategories();
    return categories
        .where((Category category) => category.type == TransactionType.expense)
        .toList(growable: false);
  }

  Stream<List<Category>> watchCategories() {
    return database
        .select(database.categories)
        .watch()
        .map(
          (List<Category> categories) =>
              categories
                ..sort((Category a, Category b) => a.id.compareTo(b.id)),
        );
  }

  Future<List<int>> topCategoryIds(String type, {int limit = 2}) async {
    final List<QueryRow> rows = await database
        .customSelect(
          'SELECT t.category_id, COUNT(*) AS usage_count '
          'FROM transactions t '
          'JOIN categories c ON c.id = t.category_id '
          'WHERE c.type = ? '
          'GROUP BY t.category_id '
          'ORDER BY usage_count DESC, t.category_id ASC '
          'LIMIT ?',
          variables: <Variable<Object>>[
            Variable.withString(type),
            Variable.withInt(limit),
          ],
        )
        .get();
    return rows
        .map((QueryRow row) => row.read<int>('category_id'))
        .toList(growable: false);
  }

  Future<TransactionRecord?> getByNativeCaptureId(int nativeCaptureId) async {
    final List<TransactionRecord> records =
        await (database.select(database.transactions)
              ..where((table) => table.nativeCaptureId.equals(nativeCaptureId))
              ..limit(1))
            .get();
    return records.isEmpty ? null : records.first;
  }
}

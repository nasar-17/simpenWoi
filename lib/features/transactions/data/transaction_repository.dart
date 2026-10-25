import 'package:drift/drift.dart';

import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../wallets/domain/wallet_balance.dart';
import 'transaction_detail.dart';
import 'transaction_queries.dart';

/// Akses data transaksi, kategori, dan penyesuaian saldo dompet.
class TransactionRepository {
  TransactionRepository(this._database)
    : _queries = TransactionQueries(_database);

  final AppDatabase _database;
  final TransactionQueries _queries;

  Stream<List<TransactionDetail>> watchBetween(DateTime start, DateTime end) {
    return _queries.watchWhere(
      _database.transactions.createdAt.isBiggerOrEqualValue(start) &
          _database.transactions.createdAt.isSmallerThanValue(end),
    );
  }

  Stream<List<TransactionDetail>> watchUncategorized() {
    return _queries.watchWhere(
      _database.transactions.isCategorized.equals(false),
    );
  }

  Future<List<Category>> getCategories() async {
    final List<Category> categories = await _database
        .select(_database.categories)
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
    return _database
        .select(_database.categories)
        .watch()
        .map(
          (List<Category> categories) =>
              categories
                ..sort((Category a, Category b) => a.id.compareTo(b.id)),
        );
  }

  Future<List<int>> topCategoryIds(String type, {int limit = 2}) async {
    final List<QueryRow> rows = await _database
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

  Future<int> addTransaction({
    required int amount,
    required String type,
    required int walletId,
    int? categoryId,
    String? note,
    String? merchant,
    String source = TransactionSource.manual,
    DateTime? createdAt,
    int? nativeCaptureId,
  }) {
    return _database.transaction(() async {
      final int id = await _database
          .into(_database.transactions)
          .insert(
            TransactionsCompanion.insert(
              amount: amount,
              type: type,
              walletId: walletId,
              categoryId: Value<int?>(categoryId),
              note: Value<String?>(note),
              merchant: Value<String?>(merchant),
              source: Value<String>(source),
              createdAt: Value<DateTime>(createdAt ?? DateTime.now()),
              isCategorized: Value<bool>(categoryId != null),
              nativeCaptureId: Value<int?>(nativeCaptureId),
            ),
          );
      await adjustWalletBalance(
        _database,
        walletId,
        balanceDelta(type: type, amount: amount),
      );
      return id;
    });
  }

  Future<TransactionRecord?> getByNativeCaptureId(int nativeCaptureId) async {
    final List<TransactionRecord> records =
        await (_database.select(_database.transactions)
              ..where((table) => table.nativeCaptureId.equals(nativeCaptureId))
              ..limit(1))
            .get();
    return records.isEmpty ? null : records.first;
  }

  Future<void> updateTransaction({
    required int id,
    required int amount,
    required String type,
    required int walletId,
    int? categoryId,
    String? note,
    String? merchant,
  }) {
    return _database.transaction(() async {
      final TransactionRecord? original = await (_database.select(
        _database.transactions,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (original == null) {
        return;
      }

      final int oldDelta = balanceDelta(
        type: original.type,
        amount: original.amount,
      );
      final int newDelta = balanceDelta(type: type, amount: amount);

      if (original.walletId == walletId) {
        await adjustWalletBalance(_database, walletId, newDelta - oldDelta);
      } else {
        await adjustWalletBalance(_database, original.walletId, -oldDelta);
        await adjustWalletBalance(_database, walletId, newDelta);
      }

      await (_database.update(
        _database.transactions,
      )..where((table) => table.id.equals(id))).write(
        TransactionsCompanion(
          amount: Value<int>(amount),
          type: Value<String>(type),
          walletId: Value<int>(walletId),
          categoryId: Value<int?>(categoryId),
          note: Value<String?>(note),
          merchant: Value<String?>(merchant),
          isCategorized: Value<bool>(categoryId != null),
        ),
      );
    });
  }

  Future<TransactionRecord?> deleteTransaction(int id) {
    return _database.transaction(() async {
      final TransactionRecord? record = await (_database.select(
        _database.transactions,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (record == null) {
        return null;
      }

      await (_database.delete(
        _database.transactions,
      )..where((table) => table.id.equals(id))).go();
      await adjustWalletBalance(
        _database,
        record.walletId,
        -balanceDelta(type: record.type, amount: record.amount),
      );
      return record;
    });
  }
}

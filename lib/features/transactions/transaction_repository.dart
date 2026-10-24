import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/transaction_values.dart';

class TransactionDetail {
  const TransactionDetail({
    required this.transaction,
    required this.wallet,
    this.category,
  });

  final TransactionRecord transaction;
  final Wallet wallet;
  final Category? category;
}

class TransactionRepository {
  TransactionRepository(this._database);

  final AppDatabase _database;

  Stream<List<TransactionDetail>> watchBetween(
    DateTime start,
    DateTime end,
  ) {
    final query =
        _database.select(_database.transactions).join([
      innerJoin(
        _database.wallets,
        _database.wallets.id.equalsExp(_database.transactions.walletId),
      ),
      leftOuterJoin(
        _database.categories,
        _database.categories.id.equalsExp(_database.transactions.categoryId),
      ),
    ])
          ..where(
            _database.transactions.createdAt.isBiggerOrEqualValue(start) &
                _database.transactions.createdAt.isSmallerThanValue(end),
          );

    return query.watch().map((List<TypedResult> rows) {
      final List<TransactionDetail> details =
          rows.map(_mapRow).toList(growable: false);
      details.sort((TransactionDetail a, TransactionDetail b) {
        final int byDate =
            b.transaction.createdAt.compareTo(a.transaction.createdAt);
        return byDate != 0 ? byDate : b.transaction.id.compareTo(a.transaction.id);
      });
      return details;
    });
  }

  Stream<List<Category>> watchCategories() {
    return _database.select(_database.categories).watch().map(
          (List<Category> categories) => categories
            ..sort((Category a, Category b) => a.id.compareTo(b.id)),
        );
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
  }) {
    return _database.transaction(() async {
      final int id = await _database.into(_database.transactions).insert(
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
            ),
          );
      await _adjustWalletBalance(
        walletId,
        _balanceDelta(type: type, amount: amount),
      );
      return id;
    });
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
      )..where((table) => table.id.equals(id)))
          .getSingleOrNull();
      if (original == null) {
        return;
      }

      final int oldDelta =
          _balanceDelta(type: original.type, amount: original.amount);
      final int newDelta = _balanceDelta(type: type, amount: amount);

      if (original.walletId == walletId) {
        await _adjustWalletBalance(walletId, newDelta - oldDelta);
      } else {
        await _adjustWalletBalance(original.walletId, -oldDelta);
        await _adjustWalletBalance(walletId, newDelta);
      }

      await (_database.update(_database.transactions)
            ..where((table) => table.id.equals(id)))
          .write(
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
      )..where((table) => table.id.equals(id)))
          .getSingleOrNull();
      if (record == null) {
        return null;
      }

      await (_database.delete(_database.transactions)
            ..where((table) => table.id.equals(id)))
          .go();
      await _adjustWalletBalance(
        record.walletId,
        -_balanceDelta(type: record.type, amount: record.amount),
      );
      return record;
    });
  }

  int _balanceDelta({required String type, required int amount}) {
    return type == TransactionType.income ? amount : -amount;
  }

  Future<void> _adjustWalletBalance(int walletId, int delta) async {
    if (delta == 0) {
      return;
    }
    final Wallet? wallet = await (_database.select(_database.wallets)
          ..where((table) => table.id.equals(walletId)))
        .getSingleOrNull();
    if (wallet == null) {
      return;
    }
    await (_database.update(_database.wallets)
          ..where((table) => table.id.equals(walletId)))
        .write(WalletsCompanion(balance: Value<int>(wallet.balance + delta)));
  }

  TransactionDetail _mapRow(TypedResult row) {
    return TransactionDetail(
      transaction: row.readTable(_database.transactions),
      wallet: row.readTable(_database.wallets),
      category: row.readTableOrNull(_database.categories),
    );
  }
}

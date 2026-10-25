import 'package:drift/drift.dart';

import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';
import '../../wallets/domain/wallet_balance.dart';
import 'transaction_merchant_rules.dart';

/// Operasi tulis transaksi beserta efek saldo dan aturan merchant.
class TransactionWriter {
  TransactionWriter(this.database);

  final AppDatabase database;

  Future<int> addTransaction({
    required int amount,
    required String type,
    required int walletId,
    int? counterpartWalletId,
    int? categoryId,
    String? note,
    String? merchant,
    String source = TransactionSource.manual,
    DateTime? createdAt,
    int? nativeCaptureId,
    bool excludeFromTarget = false,
  }) {
    return database.transaction(() async {
      final int? counterpart = _validateAndNormalize(
        amount: amount,
        type: type,
        walletId: walletId,
        counterpartWalletId: counterpartWalletId,
      );
      final int? normalizedCategory = type == TransactionType.transfer
          ? null
          : categoryId;
      final int id = await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              amount: amount,
              type: type,
              walletId: walletId,
              counterpartWalletId: Value<int?>(counterpart),
              categoryId: Value<int?>(normalizedCategory),
              note: Value<String?>(note),
              merchant: Value<String?>(merchant),
              source: Value<String>(source),
              createdAt: Value<DateTime>(createdAt ?? DateTime.now()),
              isCategorized: Value<bool>(
                type == TransactionType.transfer || normalizedCategory != null,
              ),
              nativeCaptureId: Value<int?>(nativeCaptureId),
              excludeFromTarget: Value<bool>(
                type == TransactionType.expense && excludeFromTarget,
              ),
            ),
          );
      await applyTransactionEffect(
        database,
        amount: amount,
        type: type,
        walletId: walletId,
        counterpartWalletId: counterpart,
        sign: 1,
      );
      await syncTransactionMerchantRule(
        database,
        oldMerchant: null,
        oldType: null,
        oldCategoryId: null,
        newMerchant: merchant,
        newType: type,
        newCategoryId: normalizedCategory,
      );
      return id;
    });
  }

  Future<bool> updateTransaction({
    required int id,
    required int amount,
    required String type,
    required int walletId,
    int? counterpartWalletId,
    int? categoryId,
    String? note,
    String? merchant,
    bool excludeFromTarget = false,
  }) {
    return database.transaction(() async {
      final TransactionRecord? original = await (database.select(
        database.transactions,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (original == null) {
        return false;
      }
      final int? counterpart = _validateAndNormalize(
        amount: amount,
        type: type,
        walletId: walletId,
        counterpartWalletId: counterpartWalletId,
      );
      final int? normalizedCategory = type == TransactionType.transfer
          ? null
          : categoryId;

      await applyTransactionEffect(
        database,
        amount: original.amount,
        type: original.type,
        walletId: original.walletId,
        counterpartWalletId: original.counterpartWalletId,
        sign: -1,
      );
      await applyTransactionEffect(
        database,
        amount: amount,
        type: type,
        walletId: walletId,
        counterpartWalletId: counterpart,
        sign: 1,
      );

      await (database.update(
        database.transactions,
      )..where((table) => table.id.equals(id))).write(
        TransactionsCompanion(
          amount: Value<int>(amount),
          type: Value<String>(type),
          walletId: Value<int>(walletId),
          counterpartWalletId: Value<int?>(counterpart),
          categoryId: Value<int?>(normalizedCategory),
          note: Value<String?>(note),
          merchant: Value<String?>(merchant),
          isCategorized: Value<bool>(
            type == TransactionType.transfer || normalizedCategory != null,
          ),
          excludeFromTarget: Value<bool>(
            type == TransactionType.expense && excludeFromTarget,
          ),
        ),
      );

      return syncTransactionMerchantRule(
        database,
        oldMerchant: original.merchant,
        oldType: original.type,
        oldCategoryId: original.categoryId,
        newMerchant: merchant,
        newType: type,
        newCategoryId: normalizedCategory,
      );
    });
  }

  Future<TransactionRecord?> deleteTransaction(int id) {
    return database.transaction(() async {
      final TransactionRecord? record = await (database.select(
        database.transactions,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (record == null) {
        return null;
      }
      await (database.delete(
        database.transactions,
      )..where((table) => table.id.equals(id))).go();
      await applyTransactionEffect(
        database,
        amount: record.amount,
        type: record.type,
        walletId: record.walletId,
        counterpartWalletId: record.counterpartWalletId,
        sign: -1,
      );
      return record;
    });
  }

  int? _validateAndNormalize({
    required int amount,
    required String type,
    required int walletId,
    required int? counterpartWalletId,
  }) {
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Nominal wajib lebih dari 0.',
      );
    }
    if (type == TransactionType.transfer) {
      if (counterpartWalletId == null || counterpartWalletId == walletId) {
        throw ArgumentError('Dompet asal dan tujuan transfer harus berbeda.');
      }
      return counterpartWalletId;
    }
    if (type != TransactionType.expense && type != TransactionType.income) {
      throw ArgumentError.value(type, 'type', 'Jenis transaksi tidak dikenal.');
    }
    return null;
  }
}

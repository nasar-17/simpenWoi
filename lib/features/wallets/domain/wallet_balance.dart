import 'package:drift/drift.dart';

import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';

int balanceDelta({required String type, required int amount}) {
  if (type == TransactionType.adjustment) {
    return amount;
  }
  return type == TransactionType.income ? amount : -amount;
}

Future<void> applyTransactionEffect(
  AppDatabase database, {
  required int amount,
  required String type,
  required int walletId,
  int? counterpartWalletId,
  required int sign,
}) async {
  if (type == TransactionType.transfer) {
    await adjustWalletBalance(database, walletId, -amount * sign);
    if (counterpartWalletId != null) {
      await adjustWalletBalance(database, counterpartWalletId, amount * sign);
    }
    return;
  }
  await adjustWalletBalance(
    database,
    walletId,
    balanceDelta(type: type, amount: amount) * sign,
  );
}

Future<void> adjustWalletBalance(
  AppDatabase database,
  int walletId,
  int delta,
) async {
  if (delta == 0) {
    return;
  }
  final Wallet? wallet = await (database.select(
    database.wallets,
  )..where((table) => table.id.equals(walletId))).getSingleOrNull();
  if (wallet == null) {
    return;
  }
  await (database.update(database.wallets)
        ..where((table) => table.id.equals(walletId)))
      .write(WalletsCompanion(balance: Value<int>(wallet.balance + delta)));
}

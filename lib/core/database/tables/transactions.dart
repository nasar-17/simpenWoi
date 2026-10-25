import 'package:drift/drift.dart';

import 'categories.dart';
import 'wallets.dart';

@TableIndex(name: 'idx_transactions_created_at', columns: {#createdAt})
@TableIndex(name: 'idx_transactions_wallet_id', columns: {#walletId})
@TableIndex(name: 'idx_transactions_category_id', columns: {#categoryId})
@TableIndex(name: 'idx_transactions_is_categorized', columns: {#isCategorized})
@DataClassName('TransactionRecord')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get type => text()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get counterpartWalletId =>
      integer().nullable().references(Wallets, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get note => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  IntColumn get nativeCaptureId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isCategorized =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get excludeFromTarget =>
      boolean().withDefault(const Constant(false))();
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../category_catalog.dart';

part 'app_database.g.dart';

@DataClassName('Wallet')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TransactionRecord')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get type => text()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get note => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  IntColumn get nativeCaptureId => integer().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isCategorized =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('SavingsGoal')
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get targetAmount => integer()();
  IntColumn get savedAmount => integer().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SavingsDeposit')
class SavingsDeposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(SavingsGoals, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('MerchantRule')
class MerchantRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get merchant => text().withLength(min: 1, max: 100).unique()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
}

@DriftDatabase(
  tables: <Type>[
    Wallets,
    Categories,
    Transactions,
    SavingsGoals,
    SavingsDeposits,
    MerchantRules,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'simpen_woi'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (Migrator migrator, int from, int to) async {
          if (from < 2) {
            await migrator.createTable(savingsGoals);
            await migrator.createTable(savingsDeposits);
          }
          if (from < 3) {
            await migrator.createTable(merchantRules);
          }
          if (from < 4) {
            await migrator.addColumn(transactions, transactions.nativeCaptureId);
          }
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> seedDefaults() async {
    await transaction(() async {
      final int walletCount = await _countRows('wallets');
      if (walletCount == 0) {
        await customStatement(
          "INSERT INTO wallets (name, balance, is_default, created_at) "
          "VALUES ('Tunai', 0, 1, CAST(strftime('%s','now') AS INTEGER))",
        );
      }

      final int categoryCount = await _countRows('categories');
      if (categoryCount == 0) {
        for (final SeedCategory category in seedCategories) {
          await customStatement(
            "INSERT INTO categories (id, name, type, created_at) "
            "VALUES (?, ?, ?, CAST(strftime('%s','now') AS INTEGER))",
            <Object?>[category.id, category.name, category.type],
          );
        }
      }
    });
  }

  Future<int> _countRows(String table) async {
    final QueryRow row =
        await customSelect('SELECT COUNT(*) AS total FROM $table').getSingle();
    return row.read<int>('total');
  }
}

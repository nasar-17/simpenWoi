import 'package:drift/drift.dart';

import 'app_database.dart';

MigrationStrategy buildMigrationStrategy(AppDatabase database) {
  return MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(database.savingsGoals);
        await migrator.createTable(database.savingsDeposits);
      }
      if (from < 3) {
        await migrator.createTable(database.merchantRules);
      }
      if (from < 4) {
        await migrator.addColumn(
          database.transactions,
          database.transactions.nativeCaptureId,
        );
      }
      if (from < 5) {
        await _createTransactionIndexes(database);
      }
      if (from < 6) {
        await migrator.addColumn(
          database.categories,
          database.categories.keywords,
        );
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await database.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

Future<void> _createTransactionIndexes(AppDatabase database) async {
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_transactions_created_at '
    'ON transactions (created_at)',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_transactions_wallet_id '
    'ON transactions (wallet_id)',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_transactions_category_id '
    'ON transactions (category_id)',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_transactions_is_categorized '
    'ON transactions (is_categorized)',
  );
}

import 'package:drift/drift.dart';

import '../constants/category_catalog.dart';
import 'app_database.dart';

Future<void> seedDatabase(AppDatabase database) async {
  await database.transaction(() async {
    final int walletCount = await _countRows(database, 'wallets');
    if (walletCount == 0) {
      await database.customStatement(
        "INSERT INTO wallets (name, balance, is_default, created_at) "
        "VALUES ('Tunai', 0, 1, CAST(strftime('%s','now') AS INTEGER))",
      );
    }

    final int categoryCount = await _countRows(database, 'categories');
    if (categoryCount == 0) {
      for (final SeedCategory category in seedCategories) {
        await database.customStatement(
          'INSERT INTO categories (id, name, type, created_at) '
          "VALUES (?, ?, ?, CAST(strftime('%s','now') AS INTEGER))",
          <Object?>[category.id, category.name, category.type],
        );
      }
    }
  });
}

Future<int> _countRows(AppDatabase database, String table) async {
  final QueryRow row = await database
      .customSelect('SELECT COUNT(*) AS total FROM $table')
      .getSingle();
  return row.read<int>('total');
}

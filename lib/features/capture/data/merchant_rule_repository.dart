import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Menyimpan dan memperbarui aturan merchant untuk kategori otomatis.
class MerchantRuleRepository {
  MerchantRuleRepository(this._database);

  final AppDatabase _database;

  Future<List<MerchantRule>> getAll() {
    return _database.select(_database.merchantRules).get();
  }

  Future<void> recordUsage(String merchant, int categoryId) async {
    final String normalized = merchant.trim().toLowerCase();
    if (normalized.isEmpty || categoryId <= 0) {
      return;
    }

    await _database.transaction(() async {
      final MerchantRule? existing = await (_database.select(
        _database.merchantRules,
      )..where((table) => table.merchant.equals(normalized))).getSingleOrNull();
      if (existing == null) {
        await _database
            .into(_database.merchantRules)
            .insert(
              MerchantRulesCompanion.insert(
                merchant: normalized,
                categoryId: categoryId,
                useCount: const Value<int>(1),
              ),
            );
        return;
      }

      await (_database.update(
        _database.merchantRules,
      )..where((table) => table.id.equals(existing.id))).write(
        MerchantRulesCompanion(
          categoryId: Value<int>(categoryId),
          useCount: Value<int>(existing.useCount + 1),
        ),
      );
    });
  }
}

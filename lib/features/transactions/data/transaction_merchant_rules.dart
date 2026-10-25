import 'package:drift/drift.dart';

import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';

/// Menyelaraskan aturan merchant saat transaksi ditambah atau diedit.
Future<bool> syncTransactionMerchantRule(
  AppDatabase database, {
  required String? oldMerchant,
  required String? oldType,
  required int? oldCategoryId,
  required String? newMerchant,
  required String newType,
  required int? newCategoryId,
}) async {
  final String? oldKey = _normalize(oldMerchant);
  final String? newKey = _normalize(newMerchant);
  final bool oldQualifies =
      oldType == TransactionType.expense &&
      oldCategoryId != null &&
      oldKey != null;
  final bool newQualifies =
      newType == TransactionType.expense &&
      newCategoryId != null &&
      newKey != null;
  bool changed = false;

  if (oldQualifies && oldKey != newKey) {
    await _deleteRule(database, oldKey);
    changed = true;
  }
  if (!newQualifies) {
    if (oldQualifies && oldKey == newKey) {
      await _deleteRule(database, oldKey);
      changed = true;
    }
    return changed;
  }

  final bool unchanged =
      oldKey == newKey && oldType == newType && oldCategoryId == newCategoryId;
  if (unchanged) {
    return changed;
  }

  final MerchantRule? existing = await (database.select(
    database.merchantRules,
  )..where((table) => table.merchant.equals(newKey))).getSingleOrNull();
  if (existing == null) {
    await database
        .into(database.merchantRules)
        .insert(
          MerchantRulesCompanion.insert(
            merchant: newKey,
            categoryId: newCategoryId,
            useCount: const Value<int>(1),
          ),
        );
  } else {
    await (database.update(
      database.merchantRules,
    )..where((table) => table.id.equals(existing.id))).write(
      MerchantRulesCompanion(
        categoryId: Value<int>(newCategoryId),
        useCount: Value<int>(existing.useCount + 1),
      ),
    );
  }
  return true;
}

Future<void> _deleteRule(AppDatabase database, String merchant) {
  return (database.delete(
    database.merchantRules,
  )..where((table) => table.merchant.equals(merchant))).go();
}

String? _normalize(String? merchant) {
  final String normalized = merchant?.trim().toLowerCase() ?? '';
  return normalized.isEmpty ? null : normalized;
}

import 'package:drift/drift.dart';

import '../../../core/constants/transaction_values.dart';
import '../../../core/database/app_database.dart';

class SpendingTargetRepository {
  SpendingTargetRepository(this._database);

  final AppDatabase _database;

  Stream<SpendingTarget?> watchTarget(String month) {
    return (_database.select(
      _database.spendingTargets,
    )..where((table) => table.month.equals(month))).watchSingleOrNull();
  }

  Future<SpendingTarget?> getTarget(String month) {
    return (_database.select(
      _database.spendingTargets,
    )..where((table) => table.month.equals(month))).getSingleOrNull();
  }

  Stream<int> watchSpent(DateTime month) {
    final DateTime start = DateTime(month.year, month.month, 1);
    final DateTime end = DateTime(month.year, month.month + 1, 1);
    return _database
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
          'WHERE type = ? AND exclude_from_target = 0 '
          'AND created_at >= ? AND created_at < ?',
          variables: <Variable<Object>>[
            Variable.withString(TransactionType.expense),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
          ],
          readsFrom: <ResultSetImplementation>{_database.transactions},
        )
        .watchSingle()
        .map((QueryRow row) => row.read<int>('total'));
  }

  Future<void> saveTarget({required String month, required int limitAmount}) {
    return _database.transaction(() async {
      final SpendingTarget? existing = await getTarget(month);
      if (existing == null) {
        await _database
            .into(_database.spendingTargets)
            .insert(
              SpendingTargetsCompanion.insert(
                month: month,
                limitAmount: limitAmount,
              ),
            );
        return;
      }
      await (_database.update(
        _database.spendingTargets,
      )..where((table) => table.month.equals(month))).write(
        SpendingTargetsCompanion(limitAmount: Value<int>(limitAmount)),
      );
    });
  }

  Future<void> deleteTarget(String month) async {
    await (_database.delete(
      _database.spendingTargets,
    )..where((table) => table.month.equals(month))).go();
  }
}

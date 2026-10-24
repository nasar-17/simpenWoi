import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Akses data target tabungan dan setoran.
class SavingsRepository {
  SavingsRepository(this._database);

  final AppDatabase _database;

  Stream<List<SavingsGoal>> watchGoals() {
    return _database
        .select(_database.savingsGoals)
        .watch()
        .map(
          (List<SavingsGoal> goals) => goals
            ..sort(
              (SavingsGoal a, SavingsGoal b) =>
                  b.createdAt.compareTo(a.createdAt),
            ),
        );
  }

  Future<int> addGoal({
    required String name,
    required int targetAmount,
    DateTime? deadline,
  }) {
    return _database
        .into(_database.savingsGoals)
        .insert(
          SavingsGoalsCompanion.insert(
            name: name,
            targetAmount: targetAmount,
            deadline: Value<DateTime?>(deadline),
          ),
        );
  }

  Future<void> updateGoal({
    required int id,
    required String name,
    required int targetAmount,
    DateTime? deadline,
  }) async {
    await (_database.update(
      _database.savingsGoals,
    )..where((table) => table.id.equals(id))).write(
      SavingsGoalsCompanion(
        name: Value<String>(name),
        targetAmount: Value<int>(targetAmount),
        deadline: Value<DateTime?>(deadline),
      ),
    );
  }

  Future<void> deleteGoal(int id) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.savingsDeposits,
      )..where((table) => table.goalId.equals(id))).go();
      await (_database.delete(
        _database.savingsGoals,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<void> addDeposit({required int goalId, required int amount}) {
    return _database.transaction(() async {
      final SavingsGoal? goal = await (_database.select(
        _database.savingsGoals,
      )..where((table) => table.id.equals(goalId))).getSingleOrNull();
      if (goal == null) {
        return;
      }

      await _database
          .into(_database.savingsDeposits)
          .insert(
            SavingsDepositsCompanion.insert(goalId: goalId, amount: amount),
          );
      await (_database.update(
        _database.savingsGoals,
      )..where((table) => table.id.equals(goalId))).write(
        SavingsGoalsCompanion(
          savedAmount: Value<int>(goal.savedAmount + amount),
        ),
      );
    });
  }
}

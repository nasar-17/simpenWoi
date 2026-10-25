import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'migrations.dart';
import 'seed_data.dart';
import 'tables/categories.dart';
import 'tables/merchant_rules.dart';
import 'tables/savings_goals.dart';
import 'tables/spending_targets.dart';
import 'tables/transactions.dart';
import 'tables/wallets.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Wallets,
    Categories,
    Transactions,
    SavingsGoals,
    SavingsDeposits,
    MerchantRules,
    SpendingTargets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'simpen_woi'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);

  Future<void> seedDefaults() => seedDatabase(this);
}

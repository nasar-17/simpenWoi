import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/spending_target_repository.dart';

final Provider<SpendingTargetRepository> spendingTargetRepositoryProvider =
    Provider<SpendingTargetRepository>(
      (ref) => SpendingTargetRepository(ref.watch(databaseProvider)),
    );

final spendingTargetProvider = StreamProvider.family<SpendingTarget?, String>(
  (ref, String month) =>
      ref.watch(spendingTargetRepositoryProvider).watchTarget(month),
);

final spendingSpentProvider = StreamProvider.family<int, DateTime>(
  (ref, DateTime month) =>
      ref.watch(spendingTargetRepositoryProvider).watchSpent(month),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/savings_repository.dart';

final Provider<SavingsRepository> savingsRepositoryProvider =
    Provider<SavingsRepository>(
      (ref) => SavingsRepository(ref.watch(databaseProvider)),
    );

final StreamProvider<List<SavingsGoal>> savingsGoalsProvider =
    StreamProvider<List<SavingsGoal>>(
      (ref) => ref.watch(savingsRepositoryProvider).watchGoals(),
    );

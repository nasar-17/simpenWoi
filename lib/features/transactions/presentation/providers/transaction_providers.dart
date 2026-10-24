import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/transaction_detail.dart';
import '../../data/transaction_repository.dart';

final Provider<TransactionRepository> transactionRepositoryProvider =
    Provider<TransactionRepository>(
      (ref) => TransactionRepository(ref.watch(databaseProvider)),
    );

final StreamProvider<List<Category>> categoriesProvider =
    StreamProvider<List<Category>>(
      (ref) => ref.watch(transactionRepositoryProvider).watchCategories(),
    );

final StreamProvider<List<TransactionDetail>> todayTransactionsProvider =
    StreamProvider<List<TransactionDetail>>((ref) {
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day);
      final DateTime end = start.add(const Duration(days: 1));
      return ref.watch(transactionRepositoryProvider).watchBetween(start, end);
    });

final StreamProvider<List<TransactionDetail>>
uncategorizedTransactionsProvider = StreamProvider<List<TransactionDetail>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchUncategorized(),
);

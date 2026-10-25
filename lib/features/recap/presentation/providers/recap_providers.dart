import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../transactions/domain/transaction_totals.dart';
import '../../data/recap_repository.dart';
import '../../domain/recap_period.dart';

final Provider<RecapRepository> recapRepositoryProvider =
    Provider<RecapRepository>(
      (ref) => RecapRepository(ref.watch(databaseProvider)),
    );

final recapTotalsProvider =
    StreamProvider.family<TransactionTotals, RecapRange>(
      (ref, range) => ref.watch(recapRepositoryProvider).watchTotals(range),
    );

final recapCategoryTotalsProvider =
    StreamProvider.family<List<RecapCategoryTotal>, RecapRange>(
      (ref, range) =>
          ref.watch(recapRepositoryProvider).watchCategoryTotals(range),
    );

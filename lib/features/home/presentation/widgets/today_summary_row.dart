import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/widgets/amount_summary_card.dart';
import '../../../transactions/data/transaction_detail.dart';
import '../../../transactions/domain/transaction_totals.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class TodaySummaryRow extends ConsumerWidget {
  const TodaySummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TransactionDetail>> todayAsync = ref.watch(
      todayTransactionsProvider,
    );
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return todayAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) =>
          const Text(UiText.loadSummaryFailed),
      data: (List<TransactionDetail> transactions) {
        final TransactionTotals totals = summarizeTransactions(transactions);
        return Row(
          children: <Widget>[
            Expanded(
              child: AmountSummaryCard(
                label: 'Pengeluaran hari ini',
                amount: totals.expense,
                color: scheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AmountSummaryCard(
                label: 'Pemasukan hari ini',
                amount: totals.income,
                color: scheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

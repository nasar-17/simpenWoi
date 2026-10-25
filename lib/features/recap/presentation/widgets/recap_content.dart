import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../transactions/domain/transaction_totals.dart';
import '../../data/recap_repository.dart';
import '../../domain/recap_period.dart';
import '../providers/recap_providers.dart';
import 'recap_category_chart.dart';
import 'recap_summary_cards.dart';

class RecapContent extends ConsumerWidget {
  const RecapContent({super.key, required this.range});

  final RecapRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TransactionTotals> totalsAsync = ref.watch(
      recapTotalsProvider(range),
    );
    final AsyncValue<List<RecapCategoryTotal>> categoriesAsync = ref.watch(
      recapCategoryTotalsProvider(range),
    );

    if (totalsAsync.isLoading || categoriesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (totalsAsync.hasError || categoriesAsync.hasError) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(UiText.loadRecapFailed),
      );
    }

    final TransactionTotals? totals = totalsAsync.value;
    final List<RecapCategoryTotal>? entries = categoriesAsync.value;
    if (totals == null || entries == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RecapSummaryCards(totals: totals),
        const SizedBox(height: 16),
        RecapCategoryChart(entries: entries),
      ],
    );
  }
}

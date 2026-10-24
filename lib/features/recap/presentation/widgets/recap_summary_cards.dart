import 'package:flutter/material.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/widgets/amount_summary_card.dart';
import '../../../transactions/domain/transaction_totals.dart';

class RecapSummaryCards extends StatelessWidget {
  const RecapSummaryCards({super.key, required this.totals});

  final TransactionTotals totals;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: AmountSummaryCard(
            label: UiText.expense,
            amount: totals.expense,
            color: scheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AmountSummaryCard(
            label: UiText.income,
            amount: totals.income,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

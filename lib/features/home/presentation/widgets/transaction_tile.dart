import 'package:flutter/material.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/constants/ui_text.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../transactions/data/transaction_detail.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.detail,
    required this.onDismissed,
    required this.onTap,
  });

  final TransactionDetail detail;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isExpense = detail.transaction.type == TransactionType.expense;
    final bool isTransfer = detail.transaction.type == TransactionType.transfer;
    final Color amountColor = isExpense ? scheme.error : scheme.primary;
    final String sign = isTransfer ? '' : (isExpense ? '-' : '+');
    final String title = isTransfer
        ? 'Transfer'
        : detail.category?.name ?? UiText.noCategory;
    final String walletText = isTransfer
        ? '${detail.wallet.name} \u2192 '
              '${detail.counterpartWallet?.name ?? '-'}'
        : detail.wallet.name;

    return Dismissible(
      key: ValueKey<int>(detail.transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: scheme.errorContainer,
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (DismissDirection direction) => onDismissed(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: isTransfer
              ? Icon(Icons.swap_horiz, color: scheme.primary)
              : null,
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  '$walletText \u2022 '
                  '${formatClockTime(detail.transaction.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (!isTransfer && !detail.transaction.isCategorized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      UiText.uncategorized,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          trailing: Text(
            '$sign${formatRupiah(detail.transaction.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

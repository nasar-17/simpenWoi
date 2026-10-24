import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../transactions/data/transaction_detail.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class UncategorizedBanner extends ConsumerWidget {
  const UncategorizedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(
      uncategorizedTransactionsProvider.select(
        (AsyncValue<List<TransactionDetail>> value) => value.value?.length ?? 0,
      ),
    );
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.secondaryContainer,
        child: ListTile(
          leading: Icon(
            Icons.playlist_add_check,
            color: scheme.onSecondaryContainer,
          ),
          title: Text(
            '$count transaksi perlu dilengkapi',
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Ketuk untuk memilih kategori.',
            style: TextStyle(color: scheme.onSecondaryContainer),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: scheme.onSecondaryContainer,
          ),
          onTap: () => context.push('/uncategorized'),
        ),
      ),
    );
  }
}

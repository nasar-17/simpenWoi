import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../transactions/data/transaction_detail.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../widgets/uncategorized_tile.dart';

class UncategorizedPage extends ConsumerWidget {
  const UncategorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TransactionDetail>> transactionsAsync = ref.watch(
      uncategorizedTransactionsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Perlu dilengkapi')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            const Center(child: Text(UiText.loadTransactionsFailed)),
        data: (List<TransactionDetail> transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Semua transaksi sudah dikategorikan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: transactions.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) =>
                UncategorizedTile(detail: transactions[index]),
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../transactions/data/transaction_detail.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import 'transaction_editor_sheet.dart';
import 'transaction_tile.dart';

class TodayTransactionsSection extends ConsumerStatefulWidget {
  const TodayTransactionsSection({super.key});

  @override
  ConsumerState<TodayTransactionsSection> createState() =>
      _TodayTransactionsSectionState();
}

class _TodayTransactionsSectionState
    extends ConsumerState<TodayTransactionsSection> {
  final Set<int> _hiddenIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TransactionDetail>> todayAsync = ref.watch(
      todayTransactionsProvider,
    );

    return todayAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) =>
          const Text(UiText.loadTransactionsFailed),
      data: (List<TransactionDetail> transactions) {
        final List<TransactionDetail> visible = transactions
            .where(
              (TransactionDetail detail) =>
                  !_hiddenIds.contains(detail.transaction.id),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Transaksi hari ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada transaksi hari ini.\n'
                      'Tekan Catat untuk menambah.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...visible.map(
                (TransactionDetail detail) => TransactionTile(
                  detail: detail,
                  onDismissed: () =>
                      unawaited(_deleteTransaction(context, detail)),
                  onTap: () => _showEditorSheet(context, detail),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showEditorSheet(BuildContext context, TransactionDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) =>
          TransactionEditorSheet(transaction: detail.transaction),
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    TransactionDetail detail,
  ) async {
    final TransactionRecord record = detail.transaction;
    final TransactionRepository repository = ref.read(
      transactionRepositoryProvider,
    );
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() {
      _hiddenIds.add(record.id);
    });

    final TransactionRecord? deleted = await repository.deleteTransaction(
      record.id,
    );
    if (deleted == null) {
      if (mounted) {
        setState(() {
          _hiddenIds.remove(record.id);
        });
      }
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaksi dihapus'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () {
            unawaited(
              repository.addTransaction(
                amount: record.amount,
                type: record.type,
                walletId: record.walletId,
                categoryId: record.categoryId,
                note: record.note,
                merchant: record.merchant,
                source: record.source,
                createdAt: record.createdAt,
              ),
            );
            if (mounted) {
              setState(() {
                _hiddenIds.remove(record.id);
              });
            }
          },
        ),
      ),
    );
  }
}

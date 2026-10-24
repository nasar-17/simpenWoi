import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/transaction_values.dart';
import '../../core/utils/currency.dart';
import '../transactions/transaction_providers.dart';
import '../transactions/transaction_repository.dart';
import 'capture_sync_service.dart';

class UncategorizedPage extends ConsumerWidget {
  const UncategorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TransactionDetail>> transactionsAsync =
        ref.watch(uncategorizedTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perlu dilengkapi'),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            const Center(child: Text('Gagal memuat transaksi')),
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
                _UncategorizedTile(detail: transactions[index]),
          );
        },
      ),
    );
  }
}

class _UncategorizedTile extends ConsumerWidget {
  const _UncategorizedTile({required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransactionRecord record = detail.transaction;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String merchant = record.merchant?.trim() ?? '';
    final String note = record.note?.trim() ?? '';
    final String title = merchant.isNotEmpty
        ? merchant
        : note.isNotEmpty
            ? note
            : 'Transaksi tanpa keterangan';
    final String date = DateFormat('d MMM yyyy, HH:mm', 'id_ID')
        .format(record.createdAt);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(
            Icons.receipt_long,
            color: scheme.onSecondaryContainer,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          '${formatRupiah(record.amount)} \u2022 ${detail.wallet.name}\n$date',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pickCategory(context, ref),
      ),
    );
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    final List<Category> categories = (await ref
            .read(transactionRepositoryProvider)
            .getCategories())
        .where((Category category) => category.type == TransactionType.expense)
        .toList();
    if (!context.mounted) {
      return;
    }

    final int? selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text(
              'Pilih kategori',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...categories.map(
              (Category category) => ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(category.name),
                onTap: () => Navigator.of(context).pop(category.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) {
      return;
    }

    await ref
        .read(captureSyncServiceProvider)
        .categorizeTransaction(detail.transaction, selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori tersimpan')),
      );
    }
  }
}

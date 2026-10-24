import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../transactions/data/transaction_detail.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/capture_providers.dart';
import 'category_picker_sheet.dart';

class UncategorizedTile extends ConsumerWidget {
  const UncategorizedTile({super.key, required this.detail});

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
    final String date = formatDateTimeShort(record.createdAt);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(Icons.receipt_long, color: scheme.onSecondaryContainer),
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
    final List<Category> categories = await ref
        .read(transactionRepositoryProvider)
        .getExpenseCategories();
    if (!context.mounted) {
      return;
    }

    final int? selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext context) =>
          CategoryPickerSheet(categories: categories),
    );
    if (selected == null) {
      return;
    }

    await ref
        .read(captureSyncServiceProvider)
        .categorizeTransaction(detail.transaction, selected);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategori tersimpan')));
    }
  }
}

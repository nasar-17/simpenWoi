import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import 'category_dropdown.dart';
import 'transaction_type_selector.dart';
import 'wallet_dropdown.dart';

class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({super.key, required this.transaction});

  final TransactionRecord transaction;

  @override
  ConsumerState<TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<TransactionEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _merchantController;
  late String _type;
  late int? _categoryId;
  late int _walletId;

  @override
  void initState() {
    super.initState();
    final TransactionRecord transaction = widget.transaction;
    _amountController = TextEditingController(
      text: formatRupiah(transaction.amount),
    );
    _noteController = TextEditingController(text: transaction.note ?? '');
    _merchantController = TextEditingController(
      text: transaction.merchant ?? '',
    );
    _type = transaction.type;
    _categoryId = transaction.categoryId;
    _walletId = transaction.walletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _type = newType;
      if (_categoryId != null) {
        final bool stillValid =
            ref
                .read(categoriesProvider)
                .value
                ?.any(
                  (Category category) =>
                      category.id == _categoryId && category.type == newType,
                ) ??
            false;
        if (!stillValid) {
          _categoryId = null;
        }
      }
    });
  }

  Future<void> _save() async {
    final int amount = parseCurrencyInput(_amountController.text);
    if (amount <= 0) {
      return;
    }
    final String note = _noteController.text.trim();
    final String merchant = _merchantController.text.trim();

    await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(
          id: widget.transaction.id,
          amount: amount,
          type: _type,
          walletId: _walletId,
          categoryId: _categoryId,
          note: note.isEmpty ? null : note,
          merchant: merchant.isEmpty ? null : merchant,
        );

    final int? categoryId = _categoryId;
    if (categoryId != null) {
      await ref
          .read(captureSyncServiceProvider)
          .recordMerchantUsage(merchant.isEmpty ? null : merchant, categoryId);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Edit transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: const <TextInputFormatter>[
                CurrencyInputFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            ),
            const SizedBox(height: 12),
            TransactionTypeSelector(type: _type, onChanged: _onTypeChanged),
            const SizedBox(height: 12),
            CategoryDropdown(
              type: _type,
              initialValue: _categoryId,
              onChanged: (int? value) {
                setState(() {
                  _categoryId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant (opsional)',
              ),
            ),
            const SizedBox(height: 12),
            WalletDropdown(
              preferredId: _walletId,
              onChanged: (int value) {
                setState(() {
                  _walletId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(UiText.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text(UiText.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

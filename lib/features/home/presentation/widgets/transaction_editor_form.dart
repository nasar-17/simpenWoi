import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/constants/ui_text.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import 'category_dropdown.dart';
import 'transaction_type_selector.dart';
import 'wallet_dropdown.dart';

class TransactionEditorForm extends StatelessWidget {
  const TransactionEditorForm({
    super.key,
    required this.amountController,
    required this.noteController,
    required this.merchantController,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.counterpartWalletId,
    required this.excludeFromTarget,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onCounterpartWalletChanged,
    required this.onExcludeFromTargetChanged,
    required this.onWalletChanged,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController amountController;
  final TextEditingController noteController;
  final TextEditingController merchantController;
  final String type;
  final int? categoryId;
  final int walletId;
  final int? counterpartWalletId;
  final bool excludeFromTarget;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int> onCounterpartWalletChanged;
  final ValueChanged<bool> onExcludeFromTargetChanged;
  final ValueChanged<int> onWalletChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bool isTransfer = type == TransactionType.transfer;
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
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: const <TextInputFormatter>[
                CurrencyInputFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            ),
            const SizedBox(height: 12),
            TransactionTypeSelector(type: type, onChanged: onTypeChanged),
            const SizedBox(height: 12),
            if (isTransfer)
              WalletDropdown(
                preferredId: counterpartWalletId,
                label: 'Dompet tujuan',
                onChanged: onCounterpartWalletChanged,
              )
            else
              CategoryDropdown(
                type: type,
                initialValue: categoryId,
                onChanged: onCategoryChanged,
              ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            if (!isTransfer) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant (opsional)',
                ),
              ),
            ],
            if (!isTransfer && type == TransactionType.expense)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kecualikan dari target pengeluaran'),
                value: excludeFromTarget,
                onChanged: onExcludeFromTargetChanged,
              ),
            const SizedBox(height: 12),
            WalletDropdown(
              preferredId: walletId,
              label: isTransfer ? 'Dompet asal' : 'Dompet',
              onChanged: onWalletChanged,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: onCancel,
                  child: const Text(UiText.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onSave, child: const Text(UiText.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import 'category_dropdown.dart';
import 'transaction_type_selector.dart';
import 'wallet_dropdown.dart';

class CaptureDetailsForm extends StatelessWidget {
  const CaptureDetailsForm({
    super.key,
    required this.amountController,
    required this.noteController,
    required this.type,
    required this.categoryId,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    this.counterpartWalletId,
    this.onCounterpartWalletChanged,
  });

  final TextEditingController amountController;
  final TextEditingController noteController;
  final String type;
  final int? categoryId;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int?> onCategoryChanged;
  final int? counterpartWalletId;
  final ValueChanged<int>? onCounterpartWalletChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
            if (type == TransactionType.transfer)
              WalletDropdown(
                preferredId: counterpartWalletId,
                label: 'Dompet tujuan',
                onChanged: onCounterpartWalletChanged!,
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/constants/ui_text.dart';
import '../../../home/presentation/widgets/capture_details_form.dart';
import '../../../home/presentation/widgets/wallet_dropdown.dart';
import 'coming_soon_cards.dart';

class InputFormBody extends StatelessWidget {
  const InputFormBody({
    super.key,
    required this.inputController,
    required this.amountController,
    required this.noteController,
    required this.parsedAmount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.counterpartWalletId,
    required this.excludeFromTarget,
    required this.onInputChanged,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onCounterpartWalletChanged,
    required this.onExcludeFromTargetChanged,
    required this.onWalletChanged,
    required this.onSave,
  });

  final TextEditingController inputController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final int parsedAmount;
  final String type;
  final int? categoryId;
  final int? walletId;
  final int? counterpartWalletId;
  final bool excludeFromTarget;
  final ValueChanged<String> onInputChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int> onCounterpartWalletChanged;
  final ValueChanged<bool> onExcludeFromTargetChanged;
  final ValueChanged<int> onWalletChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        TextField(
          controller: inputController,
          decoration: const InputDecoration(
            labelText: 'Tulis transaksi',
            hintText: 'Misalnya: bakso 15rb',
          ),
          onChanged: onInputChanged,
        ),
        if (parsedAmount > 0) ...<Widget>[
          const SizedBox(height: 16),
          CaptureDetailsForm(
            amountController: amountController,
            noteController: noteController,
            type: type,
            categoryId: categoryId,
            counterpartWalletId: counterpartWalletId,
            onTypeChanged: onTypeChanged,
            onCategoryChanged: onCategoryChanged,
            onCounterpartWalletChanged: onCounterpartWalletChanged,
          ),
        ],
        if (type == TransactionType.expense)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kecualikan dari target pengeluaran'),
            value: excludeFromTarget,
            onChanged: onExcludeFromTargetChanged,
          ),
        const SizedBox(height: 16),
        WalletDropdown(
          preferredId: walletId,
          isDense: true,
          label: type == TransactionType.transfer ? 'Dompet asal' : 'Dompet',
          onChanged: onWalletChanged,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: parsedAmount > 0 ? onSave : null,
          child: const Text(UiText.save),
        ),
        const SizedBox(height: 24),
        const ComingSoonCards(),
      ],
    );
  }
}

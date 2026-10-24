import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../providers/savings_providers.dart';

class DepositSheet extends ConsumerStatefulWidget {
  const DepositSheet({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  ConsumerState<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<DepositSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int remaining = widget.goal.targetAmount > widget.goal.savedAmount
        ? widget.goal.targetAmount - widget.goal.savedAmount
        : 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Setor ke ${widget.goal.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Terkumpul ${formatRupiah(widget.goal.savedAmount)} '
              'dari ${formatRupiah(widget.goal.targetAmount)}'
              '${remaining > 0 ? '\u2022 sisa ${formatRupiah(remaining)}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: const <TextInputFormatter>[
                CurrencyInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah setoran (Rp)',
                hintText: 'Misalnya: 100.000',
              ),
              validator: (String? value) {
                final int amount = parseCurrencyInput(value ?? '');
                if (amount <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Setor')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref
        .read(savingsRepositoryProvider)
        .addDeposit(
          goalId: widget.goal.id,
          amount: parseCurrencyInput(_amountController.text),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

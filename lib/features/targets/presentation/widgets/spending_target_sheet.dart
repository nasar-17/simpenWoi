import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/spending_target_summary.dart';
import '../providers/spending_target_providers.dart';

Future<void> showSpendingTargetSheet(
  BuildContext context, {
  required DateTime month,
  int? initialAmount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) =>
        SpendingTargetSheet(month: month, initialAmount: initialAmount),
  );
}

class SpendingTargetSheet extends ConsumerStatefulWidget {
  const SpendingTargetSheet({
    super.key,
    required this.month,
    this.initialAmount,
  });

  final DateTime month;
  final int? initialAmount;

  @override
  ConsumerState<SpendingTargetSheet> createState() =>
      _SpendingTargetSheetState();
}

class _SpendingTargetSheetState extends ConsumerState<SpendingTargetSheet> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount == null
          ? ''
          : formatRupiahDigits(widget.initialAmount!),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final int amount = parseCurrencyInput(_amountController.text);
    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Target harus lebih dari 0.')),
      );
      return;
    }
    await ref
        .read(spendingTargetRepositoryProvider)
        .saveTarget(month: spendingMonthKey(widget.month), limitAmount: amount);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Target pengeluaran',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            formatMonthYear(widget.month),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: const <TextInputFormatter>[
              CurrencyInputFormatter(),
            ],
            decoration: const InputDecoration(labelText: 'Batas pengeluaran'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('Simpan')),
            ],
          ),
        ],
      ),
    );
  }
}

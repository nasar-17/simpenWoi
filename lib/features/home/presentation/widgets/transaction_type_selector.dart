import 'package:flutter/material.dart';

import '../../../../core/constants/transaction_values.dart';

class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.type,
    required this.onChanged,
  });

  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: TransactionType.expense,
          label: Text('Keluar'),
        ),
        ButtonSegment<String>(
          value: TransactionType.income,
          label: Text('Masuk'),
        ),
        ButtonSegment<String>(
          value: TransactionType.transfer,
          label: Text('Transfer'),
        ),
      ],
      selected: <String>{type},
      onSelectionChanged: (Set<String> selection) => onChanged(selection.first),
    );
  }
}

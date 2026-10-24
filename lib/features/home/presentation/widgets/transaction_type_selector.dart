import 'package:flutter/material.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/constants/ui_text.dart';

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
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: TransactionType.expense,
          label: Text(UiText.expense),
          icon: Icon(Icons.trending_down),
        ),
        ButtonSegment<String>(
          value: TransactionType.income,
          label: Text(UiText.income),
          icon: Icon(Icons.trending_up),
        ),
      ],
      selected: <String>{type},
      onSelectionChanged: (Set<String> selection) => onChanged(selection.first),
    );
  }
}

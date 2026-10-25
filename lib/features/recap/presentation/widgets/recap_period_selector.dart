import 'package:flutter/material.dart';

import '../../domain/recap_period.dart';

class RecapPeriodSelector extends StatelessWidget {
  const RecapPeriodSelector({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final RecapPeriod period;
  final ValueChanged<RecapPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RecapPeriod>(
      segments: const <ButtonSegment<RecapPeriod>>[
        ButtonSegment<RecapPeriod>(
          value: RecapPeriod.daily,
          label: Text('Harian'),
        ),
        ButtonSegment<RecapPeriod>(
          value: RecapPeriod.weekly,
          label: Text('Mingguan'),
        ),
        ButtonSegment<RecapPeriod>(
          value: RecapPeriod.monthly,
          label: Text('Bulanan'),
        ),
      ],
      selected: <RecapPeriod>{period},
      onSelectionChanged: (Set<RecapPeriod> selection) =>
          onChanged(selection.first),
    );
  }
}

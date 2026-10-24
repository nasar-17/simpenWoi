import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/recap_period.dart';

class RecapRangeHeader extends StatelessWidget {
  const RecapRangeHeader({
    super.key,
    required this.period,
    required this.range,
    required this.onShift,
  });

  final RecapPeriod period;
  final RecapRange range;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onShift(-1),
        ),
        Expanded(
          child: Text(
            _rangeLabel(period, range),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onShift(1),
        ),
      ],
    );
  }

  String _rangeLabel(RecapPeriod period, RecapRange range) {
    switch (period) {
      case RecapPeriod.daily:
        return formatWeekdayDate(range.start);
      case RecapPeriod.weekly:
        final DateTime lastDay = range.end.subtract(const Duration(days: 1));
        return '${formatDayMonth(range.start)} - '
            '${formatDayMonthYear(lastDay)}';
      case RecapPeriod.monthly:
        return formatMonthYear(range.start);
    }
  }
}

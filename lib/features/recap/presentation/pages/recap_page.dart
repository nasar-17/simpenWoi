import 'package:flutter/material.dart';

import '../../domain/recap_period.dart';
import '../widgets/recap_content.dart';
import '../widgets/recap_period_selector.dart';
import '../widgets/recap_range_header.dart';

class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  RecapPeriod _period = RecapPeriod.daily;
  DateTime _anchor = DateTime.now();

  void _setPeriod(RecapPeriod period) {
    if (period == _period) {
      return;
    }
    setState(() {
      _period = period;
    });
  }

  void _shift(int direction) {
    setState(() {
      _anchor = shiftRecapAnchor(_period, _anchor, direction);
    });
  }

  @override
  Widget build(BuildContext context) {
    final RecapRange range = recapRangeFor(_period, _anchor);

    return Scaffold(
      appBar: AppBar(title: const Text('Rekap')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          RecapPeriodSelector(period: _period, onChanged: _setPeriod),
          const SizedBox(height: 16),
          RecapRangeHeader(period: _period, range: range, onShift: _shift),
          const SizedBox(height: 8),
          RecapContent(range: range),
        ],
      ),
    );
  }
}

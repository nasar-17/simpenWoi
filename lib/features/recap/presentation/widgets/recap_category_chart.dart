import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/currency.dart';
import '../../data/recap_repository.dart';

class RecapCategoryChart extends StatelessWidget {
  const RecapCategoryChart({super.key, required this.entries});

  final List<RecapCategoryTotal> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Belum ada pengeluaran di periode ini',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final int total = entries.fold<int>(
      0,
      (int sum, RecapCategoryTotal entry) => sum + entry.amount,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pengeluaran per kategori',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                      sections: <PieChartSectionData>[
                        for (int index = 0; index < entries.length; index++)
                          PieChartSectionData(
                            value: entries[index].amount.toDouble(),
                            color: _colorFor(context, index),
                            radius: 64,
                            title: entries[index].amount / total >= 0.05
                                ? '${(entries[index].amount / total * 100).round()}%'
                                : '',
                            titleStyle: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatRupiah(total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...entries.asMap().entries.map(
              (MapEntry<int, RecapCategoryTotal> entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _colorFor(context, entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.value.name)),
                    Text(
                      formatRupiah(entry.value.amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(BuildContext context, int index) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Color> palette = <Color>[
      scheme.error,
      scheme.primary,
      scheme.tertiary,
      const Color(0xFF0F9D58),
      const Color(0xFF7B1FA2),
      const Color(0xFFEF6C00),
      const Color(0xFF00838F),
      const Color(0xFFAD1457),
    ];
    return palette[index % palette.length];
  }
}

import 'package:flutter/material.dart';

import '../../../../core/utils/currency.dart';
import '../../domain/spending_target_summary.dart';

class SpendingTargetCard extends StatelessWidget {
  const SpendingTargetCard({
    super.key,
    required this.summary,
    required this.onEdit,
    required this.onDelete,
  });

  final SpendingTargetSummary summary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color progressColor = summary.isOver ? scheme.error : scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Target pengeluaran',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opsi',
                  onSelected: (String value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Ubah'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Hapus'),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah(summary.limitAmount),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.progress,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${formatRupiah(summary.spent)} terpakai',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  summary.isOver
                      ? 'Lewat ${formatRupiah(summary.spent - summary.limitAmount)}'
                      : 'Sisa ${formatRupiah(summary.remaining)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: summary.isOver ? scheme.error : scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary.daysRemaining > 0
                  ? 'Boleh pakai ${formatRupiah(summary.dailyAllowance)}/hari '
                        'untuk ${summary.daysRemaining} hari lagi.'
                  : 'Periode target sudah berakhir.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

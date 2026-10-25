import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../targets/domain/spending_target_summary.dart';
import '../../../targets/presentation/providers/spending_target_providers.dart';

class MonthlyTargetCard extends ConsumerWidget {
  const MonthlyTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();
    final DateTime month = DateTime(now.year, now.month, 1);
    final AsyncValue<SpendingTarget?> targetAsync = ref.watch(
      spendingTargetProvider(spendingMonthKey(month)),
    );
    final AsyncValue<int> spentAsync = ref.watch(spendingSpentProvider(month));
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return targetAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stack) => const SizedBox.shrink(),
      data: (SpendingTarget? target) {
        if (target == null) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.track_changes, color: scheme.primary),
              title: const Text('Atur target pengeluaran'),
              subtitle: const Text('Lihat sisa jatah harian bulan ini.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/goals'),
            ),
          );
        }
        return spentAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (Object error, StackTrace stack) => const SizedBox.shrink(),
          data: (int spent) {
            final SpendingTargetSummary summary = summarizeSpendingTarget(
              limitAmount: target.limitAmount,
              spent: spent,
              month: month,
              now: now,
            );
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
                            'Target pengeluaran bulan ini',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${formatRupiah(summary.spent)} / '
                          '${formatRupiah(summary.limitAmount)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: summary.progress,
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          summary.isOver ? scheme.error : scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.isOver
                          ? 'Pengeluaran sudah melewati target.'
                          : 'Sisa ${formatRupiah(summary.remaining)} '
                                '(${formatRupiah(summary.dailyAllowance)}/hari).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: summary.isOver
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

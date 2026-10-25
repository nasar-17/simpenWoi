import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/spending_target_summary.dart';
import '../providers/spending_target_providers.dart';
import '../widgets/spending_target_card.dart';
import '../widgets/spending_target_sheet.dart';

class SpendingTargetTab extends ConsumerStatefulWidget {
  const SpendingTargetTab({super.key});

  @override
  ConsumerState<SpendingTargetTab> createState() => _SpendingTargetTabState();
}

class _SpendingTargetTabState extends ConsumerState<SpendingTargetTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final String key = spendingMonthKey(_month);
    final AsyncValue<SpendingTarget?> targetAsync = ref.watch(
      spendingTargetProvider(key),
    );
    final AsyncValue<int> spentAsync = ref.watch(spendingSpentProvider(_month));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () {
                setState(() {
                  _month = shiftSpendingMonth(_month, -1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                formatMonthYear(_month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _month = shiftSpendingMonth(_month, 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        targetAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) =>
              const Text('Gagal memuat target.'),
          data: (SpendingTarget? target) {
            return spentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) =>
                  const Text('Gagal memuat pengeluaran.'),
              data: (int spent) => _buildContent(target, spent),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(SpendingTarget? target, int spent) {
    if (target == null) {
      return _NoTargetCard(
        month: _month,
        onSet: () => showSpendingTargetSheet(context, month: _month),
        onCopy: _copyPrevious,
      );
    }
    final SpendingTargetSummary summary = summarizeSpendingTarget(
      limitAmount: target.limitAmount,
      spent: spent,
      month: _month,
      now: DateTime.now(),
    );
    return SpendingTargetCard(
      summary: summary,
      onEdit: () => showSpendingTargetSheet(
        context,
        month: _month,
        initialAmount: target.limitAmount,
      ),
      onDelete: _confirmDelete,
    );
  }

  Future<void> _copyPrevious() async {
    final DateTime previousMonth = shiftSpendingMonth(_month, -1);
    final SpendingTarget? previous = await ref
        .read(spendingTargetRepositoryProvider)
        .getTarget(spendingMonthKey(previousMonth));
    if (previous == null || !mounted) {
      return;
    }
    await ref
        .read(spendingTargetRepositoryProvider)
        .saveTarget(
          month: spendingMonthKey(_month),
          limitAmount: previous.limitAmount,
        );
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hapus target?'),
        content: const Text('Target pengeluaran bulan ini akan dihapus.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(spendingTargetRepositoryProvider)
          .deleteTarget(spendingMonthKey(_month));
    }
  }
}

class _NoTargetCard extends ConsumerWidget {
  const _NoTargetCard({
    required this.month,
    required this.onSet,
    required this.onCopy,
  });

  final DateTime month;
  final VoidCallback onSet;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime previous = shiftSpendingMonth(month, -1);
    final AsyncValue<SpendingTarget?> previousAsync = ref.watch(
      spendingTargetProvider(spendingMonthKey(previous)),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.track_changes,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada target pengeluaran',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tetapkan batas pengeluaran bulan ini agar sisa harian lebih jelas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSet, child: const Text('Atur target')),
            previousAsync.maybeWhen(
              data: (SpendingTarget? value) => value == null
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: onCopy,
                      child: const Text('Salin target bulan lalu'),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../targets/presentation/widgets/spending_target_tab.dart';
import '../providers/savings_providers.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_sheets.dart';

class SavingsGoalsPage extends StatelessWidget {
  const SavingsGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Target'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Menabung'),
              Tab(text: 'Pengeluaran'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[_SavingsTab(), SpendingTargetTab()],
        ),
      ),
    );
  }
}

class _SavingsTab extends ConsumerWidget {
  const _SavingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SavingsGoal>> goalsAsync = ref.watch(
      savingsGoalsProvider,
    );
    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) =>
          const Center(child: Text('Gagal memuat target')),
      data: (List<SavingsGoal> goals) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => showGoalForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Target menabung'),
              ),
            ),
            const SizedBox(height: 12),
            if (goals.isEmpty)
              const _EmptyGoalsState()
            else
              ...goals.map((SavingsGoal goal) => GoalCard(goal: goal)),
          ],
        );
      },
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.savings_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada target menabung',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol tambah untuk membuat target baru.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

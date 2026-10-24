import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/currency_input_formatter.dart';
import 'savings_providers.dart';
import 'savings_repository.dart';

class SavingsGoalsPage extends ConsumerWidget {
  const SavingsGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SavingsGoal>> goalsAsync =
        ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target menabung'),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            const Center(child: Text('Gagal memuat target')),
        data: (List<SavingsGoal> goals) {
          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.savings_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: goals.length,
            itemBuilder: (BuildContext context, int index) =>
                _GoalCard(goal: goals[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext context, SavingsGoal? goal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => GoalFormSheet(goal: goal),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double progress = goal.targetAmount <= 0
        ? 0
        : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0).toDouble();
    final int remaining =
        goal.targetAmount > goal.savedAmount
            ? goal.targetAmount - goal.savedAmount
            : 0;

    String? suggestion;
    if (goal.savedAmount >= goal.targetAmount) {
      suggestion = 'Target tercapai';
    } else if (goal.deadline != null) {
      final DateTime deadline =
          DateTime(goal.deadline!.year, goal.deadline!.month, goal.deadline!.day);
      final DateTime today = DateTime.now();
      final int daysLeft = deadline.difference(today).inDays;
      if (daysLeft <= 0) {
        suggestion = 'Tenggat sudah lewat';
      } else {
        final int perDay = (remaining / daysLeft).ceil();
        suggestion = 'Sisihkan ${formatRupiah(perDay)} per hari';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opsi',
                  onSelected: (String value) {
                    if (value == 'edit') {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (BuildContext context) =>
                            GoalFormSheet(goal: goal),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Hapus'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${formatRupiah(goal.savedAmount)} dari ${formatRupiah(goal.targetAmount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (goal.deadline != null) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.event,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tenggat: ${_formatDate(goal.deadline!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
            if (suggestion != null) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  suggestion,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (BuildContext context) => DepositSheet(goal: goal),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Setor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hapus target?'),
        content: Text('Target "${goal.name}" akan dihapus permanen.'),
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
      await ref.read(savingsRepositoryProvider).deleteGoal(goal.id);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }
}

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.goal});

  final SavingsGoal? goal;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetController = TextEditingController(
      text: widget.goal == null ? '' : formatRupiah(widget.goal!.targetAmount),
    );
    _deadline = widget.goal?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.goal == null ? 'Target baru' : 'Edit target',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama target',
                hintText: 'Misalnya: Laptop baru',
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama target wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Nominal target (Rp)',
                hintText: 'Misalnya: 5.000.000',
              ),
              validator: (String? value) {
                final int amount = parseCurrencyInput(value ?? '');
                if (amount <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _deadline == null
                        ? 'Tenggat: tidak ditentukan'
                        : 'Tenggat: ${DateFormat('d MMMM yyyy', 'id_ID').format(_deadline!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _deadline == null
                      ? _pickDeadline
                      : () => setState(() => _deadline = null),
                  child: Text(_deadline == null ? 'Pilih tenggat' : 'Hapus'),
                ),
                IconButton(
                  icon: const Icon(Icons.event),
                  tooltip: 'Pilih tenggat',
                  onPressed: _pickDeadline,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(widget.goal == null ? 'Tambah' : 'Simpan'),
            ),
            if (widget.goal != null) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(savingsRepositoryProvider)
                      .deleteGoal(widget.goal!.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Hapus target'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String name = _nameController.text.trim();
    final int targetAmount = parseCurrencyInput(_targetController.text);
    final SavingsRepository repository = ref.read(savingsRepositoryProvider);

    if (widget.goal == null) {
      await repository.addGoal(
        name: name,
        targetAmount: targetAmount,
        deadline: _deadline,
      );
    } else {
      await repository.updateGoal(
        id: widget.goal!.id,
        name: name,
        targetAmount: targetAmount,
        deadline: _deadline,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class DepositSheet extends ConsumerStatefulWidget {
  const DepositSheet({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  ConsumerState<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<DepositSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int remaining = widget.goal.targetAmount > widget.goal.savedAmount
        ? widget.goal.targetAmount - widget.goal.savedAmount
        : 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Setor ke ${widget.goal.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Terkumpul ${formatRupiah(widget.goal.savedAmount)} '
              'dari ${formatRupiah(widget.goal.targetAmount)}'
              '${remaining > 0 ? '\u2022 sisa ${formatRupiah(remaining)}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Jumlah setoran (Rp)',
                hintText: 'Misalnya: 100.000',
              ),
              validator: (String? value) {
                final int amount = parseCurrencyInput(value ?? '');
                if (amount <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Setor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref.read(savingsRepositoryProvider).addDeposit(
          goalId: widget.goal.id,
          amount: parseCurrencyInput(_amountController.text),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

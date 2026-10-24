import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/savings_repository.dart';
import '../../savings_constants.dart';
import '../providers/savings_providers.dart';

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
              inputFormatters: const <TextInputFormatter>[
                CurrencyInputFormatter(),
              ],
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
                        : 'Tenggat: ${formatDateLong(_deadline!)}',
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
              child: Text(widget.goal == null ? 'Tambah' : UiText.save),
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
      initialDate:
          _deadline ??
          now.add(const Duration(days: SavingsConstants.defaultDeadlineDays)),
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

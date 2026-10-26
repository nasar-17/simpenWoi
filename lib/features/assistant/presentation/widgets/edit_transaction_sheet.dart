import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/assistant/assistant_action.dart';
import '../../../../core/assistant/proposed_action.dart';
import '../../../../core/constants/transaction_values.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../home/presentation/widgets/category_dropdown.dart';
import '../../../home/presentation/widgets/wallet_dropdown.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

Future<ProposedAction?> showEditTransactionSheet(
  BuildContext context,
  ProposedAction proposal,
) {
  return showModalBottomSheet<ProposedAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) =>
        _EditTransactionSheet(proposal: proposal),
  );
}

class _EditTransactionSheet extends ConsumerStatefulWidget {
  const _EditTransactionSheet({required this.proposal});

  final ProposedAction proposal;
  @override
  ConsumerState<_EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<_EditTransactionSheet> {
  late final _action = widget.proposal.action as AddTransactionAction;
  late final _amount = TextEditingController(
    text: formatRupiahDigits(_action.amount),
  );
  late final _note = TextEditingController(text: _action.note ?? '');
  late String _type = _action.type;
  late int _walletId = _action.walletId;
  late int? _categoryId = _action.categoryId;
  late bool _exclude = _action.excludeFromTarget;
  late DateTime _date = _action.createdAt ?? DateTime.now();
  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    final int amount = parseCurrencyInput(_amount.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0.')),
      );
      return;
    }
    final List<Category> categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    String? categoryName;
    for (final Category category in categories) {
      if (category.id == _categoryId) {
        categoryName = category.name;
      }
    }
    final AddTransactionAction updated = AddTransactionAction(
      amount: amount,
      type: _type,
      walletId: _walletId,
      categoryId: _categoryId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      merchant: _action.merchant,
      excludeFromTarget: _type == TransactionType.expense && _exclude,
      createdAt: DateTime(_date.year, _date.month, _date.day, 12),
    );
    final String typeLabel = _type == TransactionType.income
        ? 'Tambah pemasukan'
        : 'Tambah pengeluaran';
    Navigator.of(context).pop(
      widget.proposal.copyWith(
        action: updated,
        confidence: 1,
        options: const <CategoryOption>[],
        clearSuggestedCategory: true,
        summary:
            '$typeLabel ${formatRupiah(amount)} \u2014 '
            '${categoryName ?? 'kategori belum dipilih'}',
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Text('Ubah transaksi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: const <TextInputFormatter>[
              CurrencyInputFormatter(),
            ],
            decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: TransactionType.expense,
                label: Text('Keluar'),
              ),
              ButtonSegment<String>(
                value: TransactionType.income,
                label: Text('Masuk'),
              ),
            ],
            selected: <String>{_type},
            onSelectionChanged: (Set<String> value) => setState(() {
              _type = value.first;
              _categoryId = null;
            }),
          ),
          const SizedBox(height: 12),
          WalletDropdown(
            preferredId: _walletId,
            label: 'Dompet',
            onChanged: (int value) => setState(() => _walletId = value),
          ),
          const SizedBox(height: 12),
          CategoryDropdown(
            type: _type,
            initialValue: _categoryId,
            onChanged: (int? value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Tanggal'),
            subtitle: Text(DateFormat('dd MMM yyyy', 'id_ID').format(_date)),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text('Pilih'),
            ),
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
          if (_type == TransactionType.expense)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kecualikan dari target pengeluaran'),
              value: _exclude,
              onChanged: (bool value) => setState(() => _exclude = value),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('Simpan')),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/constants/ui_text.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/parser/parsed_entry.dart';
import '../../../../core/parser/transaction_parser.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../categories/domain/category_rules.dart';
import '../../../categories/domain/category_selection.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../wallets/domain/wallet_resolver.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import 'capture_details_form.dart';
import 'wallet_dropdown.dart';

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  ParsedEntry _parsed = const ParsedEntry(
    amount: 0,
    type: TransactionType.expense,
  );
  String _type = TransactionType.expense;
  int? _categoryId;
  int? _walletId;

  @override
  void dispose() {
    _inputController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _parsed = const ParsedEntry(amount: 0, type: TransactionType.expense);
        _categoryId = null;
        _amountController.clear();
        _noteController.clear();
      });
      return;
    }

    final List<Category> categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    final ParsedEntry parsed = const TransactionParser().parse(
      value,
      categories: categoryRulesFrom(categories),
    );
    setState(() {
      _parsed = parsed;
      _type = parsed.type;
      if (parsed.amount > 0) {
        _amountController.text = formatRupiah(parsed.amount);
      }
      _noteController.text = parsed.note ?? '';
      _categoryId = parsed.categoryId;
    });
  }

  void _onTypeChanged(String newType) {
    final List<Category> categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    setState(() {
      _type = newType;
      _categoryId = validCategoryId(_categoryId, newType, categories);
    });
  }

  void _onCategoryChanged(int? value) {
    setState(() {
      _categoryId = value;
    });
  }

  Future<void> _save() async {
    final int amount = parseCurrencyInput(_amountController.text);
    final List<Wallet> wallets = ref.read(walletsProvider).value ?? <Wallet>[];
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dompet belum tersedia.')));
      return;
    }
    final List<Category> categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    final int? categoryId = validCategoryId(_categoryId, _type, categories);
    final Wallet wallet = resolveWallet(wallets, preferredId: _walletId);
    final String note = _noteController.text.trim();

    await ref
        .read(transactionRepositoryProvider)
        .addTransaction(
          amount: amount,
          type: _type,
          walletId: wallet.id,
          categoryId: categoryId,
          note: note.isEmpty ? null : note,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Catat cepat', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tulis transaksi',
                hintText: 'Misalnya: bakso 15rb',
              ),
              onChanged: _onInputChanged,
            ),
            if (_parsed.amount > 0) ...<Widget>[
              const SizedBox(height: 16),
              CaptureDetailsForm(
                amountController: _amountController,
                noteController: _noteController,
                type: _type,
                categoryId: _categoryId,
                onTypeChanged: _onTypeChanged,
                onCategoryChanged: _onCategoryChanged,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: WalletDropdown(
                    preferredId: _walletId,
                    isDense: true,
                    onChanged: (int value) {
                      setState(() {
                        _walletId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _parsed.amount > 0 ? _save : null,
                  child: const Text(UiText.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

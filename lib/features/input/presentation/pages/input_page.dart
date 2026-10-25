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
import '../../../home/presentation/widgets/capture_details_form.dart';
import '../../../home/presentation/widgets/wallet_dropdown.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../wallets/domain/wallet_resolver.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import '../widgets/coming_soon_cards.dart';

class InputPage extends ConsumerStatefulWidget {
  const InputPage({super.key});

  @override
  ConsumerState<InputPage> createState() => _InputPageState();
}

class _InputPageState extends ConsumerState<InputPage> {
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
        _amountController.text = formatRupiahDigits(parsed.amount);
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

  Future<void> _save() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final int amount = parseCurrencyInput(_amountController.text);
    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0.')),
      );
      return;
    }
    final List<Wallet> wallets = ref.read(walletsProvider).value ?? <Wallet>[];
    if (wallets.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Dompet belum tersedia.')),
      );
      return;
    }
    final List<Category> categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    final int? categoryId = validCategoryId(_categoryId, _type, categories);
    final Wallet wallet = resolveWallet(wallets, preferredId: _walletId);
    final String note = _noteController.text.trim();

    try {
      await ref
          .read(transactionRepositoryProvider)
          .addTransaction(
            amount: amount,
            type: _type,
            walletId: wallet.id,
            categoryId: categoryId,
            note: note.isEmpty ? null : note,
          );
      if (!mounted) {
        return;
      }
      _inputController.clear();
      _amountController.clear();
      _noteController.clear();
      setState(() {
        _parsed = const ParsedEntry(amount: 0, type: TransactionType.expense);
        _type = TransactionType.expense;
        _categoryId = null;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Tersimpan')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan transaksi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          TextField(
            controller: _inputController,
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
              onCategoryChanged: (int? value) {
                setState(() {
                  _categoryId = value;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          WalletDropdown(
            preferredId: _walletId,
            isDense: true,
            onChanged: (int value) {
              setState(() {
                _walletId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _parsed.amount > 0 ? _save : null,
            child: const Text(UiText.save),
          ),
          const SizedBox(height: 24),
          const ComingSoonCards(),
        ],
      ),
    );
  }
}

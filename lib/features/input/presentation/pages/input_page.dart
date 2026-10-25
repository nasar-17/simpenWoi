import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/transaction_values.dart';
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
import '../../domain/input_transaction_saver.dart';
import '../widgets/input_form_body.dart';

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
  int? _counterpartWalletId;
  bool _excludeFromTarget = false;

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
        _type = TransactionType.expense;
        _categoryId = null;
        _counterpartWalletId = null;
        _excludeFromTarget = false;
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
      _counterpartWalletId = null;
      _excludeFromTarget = false;
    });
  }

  void _onTypeChanged(String newType) {
    final List<Category> categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    final List<Wallet> wallets = ref.read(walletsProvider).value ?? <Wallet>[];
    setState(() {
      _type = newType;
      _categoryId = validCategoryId(_categoryId, newType, categories);
      if (newType != TransactionType.expense) {
        _excludeFromTarget = false;
      }
      if (newType == TransactionType.transfer && wallets.isNotEmpty) {
        final Wallet source = resolveWallet(wallets, preferredId: _walletId);
        _counterpartWalletId = resolveTransferWallet(
          wallets,
          sourceId: source.id,
        )?.id;
      } else {
        _counterpartWalletId = null;
      }
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
    final List<Category> categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    final String? error = await saveInputTransaction(
      repository: ref.read(transactionRepositoryProvider),
      wallets: wallets,
      categories: categories,
      amount: amount,
      type: _type,
      walletId: _walletId,
      counterpartWalletId: _counterpartWalletId,
      categoryId: _categoryId,
      note: _noteController.text.trim(),
      excludeFromTarget: _excludeFromTarget,
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _inputController.clear();
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _parsed = const ParsedEntry(amount: 0, type: TransactionType.expense);
      _type = TransactionType.expense;
      _categoryId = null;
      _counterpartWalletId = null;
      _excludeFromTarget = false;
    });
    messenger.showSnackBar(const SnackBar(content: Text('Tersimpan')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input')),
      body: InputFormBody(
        inputController: _inputController,
        amountController: _amountController,
        noteController: _noteController,
        parsedAmount: _parsed.amount,
        type: _type,
        categoryId: _categoryId,
        walletId: _walletId,
        counterpartWalletId: _counterpartWalletId,
        excludeFromTarget: _excludeFromTarget,
        onInputChanged: _onInputChanged,
        onTypeChanged: _onTypeChanged,
        onCategoryChanged: (int? value) {
          setState(() {
            _categoryId = value;
          });
        },
        onCounterpartWalletChanged: (int value) {
          setState(() {
            _counterpartWalletId = value;
          });
        },
        onExcludeFromTargetChanged: (bool value) {
          setState(() {
            _excludeFromTarget = value;
          });
        },
        onWalletChanged: (int value) {
          setState(() {
            _walletId = value;
            if (_type == TransactionType.transfer &&
                _counterpartWalletId == value) {
              _counterpartWalletId = resolveTransferWallet(
                ref.read(walletsProvider).value ?? <Wallet>[],
                sourceId: value,
              )?.id;
            }
          });
        },
        onSave: _save,
      ),
    );
  }
}

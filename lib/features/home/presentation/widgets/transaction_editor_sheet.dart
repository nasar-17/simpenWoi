import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/transaction_values.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../capture/presentation/providers/capture_providers.dart';
import '../../../categories/domain/category_selection.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../wallets/domain/wallet_resolver.dart';
import '../../../wallets/presentation/providers/wallet_providers.dart';
import 'transaction_editor_form.dart';

class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({super.key, required this.transaction});

  final TransactionRecord transaction;

  @override
  ConsumerState<TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<TransactionEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _merchantController;
  late String _type;
  late int? _categoryId;
  late int _walletId;
  int? _counterpartWalletId;
  late bool _excludeFromTarget;

  @override
  void initState() {
    super.initState();
    final TransactionRecord transaction = widget.transaction;
    _amountController = TextEditingController(
      text: formatRupiahDigits(transaction.amount),
    );
    _noteController = TextEditingController(text: transaction.note ?? '');
    _merchantController = TextEditingController(
      text: transaction.merchant ?? '',
    );
    _type = transaction.type;
    _categoryId = transaction.categoryId;
    _walletId = transaction.walletId;
    _counterpartWalletId = transaction.counterpartWalletId;
    _excludeFromTarget = transaction.excludeFromTarget;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
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
        _counterpartWalletId = resolveTransferWallet(
          wallets,
          preferredId: _counterpartWalletId,
          sourceId: _walletId,
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
    final String merchant = _merchantController.text.trim();
    final int? counterpartWalletId = _type == TransactionType.transfer
        ? _counterpartWalletId
        : null;
    if (_type == TransactionType.transfer &&
        (counterpartWalletId == null || counterpartWalletId == wallet.id)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pilih dompet tujuan yang berbeda.')),
      );
      return;
    }

    try {
      final bool rulesChanged = await ref
          .read(transactionRepositoryProvider)
          .updateTransaction(
            id: widget.transaction.id,
            amount: amount,
            type: _type,
            walletId: wallet.id,
            counterpartWalletId: counterpartWalletId,
            categoryId: categoryId,
            note: note.isEmpty ? null : note,
            merchant: _type == TransactionType.transfer
                ? null
                : (merchant.isEmpty ? null : merchant),
            excludeFromTarget: _excludeFromTarget,
          );
      try {
        final int? nativeCaptureId = widget.transaction.nativeCaptureId;
        if (nativeCaptureId != null) {
          await ref
              .read(captureSyncServiceProvider)
              .syncEditedCapture(
                nativeCaptureId: nativeCaptureId,
                categoryId: categoryId,
                note: note.isEmpty ? null : note,
              );
        }
        if (rulesChanged) {
          await ref.read(captureSyncServiceProvider).refreshNativeContext();
        }
      } on Exception catch (_) {}
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan transaksi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TransactionEditorForm(
      amountController: _amountController,
      noteController: _noteController,
      merchantController: _merchantController,
      type: _type,
      categoryId: _categoryId,
      walletId: _walletId,
      counterpartWalletId: _counterpartWalletId,
      excludeFromTarget: _excludeFromTarget,
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
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

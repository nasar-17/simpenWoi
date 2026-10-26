import '../constants/transaction_values.dart';
import '../database/app_database.dart';
import 'assistant_action.dart';
import 'assistant_context.dart';

String? validateAssistantAction(
  AssistantAction action,
  AssistantContext context,
) {
  return switch (action) {
    AddTransactionAction() => _validateAdd(action, context),
    CreateCategoryAction() => _validateCategory(action),
    SetWalletBalanceAction() => _validateBalance(action, context),
    TransferAction() => _validateTransfer(action, context),
    CreateWalletAction() => _validateWallet(action),
    SetSpendingTargetAction() => _validateTarget(action),
    QueryTotalAction() => _validateQuery(action, context),
    AskClarificationAction() => null,
  };
}

String? _validateAdd(AddTransactionAction action, AssistantContext context) {
  if (action.amount <= 0) {
    return 'Nominal harus lebih dari 0.';
  }
  if (action.type != TransactionType.expense &&
      action.type != TransactionType.income) {
    return 'Jenis transaksi tidak dikenal.';
  }
  final Wallet? wallet = context.walletById(action.walletId);
  if (wallet == null) {
    return 'Dompet tidak ditemukan.';
  }
  final Category? category = context.categoryById(action.categoryId);
  if (action.categoryId != null &&
      (category == null || category.type != action.type)) {
    return 'Kategori tidak sesuai.';
  }
  return null;
}

String? _validateCategory(CreateCategoryAction action) {
  if (action.name.trim().isEmpty) {
    return 'Nama kategori wajib diisi.';
  }
  if (action.type != TransactionType.expense &&
      action.type != TransactionType.income) {
    return 'Jenis kategori tidak valid.';
  }
  return null;
}

String? _validateBalance(
  SetWalletBalanceAction action,
  AssistantContext context,
) {
  if (action.targetBalance < 0) {
    return 'Saldo tujuan tidak boleh negatif.';
  }
  if (context.walletById(action.walletId) == null) {
    return 'Dompet tidak ditemukan.';
  }
  return null;
}

String? _validateTransfer(TransferAction action, AssistantContext context) {
  if (action.amount <= 0) {
    return 'Nominal transfer harus lebih dari 0.';
  }
  if (action.fromWalletId == action.toWalletId) {
    return 'Dompet asal dan tujuan harus berbeda.';
  }
  if (context.walletById(action.fromWalletId) == null ||
      context.walletById(action.toWalletId) == null) {
    return 'Dompet transfer tidak ditemukan.';
  }
  return null;
}

String? _validateWallet(CreateWalletAction action) {
  if (action.name.trim().isEmpty) {
    return 'Nama dompet wajib diisi.';
  }
  if (action.initialBalance < 0) {
    return 'Saldo awal tidak boleh negatif.';
  }
  return null;
}

String? _validateTarget(SetSpendingTargetAction action) {
  if (action.amount <= 0) {
    return 'Target pengeluaran harus lebih dari 0.';
  }
  if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(action.month)) {
    return 'Bulan target tidak valid.';
  }
  return null;
}

String? _validateQuery(QueryTotalAction action, AssistantContext context) {
  if (action.categoryId == null) {
    return null;
  }
  final Category? category = context.categoryById(action.categoryId);
  if (category == null || category.type != TransactionType.expense) {
    return 'Kategori pengeluaran tidak ditemukan.';
  }
  return null;
}
